import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path/path.dart' as path;
import 'package:rapidefi/pages/hardware/widgets/efi_build_progress_dialog.dart';
import 'package:rapidefi/utils/config/build/efi_build_options.dart';
import 'package:rapidefi/utils/config/build/efi_build_pipeline.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/services/config_service.dart';
import 'package:rapidefi/utils/config/services/config_session.dart';
import 'package:rapidefi/utils/file_util.dart';
import 'package:rapidefi/utils/hardware/config/hardware_config_build_context.dart';
import 'package:rapidefi/utils/hardware/config/hardware_config_model_builder.dart';
import 'package:rapidefi/utils/hardware/config/hardware_config_options.dart';
import 'package:rapidefi/utils/hardware/hardware_info.dart';
import 'package:rapidefi/utils/hardware/ssdt/custom_ssdt_prebuilt_pruner.dart';
import 'package:rapidefi/utils/hardware/ssdt/ssdt_platform_catalog.dart';
import 'package:rapidefi/utils/hardware/ssdt/ssdt_selection.dart';
import 'package:rapidefi/utils/hardware/ssdt/win_ssdt_build_service.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi_generic.dart';
import 'package:rapidefi/utils/hardware/model/allinfo.dart';
import 'package:rapidefi/utils/log/log.dart';
import 'package:rapidefi/utils/ssdttool/config.dart';
import 'package:rapidefi/utils/ssdttool/dsdt.dart';
import 'package:rapidefi/utils/ssdttool/manager.dart';
import 'package:rapidefi/utils/ssdttool/table.dart';

class _AcpiExportResult {
  const _AcpiExportResult({
    this.path,
    this.failureMessage,
  });

  final String? path;
  final String? failureMessage;

  bool get exported => path != null && path!.isNotEmpty;
}

class HardwarePageController extends ChangeNotifier {
  static const String _idleStatus = '等待刷新硬件信息';
  static const String _loadingStatus = '正在加载硬件信息';
  static const String _refreshStatus = '正在刷新硬件信息';
  static const String _completeStatus = '硬件信息加载完成';
  static const String _failedStatus = '硬件信息加载失败';
  static const String _unsupportedStatus = '硬件信息暂不支持';
  static const String _importedStatus = '硬件信息导入完成';

  HardwareAllInfo? allInfo;
  Map<String, dynamic>? rawInfo;
  String outputDirectory = '';
  String importedHardwarePath = '';
  String importedAcpiTablesPath = '';
  bool isLoading = false;
  double loadProgress = 0;
  String loadStatus = _idleStatus;
  int elapsedMilliseconds = 0;
  int contentRevision = 0;

  DateTime? _loadStartTime;
  Timer? _elapsedTimer;
  StreamSubscription<String>? _progressSubscription;
  bool _disposed = false;

  bool get hasImportedHardware => importedHardwarePath.trim().isNotEmpty;

  bool get hasImportedAcpiTables => importedAcpiTablesPath.trim().isNotEmpty;

  bool get customSsdtAvailable => !hasImportedHardware || hasImportedAcpiTables;

