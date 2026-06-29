//  manager.dart
//  Created by JeoJay127
//
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'merge.dart';
import 'ssdt.dart';
import 'config.dart';
import 'table.dart';

class PatchContext {
  dynamic data;
  Map<String, Map<String, dynamic>>? devs;
  Map<String, List<int>>? targetIrqs;
  bool prebuilt;

  PatchContext({
    this.data,
    this.devs = const {},
    this.targetIrqs = const {},
    this.prebuilt = false,
  });

  PatchContext copyWith({
    Map<String, Map<String, dynamic>>? devs,
    Map<String, List<int>>? targetIrqs,
    dynamic data,
    bool? prebuilt,
  }) {
    return PatchContext()
      ..devs = devs ?? this.devs
      ..targetIrqs = targetIrqs ?? this.targetIrqs
      ..data = data ?? this.data
      ..prebuilt = prebuilt ?? this.prebuilt;
  }
}

typedef PatchExecutor = FutureOr<void> Function({
  PatchContext? context,
  Map<String, dynamic>? action,
});

class ACPIToolManager {
  final SSDT ssdt;
  final PatchMerge _merge = PatchMerge();
  AcpiConfig _acpiConfig;
  AcpiConfig get acpiConfig => _acpiConfig;
  final String resultFolder = 'Results';

  set acpiConfig(AcpiConfig config) {
    _acpiConfig = config;
    ssdt.config = config;
  }