  void init() {
    _initOutputDirectory();
    _listenProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 32), () {
        if (_disposed) return;
        unawaited(loadAllInfo());
      });
    });
  }

  void _listenProgress() {
    _progressSubscription = HardwareInfo.progressStream.listen((message) {
      if (_disposed) return;
      loadStatus = _statusFromProgress(message);
      notifyListeners();
    });
  }

  String _statusFromProgress(String message) {
    if (message.contains('失败')) return _failedStatus;
    if (message.contains('不支持')) return _unsupportedStatus;
    if (message.contains('完成')) return _completeStatus;
    if (message.contains('缓存')) return _refreshStatus;
    return isLoading ? _loadingStatus : _idleStatus;
  }

  Future<void> _initOutputDirectory() async {
    if (outputDirectory.isEmpty) {
      outputDirectory = await FileUtils.getDefaultOutputDirectory();
      if (_disposed) return;
      notifyListeners();
    }
  }

  Future<void> loadAllInfo() async {
    if (_disposed) return;
    final hasCache = await HardwareInfo.loadCachedInfo('all');
    if (_disposed) return;
    allInfo = HardwareInfo.getHardwareInfoForPage('all');
    rawInfo = HardwareInfo.rawInfo;
    if (hasCache) {
      contentRevision++;
      loadStatus = _refreshStatus;
      loadProgress = 1;
      isLoading = false;
      notifyListeners();
      if (!HardwareInfo.analysisDataLoaded) {
        unawaited(HardwareInfo.ensureAnalysisDataLoaded().then((_) {
          if (_disposed || !hasListeners) return;
          contentRevision++;
          notifyListeners();
        }));
      }
    }
    if (Platform.isWindows) {
      unawaited(refreshHardwareInfo(
        clearCache: true,
        preserveCurrent: hasCache,
        force: true,
      ));
    } else if (hasCache) {
      _elapsedTimer?.cancel();
      isLoading = false;
      notifyListeners();
    } else {
      _failLoadStatus(_unsupportedStatus);
    }
  }

  Future<void> refreshHardwareInfo({
    bool clearCache = true,
    bool preserveCurrent = false,
    bool force = false,
  }) async {
    if (_disposed) return;
    if (isLoading && !force) return;
    if (!Platform.isWindows) {
      showToast('当前平台不支持硬件信息查询');
      loadStatus = _unsupportedStatus;
      isLoading = false;
      loadProgress = 0;
      notifyListeners();
      return;
    }
    if (!preserveCurrent) {
      allInfo = null;
      rawInfo = null;
      importedHardwarePath = '';
      importedAcpiTablesPath = '';
    }
    if (!isLoading) {
      _startLoadStatus(
        status: preserveCurrent ? _refreshStatus : _loadingStatus,
      );
    }
    notifyListeners();
    if (clearCache) HardwareInfo.clearInfo('all');

    final startTime = _loadStartTime ?? DateTime.now();
    try {
      await HardwareInfo.initWindowsInfo(
        taskId: 'all',
        requiredValues: [WindowsSystemInfoType.ALL],
        simple: false,
      );
      if (_disposed) return;
      if (hasImportedHardware) return;
      allInfo = HardwareInfo.getHardwareInfoForPage('all');
      rawInfo = HardwareInfo.rawInfo;
      contentRevision++;
      _finishLoadStatus(DateTime.now().difference(startTime));
    } catch (e) {
      _failLoadStatus(e);
      showToast('硬件信息获取失败: $e');
    }
  }

  void _startLoadStatus({String status = _loadingStatus}) {
    _elapsedTimer?.cancel();
    _loadStartTime = DateTime.now();
    isLoading = true;
    loadProgress = 0.08;
    elapsedMilliseconds = 0;
    loadStatus = status;
    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_disposed) return;
      if (_loadStartTime == null) return;
      elapsedMilliseconds =
          DateTime.now().difference(_loadStartTime!).inMilliseconds;
      if (loadProgress < 0.92) loadProgress += 0.015;
      notifyListeners();
    });
  }

  void _finishLoadStatus(Duration duration) {
    _elapsedTimer?.cancel();
    isLoading = false;
    loadProgress = 1;
    elapsedMilliseconds = duration.inMilliseconds;
    loadStatus = _completeStatus;
    notifyListeners();
  }

  void _failLoadStatus(Object error) {
    _elapsedTimer?.cancel();
    isLoading = false;
    loadProgress = 0;
    loadStatus =
        error == _unsupportedStatus ? _unsupportedStatus : _failedStatus;
    notifyListeners();
  }

  Future<void> exportHardwareInfo() async {
    if (hasImportedHardware) {
      showToast('当前为导入的外部硬件报告，请先刷新本机硬件信息后再导出');
      return;
    }

    final report = HardwareInfo.rawReport ??
        const JsonEncoder.withIndent('  ').convert(rawInfo ?? {});
    if (report.trim().isEmpty || report.trim() == '{}') {
      showToast('暂无可导出的本机硬件信息');
      return;
    }

    final baseDirectory = outputDirectory.isEmpty
        ? await FileUtils.getDefaultOutputDirectory()
        : outputDirectory;
    final reportDirectoryPath = path.join(
      baseDirectory,
      'RapidEFI-HardwareReport',
    );
    final reportRoot = Directory(reportDirectoryPath);
    if (await reportRoot.exists()) {
      try {
        await reportRoot.delete(recursive: true);
      } catch (error) {
        Log.warning('硬件报告文件夹清理失败: $error');
        showToast('硬件报告文件夹清理失败');
        return;
      }
    }
    final reportDirectory = await FileUtils.createDirectory(
      baseDirectory,
      'RapidEFI-HardwareReport',
    );
    if (reportDirectory.isEmpty) {
      showToast('硬件报告文件夹创建失败');
      return;
    }

    Log('正在导出本机硬件报告...');
    await FileUtils.saveToFile(
      content: report,
      fileName: 'sysInfo.txt',
      directoryPath: reportDirectory,
    );

    final acpiResult = await _exportLocalAcpiTables(
      reportDirectory,
      folderName: 'ACPI',
    );
    showToast(
      acpiResult.exported
          ? '硬件报告和 ACPI 表已导出到 $reportDirectory'
          : '硬件报告已导出到 $reportDirectory，${acpiResult.failureMessage ?? 'ACPI 表导出失败或不支持'}',
    );
  }

  Future<void> exportLocalAcpiTables({
    Future<String?> Function()? onRequestSudoPassword,
  }) async {
    final baseDirectory = outputDirectory.isEmpty
        ? await FileUtils.getDefaultOutputDirectory()
        : outputDirectory;
    final result = await _exportLocalAcpiTables(
      baseDirectory,
      folderName: 'RapidEFI-ACPI',
      onRequestSudoPassword: onRequestSudoPassword,
    );
    showToast(
      result.exported
          ? 'ACPI 表已导出到 ${result.path}'
          : result.failureMessage ?? 'ACPI 表导出失败或不支持',
    );
  }

  Future<_AcpiExportResult> _exportLocalAcpiTables(
    String reportDirectory, {
    required String folderName,
    Future<String?> Function()? onRequestSudoPassword,
  }) async {
    Directory? tempDirectory;
    var tempMoved = false;
    try {
      Log('正在导出本机 ACPI 表...');
      final baseDirectory = Directory(reportDirectory);
      await baseDirectory.create(recursive: true);
      final acpiDirectoryPath = path.join(reportDirectory, folderName);
      final tempDirectoryPath = path.join(
        reportDirectory,
        '.$folderName.tmp_${DateTime.now().microsecondsSinceEpoch}',
      );
      tempDirectory = Directory(tempDirectoryPath);
      await tempDirectory.create(recursive: true);

      final manager = ACPIToolManager(
        acpiConfig: AcpiConfig(
          outputDirectory: tempDirectory.path,
          acpiDirectory: tempDirectory.path,
          overwriteEFI: true,
        ),
      );
      final dumpPath = await manager.dumpTables(
        tempDirectory.path,
        onRequestSudoPassword: onRequestSudoPassword,
        throwOnFailure: true,
      );
      final exported = dumpPath != null && dumpPath.isNotEmpty;
      if (!exported) {
        Log.warning('本机 ACPI 表导出失败');
        return const _AcpiExportResult(failureMessage: 'ACPI 表导出失败或不支持');
      }

      final acpiRoot = Directory(acpiDirectoryPath);
      if (await acpiRoot.exists()) {
        await acpiRoot.delete(recursive: true);
      }
      await tempDirectory.rename(acpiDirectoryPath);
      tempMoved = true;
      Log('本机 ACPI 表导出完成: $acpiDirectoryPath');
      return _AcpiExportResult(path: acpiDirectoryPath);
    } on AcpiDumpException catch (error) {
      Log.warning('本机 ACPI 表导出失败: $error');
      return _AcpiExportResult(
        failureMessage: _acpiDumpFailureMessage(error),
      );
    } catch (error) {
      Log.warning('本机 ACPI 表导出失败: $error');
      return const _AcpiExportResult(failureMessage: 'ACPI 表导出失败或不支持');
    } finally {
      if (!tempMoved && tempDirectory != null && await tempDirectory.exists()) {
        try {
          await tempDirectory.delete(recursive: true);
        } catch (error) {
          Log.warning('ACPI 表临时目录清理失败: $error');
        }
      }
    }
  }

  String _acpiDumpFailureMessage(AcpiDumpException error) {
    switch (error.type) {
      case AcpiDumpFailureType.toolMissing:
        return 'ACPI 导出工具未准备就绪';
      case AcpiDumpFailureType.unsupportedPlatform:
        return '当前平台不支持导出 ACPI 表';
      case AcpiDumpFailureType.authorizationCancelled:
        return '已取消管理员授权，未导出 ACPI 表';
      case AcpiDumpFailureType.passwordRequired:
        return '未输入管理员密码，无法导出 ACPI 表';
      case AcpiDumpFailureType.incorrectPassword:
        return '管理员密码不正确，无法导出 ACPI 表';
      case AcpiDumpFailureType.emptyResult:
        return 'ACPI 表导出失败：未找到有效 ACPI 表';
      case AcpiDumpFailureType.processFailed:
        return 'ACPI 表导出失败：导出进程执行失败';
    }
  }

  Future<void> importHardwareInfo({
    required String filePath,
    String acpiTablesPath = '',
  }) async {
    if (filePath.isEmpty) return;
    try {
      final text = await HardwareInfo.readHardwareReportFile(filePath);
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('硬件信息文件不是 JSON 对象');
      }
      await HardwareInfo.importRawInfo('all', decoded);
      allInfo = HardwareInfo.getHardwareInfoForPage('all');
      rawInfo = HardwareInfo.rawInfo;
      contentRevision++;
      importedHardwarePath = filePath;
      importedAcpiTablesPath = _validAcpiTablesPath(acpiTablesPath);
      _elapsedTimer?.cancel();
      isLoading = false;
      loadProgress = 1;
      loadStatus = _importedStatus;
      notifyListeners();
      showToast('硬件信息已导入');
      if (acpiTablesPath.trim().isNotEmpty && importedAcpiTablesPath.isEmpty) {
        showToast('ACPI 表目录无效，定制 SSDT 不可用');
      }
    } catch (e) {
      showToast('导入硬件报告失败: $e');
    }
  }

  String _validAcpiTablesPath(String acpiTablesPath) {
    final input = acpiTablesPath.trim();
    if (input.isEmpty) return '';

    final directory = Directory(input);
    if (!directory.existsSync()) return '';
    if (_containsSingleDsdt(directory)) return directory.path;

    for (final candidate in _preferredAcpiDirectoryCandidates(directory)) {
      if (_containsSingleDsdt(candidate)) return candidate.path;
    }

    for (final candidate in _acpiDirectoryCandidates(directory)) {
      if (_containsSingleDsdt(candidate)) {
        return candidate.path;
      }
    }

    return '';
  }

  List<Directory> _preferredAcpiDirectoryCandidates(Directory directory) {
    try {
      return directory
          .listSync(followLinks: false)
          .whereType<Directory>()
          .where(
        (entity) {
          final name = entity.path.split(Platform.pathSeparator).last;
          final lowerName = name.toLowerCase();
          return lowerName == 'acpi' || lowerName == 'acpis';
        },
      ).toList();
    } catch (_) {
      return const <Directory>[];
    }
  }

  List<Directory> _acpiDirectoryCandidates(Directory directory) {
    final candidates = <Directory>[];
    void collect(Directory current, int depth) {
      if (depth > 3) return;
      List<FileSystemEntity> entities;
      try {
        entities = current.listSync(followLinks: false);
      } catch (_) {
        return;
      }
      for (final entity in entities) {
        if (entity is! Directory) continue;
        final name = entity.path.split(Platform.pathSeparator).last;
        if (name.toLowerCase().contains('acpi')) {
          candidates.add(entity);
        }
        collect(entity, depth + 1);
      }
    }

    collect(directory, 0);
    return candidates;
  }

  bool _containsSingleDsdt(Directory directory) {
    final files =
        directory.listSync(followLinks: false).whereType<File>().where((file) {
      final lower = file.path.toLowerCase();
      return lower.endsWith('.aml') || lower.endsWith('.dat');
    }).toList();
    if (files.isEmpty) return false;

    var dsdtCount = 0;
    for (final file in files) {
      RandomAccessFile? opened;
      try {
        opened = file.openSync(mode: FileMode.read);
        final header = opened.readSync(4);
        if (header.length == 4 && String.fromCharCodes(header) == 'DSDT') {
          dsdtCount++;
        }
      } catch (_) {
      } finally {
        opened?.closeSync();
      }
    }
    return dsdtCount == 1;
  }

  Future<void> buildAndExportEfi({
    required HardwareAllInfo info,
    required String macOSVersion,
    required int? alcLayoutId,
    required bool? enableNpci,
    required PlatformInfoGeneric? platformInfoGeneric,
    required CpuType? cpuType,
    required PlatformType? platformType,
    required String? platformCode,
    required SsdtBuildMode ssdtBuildMode,
    required SsdtSelection? ssdtSelection,
    required BuildContext context,
  }) async {
    final effectiveSsdtBuildMode =
        ssdtBuildMode == SsdtBuildMode.custom && !customSsdtAvailable
            ? SsdtBuildMode.original
            : ssdtBuildMode;
    final progress = EfiBuildProgressDialog.show(context);
    progress.addLine('开始配置 EFI...');
    try {
      progress.addLine('正在根据硬件信息生成 ConfigModel...');
      final configModel = await HardwareConfigModelBuilder(
        hardwareInfo: info,
        rawInfo: rawInfo,
      ).buildAsync(
        options: HardwareConfigOptions(
          macOSVersion: macOSVersion,
          alcLayoutId: alcLayoutId,
          enableNpci: enableNpci,
          platformInfoGeneric: platformInfoGeneric,
          cpuType: cpuType,
          platformType: platformType,
          platformCode: platformCode,
        ),
      );
      progress.addLine(
        'ConfigModel 已生成: ${configModel.cpuType.name}/${configModel.platformType.name}/${configModel.platformCode}',
      );
      final resolvedSsdtSelection =
          effectiveSsdtBuildMode == SsdtBuildMode.custom
              ? ssdtSelection ??
                  SsdtSelection(
                    cpuType: configModel.cpuType,
                    platformType: configModel.platformType,
                    platformCode: configModel.platformCode,
                    items: _defaultSsdtItems(configModel, info),
                  )
              : null;
      final customSsdtManagedPaths = resolvedSsdtSelection == null
          ? const <String>{}
          : customSsdtManagedAmlPaths(resolvedSsdtSelection);
      if (resolvedSsdtSelection != null) {
        removeCustomSsdtPrebuiltItems(configModel, resolvedSsdtSelection);
        progress.addLine(
          '准备定制 SSDT: ${resolvedSsdtSelection.items.map((item) => item.name).join(', ')}',
        );
      } else if (effectiveSsdtBuildMode == SsdtBuildMode.original) {
        progress.addLine('使用 EFI 原始 SSDT，跳过 SSDT 定制.');
        if (hasImportedHardware && !hasImportedAcpiTables) {
          progress.addLine('已导入外部硬件报告但未提供 ACPI 表目录，已禁用定制 SSDT。');
        }
      }

      progress.addLine('正在输出 OpenCore EFI...');
      final result = await EfiBuildPipeline(ConfigService()).buildResult(
        configModel: configModel,
        mode: ConfigModelMode.auto,
        options: EfiBuildOptions(
          outDirectory: outputDirectory,
          excludedAcpiPaths: customSsdtManagedPaths,
          afterConfigWritten: resolvedSsdtSelection == null
              ? null
              : (draft) async {
                  progress.addLine('EFI 已写入，开始提取 ACPI 并定制 SSDT...');
                  final merged =
                      await const WinSsdtBuildService().buildAndMerge(
                    draft: draft,
                    selection: resolvedSsdtSelection,
                    platformType: configModel.platformType,
                    rawInfo: rawInfo,
                    acpiTablesPath: importedAcpiTablesPath,
                  );
                  progress.addLine(merged ? 'SSDT 定制流程结束.' : 'SSDT 定制流程失败.');
                  return merged;
                },
        ),
      );
      progress.complete(
        success: result.success,
        outputPath: result.efiRootPath,
        message: result.success ? 'EFI 配置完成.' : 'EFI 配置失败，请检查输出路径或日志.',
      );
    } on UnsupportedError catch (error) {
      progress.addLine('配置 EFI 失败: ${error.message}');
      progress.complete(
        success: false,
        outputPath: outputDirectory,
        message: error.message ?? '硬件自动生成 ConfigModel 规则重构中',
      );
    } catch (error, stackTrace) {
      debugPrint('hardware EFI export failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      progress.addLine('配置 EFI 失败: $error');
      progress.complete(
        success: false,
        outputPath: outputDirectory,
        message: '配置 EFI 发生错误: $error',
      );
    }
  }

  List<SsdtItem> _defaultSsdtItems(ConfigModel model, HardwareAllInfo info) {
    final items = SsdtPlatformCatalog.items(
      model.cpuType,
      model.platformType,
      model.platformCode,
    );
    final selectedKeys = SsdtPlatformCatalog.defaultSelectedKeys(
      model.cpuType,
      model.platformType,
      model.platformCode,
    );

    if (model.platformType == PlatformType.laptop &&
        HardwareConfigBuildContext(
          hardwareInfo: info,
          rawInfo: rawInfo,
          options: const HardwareConfigOptions(),
        ).hasI2cInputDevice) {
      for (final item in items) {
        if (item.name == ACPITable.ssdtGPI0.name) {
          selectedKeys.add(item.key);
          break;
        }
      }
    }

    return items
        .where((item) => item.isBasic || selectedKeys.contains(item.key))
        .toList();
  }

  @override
  void dispose() {
    _disposed = true;
    _elapsedTimer?.cancel();
    _progressSubscription?.cancel();
    super.dispose();
  }
}