  /// 根据表签名,查找SSDT表路径
  String getSSDTPathWithSignature(String tableSignature) {
    for (final entry in ssdt.d.acpiTables.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value['signature'] == tableSignature) {
        return path.join(ssdt.config.outputDirectory!, key);
      }
    }
    return '';
  }

  late Map<String, PatchExecutor> _actionMap;
  List<String> get actionKeys => _actionMap.keys.toList();

  bool _pb(PatchContext? context) => context?.prebuilt ?? false;

  ACPIToolManager({AcpiConfig? acpiConfig})
      : _acpiConfig = acpiConfig ?? AcpiConfig(),
        ssdt = SSDT(config: acpiConfig ?? AcpiConfig()) {
    _initActionMap();
  }

  void _initActionMap() {
    _actionMap = {
      ACPITable.ssdtHPET.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtHPET(devs: context?.devs, targetIrqs: context?.targetIrqs),
      ACPITable.ssdtECDesktop.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtEC(prebuilt: _pb(context)),
      ACPITable.ssdtECLaptop.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtEC(prebuilt: _pb(context), isLaptop: true),
      ACPITable.ssdtECUSBXDesktop.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtEC(prebuilt: _pb(context), injectUSBPower: true),
      ACPITable.ssdtECUSBXLaptop.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtEC(
            prebuilt: _pb(context),
            isLaptop: true,
            injectUSBPower: true,
          ),
      ACPITable.ssdtUSBX.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtUSBX(prebuilt: _pb(context), usbxProps: context?.data ?? {}),
      ACPITable.ssdtPNLF.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtPNLF(
            prebuilt: _pb(context),
            uid: action?['extra'] ?? context?.data?.$1,
            getIgpu: context?.data?.$3,
            manualIGPUPath: context?.data?.$2,
          ),
      ACPITable.ssdtXOSI.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtXOSI(
            prebuilt: _pb(context),
            targetString: context?.data ?? '',
          ),
      ACPITable.ssdtPMC.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtPMC(prebuilt: _pb(context)),
      ACPITable.ssdtAPIC.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtAPIC(apicPath: context?.data),    
      ACPITable.ssdtDMAR.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtDMAR(dmarPath: context?.data),
      ACPITable.ssdtFACP.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtFACP(facpPath: context?.data),
      ACPITable.ssdtSBUSMCHC.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtSBUSMCHC(prebuilt: _pb(context)),
      ACPITable.ssdtAWAC.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtAWAC(prebuilt: _pb(context)),
      ACPITable.ssdtRTC0RANGE.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtRTC0RANGE(prebuilt: _pb(context)),
      ACPITable.ssdtPLUG.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtPLUG(prebuilt: _pb(context)),
      ACPITable.ssdtPLUGALT.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtPLUG(prebuilt: _pb(context), alderlakeOrLater: true),
      ACPITable.ssdtPCIDISABLE.name: (
          {PatchContext? context, Map<String, dynamic>? action}) {
        final data = _actionData(context, action);
        return ssdt.ssdtPCIDISABLE(
          acpiPath: _dataValue(data, 0, 'acpiPath') ??
              _dataValue(data, 0, 'pciPath'),
          disableMethod: _dataValue(data, 1, 'disableMethod'),
          type: _dataValue(data, 2, 'type'),
        );
      },
      ACPITable.ssdtGPUSPOOF.name: (
          {PatchContext? context, Map<String, dynamic>? action}) {
        final data = _actionData(context, action);
        return ssdt.ssdtGPUSPOOF(
          gpuPath: _dataValue(data, 0, 'acpiPath') ??
              _dataValue(data, 0, 'gpuPath'),
          deviceId: _dataValue(data, 1, 'deviceId'),
          fakeModel: _dataValue(data, 2, 'fakeModel'),
        );
      },
      ACPITable.ssdtBridge.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtPCIBridge(pciBridges: context?.data?.toList()),
      ACPITable.ssdtALS0.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtALS0(prebuilt: _pb(context)),
      ACPITable.ssdtIMEI.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtIMEI(
            prebuilt: _pb(context),
            fakeid: action?['extra'] ?? context?.data,
          ),
      ACPITable.ssdtFixShutdown.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtFixShutdown(prebuilt: _pb(context)),
      ACPITable.checkSystemState.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.checkSystemState(facpPath: context?.data),
      ACPITable.checkAOAC.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.checkAOAC(facpPath: context?.data),
      ACPITable.ssdtGPRW.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtGPRW(prebuilt: _pb(context)),
      ACPITable.ssdtUPRW.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtUPRW(prebuilt: _pb(context)),
      ACPITable.ssdtRMNE.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtRMNE(),
      ACPITable.ssdtGPI0.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtGPI0(prebuilt: _pb(context)),
      ACPITable.ssdtCPUR.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtCPUR(prebuilt: _pb(context)),
      ACPITable.ssdtRHUB.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtRHUB(prebuilt: _pb(context)),
      ACPITable.ssdtUNC.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtUNC(prebuilt: _pb(context)),
      ACPITable.ssdtDTGP.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtDTGP(prebuilt: _pb(context)),
      ACPITable.ssdtDMAC.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtDMAC(prebuilt: _pb(context)),
      ACPITable.ssdtLID.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtLID(prebuilt: _pb(context)),
      ACPITable.ssdtPWRB.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtPWRB(prebuilt: _pb(context)),
      ACPITable.ssdtWakeScreen.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtWakeScreen(prebuilt: _pb(context)),
      ACPITable.ssdtLED.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtLED(prebuilt: _pb(context)),
      ACPITable.ssdtS3Disable.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtS3Disable(prebuilt: _pb(context)),
      ACPITable.ssdtSLPB.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtSLPB(prebuilt: _pb(context)),
      ACPITable.ssdtMEM2.name: (
              {PatchContext? context, Map<String, dynamic>? action}) =>
          ssdt.ssdtMEM2(prebuilt: _pb(context)),
    };
  }

  dynamic _actionData(PatchContext? context, Map<String, dynamic>? action) {
    final extra = action?['extra'];
    if (extra is Map || extra is List) return extra;
    return context?.data;
  }

  String? _dataValue(dynamic data, int index, String key) {
    if (data is Map) return data[key]?.toString();
    if (data is List && index < data.length) return data[index]?.toString();
    try {
      return switch (index) {
        0 => data?.$1?.toString(),
        1 => data?.$2?.toString(),
        2 => data?.$3?.toString(),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> runPatch(
    Map<String, dynamic> action, {
    PatchContext? context,
    String? outputFolder,
    Function(String)? onError,
  }) async {
    final executor = _actionMap[action.name];
    if (executor != null) {
      try {
        final ctx = context ?? PatchContext();
        ssdt.outputFolder = outputFolder ?? resultFolder;
        await executor(context: ctx, action: action);
      } catch (e) {
        onError?.call('执行失败: $action, 错误: $e');
      }
    } else {
      onError?.call('不支持的补丁操作: $action');
    }
  }

  Future<void> runPatchBatch(
    Future<void> Function() action, {
    bool Function()? shouldSave,
  }) async {
    ssdt.beginPlistBatch();
    try {
      await action();
      await ssdt.endPlistBatch(save: shouldSave?.call() ?? true);
    } catch (_) {
      await ssdt.endPlistBatch(save: false);
      rethrow;
    }
  }

  Future<void> runPatches(
    List<Map<String, dynamic>> actions, {
    PatchContext? context,
    String? outputFolder,
    Function(String)? onError,
    bool copyToResults = true,
  }) async {
    // 清空 outputFolder 目录
    if (outputFolder != null) {
      await ssdt.util.clearDirectory(
        ssdt.config.outputDirectory!,
        outputFolder,
      );
    }
    // 清空 resultFolder 目录
    await ssdt.util.clearDirectory(ssdt.config.outputDirectory!, resultFolder);

    for (var action in actions) {
      await runPatch(
        action,
        context: context,
        outputFolder: outputFolder,
        onError: onError,
      );
    }

    final outputPath = path.join(ssdt.config.outputDirectory!, outputFolder);
    final resultPath = path.join(ssdt.config.outputDirectory!, resultFolder);

    await _waitForDirectoryStable(outputPath);

    if (copyToResults) {
      await ssdt.util.copyDirectory(outputPath, resultPath);
    }
  }

  Future<void> copyPatchOutputToResults(String outputFolder) async {
    final outputPath = path.join(ssdt.config.outputDirectory!, outputFolder);
    final resultPath = path.join(ssdt.config.outputDirectory!, resultFolder);

    await _waitForDirectoryStable(outputPath);
    await ssdt.util.clearDirectory(ssdt.config.outputDirectory!, resultFolder);
    await ssdt.util.copyDirectory(outputPath, resultPath);
  }

  Future<void> _waitForDirectoryStable(
    String dirPath, {
    Duration interval = const Duration(milliseconds: 300),
    int stableRounds = 3,
  }) async {
    if (!Directory(dirPath).existsSync()) return;

    List<FileStat> snapshot() {
      return Directory(dirPath)
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => FileStat.statSync(f.path))
          .toList();
    }

    List<FileStat> prev = snapshot();

    int stableCount = 0;
    while (stableCount < stableRounds) {
      await Future.delayed(interval);
      final current = snapshot();

      bool changed = current.length != prev.length ||
          current.asMap().entries.any(
                (e) =>
                    e.key < prev.length &&
                    e.value.modified != prev[e.key].modified,
              );

      if (changed) {
        stableCount = 0;
        prev = current;
      } else {
        stableCount++;
      }
    }
  }

  ///  默认输出目录
  String getDesktopDirectory() => ssdt.util.getDesktopDirectory();

  void checkIaslValid({bool? local, bool? legacy}) =>
      ssdt.checkIaslValid(local: local, legacy: legacy);

  ///  导出 ACPI 表
  Future<String?> dumpTables(
    String filePath, {
    bool disassemble = false,
    Future<String?> Function()? onRequestSudoPassword,
  }) async =>
      await ssdt.dumpTables(
        filePath,
        disassemble: disassemble,
        onRequestSudoPassword: onRequestSudoPassword,
      );

  Future<String?> loadTables(String dumpPath) async =>
      await ssdt.loadTables(dumpPath);

  /// ================== 合并 plist 文件 ==================
  Future<void> mergePlist(
    String patchedPath,
    String configPath, {
    bool overwrite = true,
    bool backupBeforeOverwrite = true,
  }) async {
    _merge
      ..patchedPath = patchedPath
      ..configPath = configPath
      ..overwrite = overwrite
      ..backupBeforeOverwrite = backupBeforeOverwrite;
    await _merge.mergePlist();
  }

  String? getPlistType(String plistPath, {Function(String)? onError}) {
    final result = _merge.getPlistInfo(plistPath);
    if (result.$3 != null) {
      onError?.call('获取 plist 类型失败: ${result.$3}');
    }
    return result.$1.value;
  }
}
