//  ssdt.dart
//  Created by JeoJay127
//
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:rapidefi/extension/string_extension.dart';
import 'dsdt.dart';
import 'parser.dart';
import 'util.dart';
import '../log/log.dart';
import 'config.dart';
import 'prebuilt.dart';
import 'run.dart';
import 'package:path/path.dart' as path;
import 'battery_external_normalizer.dart';
import 'battery_body_transformer.dart';
import 'battery_namespace_resolver.dart';

typedef _NativePnlfDevice = ({
  String tableName,
  Map<String, dynamic> table,
  List<dynamic> path,
});

class SSDT {
  final Run run = Run();
  final DSDT d;
  final Util util = Util();
  final targetIrqs = [0, 2, 8, 11];
  final illegalNames = ["XHC1", "EHC1", "EHC2", "PXSX"];
  final Map<String, List<String>> ssdtDependencies = const {
    "SSDT-SleepHook.aml": [
      "SSDT-LID.aml",
      "SSDT-FixShutdown.aml",
      "SSDT-WakeScreen.aml",
      "SSDT-LED.aml",
    ],
  };

  final String legacyWarning =
      '注意:旧版iasl-legacy仅支持macOS 10.6及更早版本，目前主流系统使用可能存在兼容性问题,谨慎使用!!!\n';

  AcpiConfig config;

  String outputFolder = 'Results';
  ACPIMatchMode? _lastACPIMatchMode = ACPIMatchMode.leastStrict;
  int _plistBatchDepth = 0;
  final Map<String, Map<String, dynamic>> _batchedPlists = {};
  List<BatteryNamespaceObject> _batteryNamespaceObjects = const [];
  final Set<String> _batteryBodyExternals = {};
  final Set<String> _batteryRegionWarnings = {};

  /// 预制补丁
  final prePatches = [
    {
      "PrePatch": "GPP7 duplicate _PRW methods",
      "Comment": "GPP7._PRW to XPRW to fix Gigabyte's Mistake",
      "Find": "3708584847500A021406535245470214065350525701085F505257",
      "Replace": "3708584847500A0214065352454702140653505257010858505257",
    },
    {
      "PrePatch": "GPP7 duplicate UP00 devices",
      "Comment": "GPP7.UP00 to UPXX to fix Gigabyte's Mistake",
      "Find": "1047052F035F53425F50434930475050375B82450455503030",
      "Replace": "1047052F035F53425F50434930475050375B82450455505858",
    },
    {
      "PrePatch": "GPP6 duplicate _PRW methods",
      "Comment": "GPP6._PRW to XPRW to fix ASRock's Mistake",
      "Find": "47505036085F4144520C04000200140F5F505257",
      "Replace": "47505036085F4144520C04000200140F58505257",
    },
    {
      "PrePatch": "GPP1 duplicate PTXH devices",
      "Comment": "GPP1.PTXH to XTXH to fix MSI's Mistake",
      "Find": "50545848085F41445200140F",
      "Replace": "58545848085F41445200140F",
    },
  ];

  /// 构造函数
  /// [config] 配置
  SSDT({required this.config})
    : d = DSDT(
        useLocaliAsl: config.useLocaliAsl,
        useLeagcyiAsl: config.useLeagcyiAsl,
      );

  /// 转储表
  /// [filePath] 输入DSDT路径
  /// [disassemble] 是否反编译
  Future<String?> dumpTables(
    String filePath, {
    bool disassemble = false,
    Future<String?> Function()? onRequestSudoPassword,
    bool throwOnFailure = false,
  }) async => await d.dumpTables(
    filePath,
    disassemble: disassemble,
    onRequestSudoPassword: onRequestSudoPassword,
    throwOnFailure: throwOnFailure,
  );

  void checkIaslValid({bool? local, bool? legacy}) {
    if (local != null) {
      config = config.copyWith(useLocaliAsl: local);
      d.useLocaliAsl = local;
    }
    if (legacy != null) {
      config = config.copyWith(useLeagcyiAsl: legacy);
      d.useLeagcyiAsl = legacy;
    }
    d.acpiTool.checkIaslValid();
  }

  /// 自然排序
  /// [list] 待排序的字符串列表
  /// [first] 指定排到最前的名称
  List<String> sortedNicely(List<String> list, {String? first = "DSDT"}) {
    // 分割字符串为数字 / 非数字的序列
    List<dynamic> alphanumKey(String key) {
      final regex = RegExp(r'(\d+)');
      final parts = <dynamic>[];
      int lastIndex = 0;

      for (final match in regex.allMatches(key.toLowerCase())) {
        if (lastIndex < match.start) {
          parts.add(key.substring(lastIndex, match.start));
        }
        parts.add(int.parse(match.group(0)!));
        lastIndex = match.end;
      }
      if (lastIndex < key.length) {
        parts.add(key.substring(lastIndex));
      }
      return parts;
    }

    bool isFirst(String name) {
      if (first == null) return false;
      final lowerName = name.toLowerCase();
      final lowerFirst = first.toLowerCase();
      // 去掉后缀，仅比较表名
      final baseName = lowerName.split('.').first;
      return baseName == lowerFirst;
    }

    list.sort((a, b) {
      // 优先让 first 指定的表名排在最前
      final aIsFirst = isFirst(a);
      final bIsFirst = isFirst(b);

      if (aIsFirst && !bIsFirst) return -1;
      if (bIsFirst && !aIsFirst) return 1;

      // 其他项按自然排序
      final aKey = alphanumKey(a);
      final bKey = alphanumKey(b);

      for (int i = 0; i < aKey.length && i < bKey.length; i++) {
        final ax = aKey[i];
        final bx = bKey[i];

        if (ax is int && bx is int) {
          final cmp = ax.compareTo(bx);
          if (cmp != 0) return cmp;
        } else {
          final cmp = ax.toString().compareTo(bx.toString());
          if (cmp != 0) return cmp;
        }
      }
      return aKey.length.compareTo(bKey.length);
    });

    return list;
  }

  /// 从行中获取地址
  /// [line] 行号
  /// [splitBy] 分隔符
  /// [table] 表
  int? getAddressFromLine(
    int line, {
    String splitBy = '_ADR, ',
    Map<String, dynamic>? table,
  }) {
    // 如果未提供table，则获取 DSDT 或唯一表
    table ??= d.getDsdt();
    try {
      String rawLine = table?['lines'][line];
      String part = rawLine.split(splitBy)[1].split(')')[0];
      part = part
          .replaceAll('Zero', '0x0')
          .replaceAll('One', '0x1')
          .replaceFirst('0x', '');
      return int.parse(part, radix: 16);
    } catch (e) {
      debugPrint('Error Address : $e');
      return null;
    }
  }

  /// 获取 LPC 名称
  /// [skipEc] 是否跳过 EC 设备
  /// [skipCommonNames] 是否跳过常见名称
  String? getLpcName({bool skipEc = false, bool skipCommonNames = false}) {
    Log("正在定位 LPC(B)/SBRG…");

    for (final tableName in sortedNicely(d.acpiTables.keys.toList())) {
      final table = d.acpiTables[tableName]!;

      // 检查 EC 设备
      if (!skipEc) {
        final ecList = d.getDevicePathsWithHid(hid: "PNP0C09", table: table);
        if (ecList.isNotEmpty) {
          final lpcName = ecList[0][0]
              .split(".")
              .sublist(0, ecList[0][0].split(".").length - 1)
              .join(".");
          Log("=> 在 $tableName 中找到 $lpcName");
          return lpcName;
        }
      }

      // 检查常见名称
      if (!skipCommonNames) {
        for (final name in ["LPCB", "LPC0", "LPC", "SBRG", "PX40"]) {
          final paths = d.getDevicePaths(obj: name, table: table);
          if (paths.isNotEmpty && paths[0].isNotEmpty) {
            var lpcName = paths[0][0];
            Log("=> 在 $tableName 中找到 $lpcName");
            return lpcName;
          }
        }
      }

      // 检查地址
      final paths = d.getPathOfType(objType: "Name", obj: "_ADR", table: table);
      for (final path in paths) {
        final adr = getAddressFromLine(path[1], table: table);
        if (adr == 0x001F0000 || adr == 0x00140003) {
          // 移除 ._ADR
          final lpcName = path[0].substring(0, path[0].length - 5);
          final lpcHid = "$lpcName._HID";
          if (table['paths'].any((x) => x[0] == lpcHid)) continue;
          Log("=> 在 $tableName 中找到 $lpcName");
          return lpcName;
        }
      }
    }

    Log.warning("=> 未能找到 LPC(B)！已终止操作！");
    // 未找到 LPC(B)
    return null;
  }

  /// 确保 DSDT 存在
  /// [allowAny] 是否允许任何 DSDT
  bool _ensureDSDT({bool allowAny = false}) {
    if (allowAny) {
      return d.acpiTables.isNotEmpty;
    } else {
      return d.getDsdt() != null;
    }
  }

  /// 确保 DSDT 存在
  /// [allowAny] 是否允许任何 DSDT
  Future<bool> ensureDSDT({bool allowAny = false}) async {
    // 检查是否已经有有效的 iasl
    if (!checkIasl()) return false;
    // 检查是否已经有有效的 dsdt
    if (_ensureDSDT(allowAny: allowAny)) return true;
    // 未找到有效的 dsdt
    Log.warning("未找到有效的 DSDT ！请先选择一个 DSDT 文件或包含 DSDT 的文件目录!");
    return false;
  }

  /// 选择 DSDT
  /// [singleTable] 是否仅选择一个表
  /// [dsdtPath] DSDT 文件路径
  Future<String?> selectDsdt({
    bool singleTable = false,
    String? dsdtPath,
  }) async {
    // 如果传入了 DSDT 文件路径，直接验证和加载
    if (dsdtPath != null && dsdtPath.isNotEmpty) {
      Log("提供的 DSDT 路径：$dsdtPath");
      String out = await util.checkPath(filePath: dsdtPath);
      if (out.isNotEmpty) {
        // 路径有效，加载并返回结果
        return await loadTables(out);
      } else {
        Log("提供的 DSDT 路径无效：$dsdtPath");
        // 路径无效，返回 null
        return null;
      }
    }
    return null;
  }

  /// 获取唯一设备 (设备名称, 设备编号)
  /// [parentPath] 父路径
  /// [baseName] 基础名称
  /// [startingNumber] 起始数字
  /// [usedNames] 已使用名称
  ({String name, int number}) getUniqueDevice(
    String parentPath,
    String baseName, {
    int startingNumber = 0,
    List<String> usedNames = const [],
  }) {
    int num = startingNumber;

    while (true) {
      String name;

      if (num < 0) {
        // 尝试原始名称
        name = baseName;
        // 下一轮开始从 0
        num = 0;
      } else {
        // 将数字转为大写十六进制，并附加在 baseName 后
        final hexNum = num.toRadixString(16).toUpperCase();
        final maxLen = baseName.length - hexNum.length;
        // 防止越界
        name = maxLen > 0 ? baseName.substring(0, maxLen) + hexNum : hexNum;
      }

      final fullPath = '${parentPath.replaceAll(RegExp(r'\.$'), '')}.$name';

      if (d.getDevicePaths(obj: fullPath).isEmpty &&
          !usedNames.contains(name)) {
        return (name: name, number: num);
      }

      num += 1;
    }
  }

  String _normalizeObjectPath(String path) {
    return path
        .trim()
        .replaceAll('\\', '')
        .split('.')
        .map((segment) {
          var normalized = segment.toUpperCase();
          while (normalized.endsWith('_')) {
            normalized = normalized.substring(0, normalized.length - 1);
          }
          return normalized;
        })
        .where((segment) => segment.isNotEmpty)
        .join('.');
  }

  /// 分配一个不会与所有已加载 ACPI 表中任意对象类型冲突的 NameSeg。
  ({String name, int number}) getUniqueObjectName(
    String parentPath,
    String baseName, {
    int startingNumber = -1,
    List<String> usedNames = const [],
  }) {
    var base = baseName.trim().toUpperCase();
    if (base.length > 4) base = base.substring(0, 4);
    if (base.isEmpty) return (name: '', number: startingNumber);

    final unavailable = usedNames
        .map((name) => name.trim().toUpperCase())
        .toSet();
    final parent = _normalizeObjectPath(parentPath);
    final parentPrefix = parent.isEmpty ? '' : '$parent.';

    for (final rawTable in d.acpiTables.values) {
      if (rawTable is! Map) continue;
      final table = Map<String, dynamic>.from(rawTable);
      final rawPaths = table['paths'];
      final paths = rawPaths is List && rawPaths.isNotEmpty
          ? rawPaths
          : d.getPaths(table: table);
      for (final rawPath in paths) {
        if (rawPath is! List || rawPath.isEmpty) continue;
        final normalized = _normalizeObjectPath(rawPath.first.toString());
        if (!normalized.startsWith(parentPrefix)) continue;
        final child = normalized.substring(parentPrefix.length);
        if (child.isNotEmpty && !child.contains('.')) {
          unavailable.add(child);
        }
      }
    }

    var number = startingNumber;
    while (true) {
      if (number < 0) {
        if (!unavailable.contains(base)) return (name: base, number: 0);
        number = 0;
        continue;
      }
      final suffix = number.toRadixString(16).toUpperCase();
      final prefixLength = 4 - suffix.length;
      final candidate =
          '${prefixLength > 0 ? base.substring(0, prefixLength) : ''}$suffix';
      if (!unavailable.contains(candidate)) {
        return (name: candidate, number: number);
      }
      number += 1;
    }
  }

  /// 获取唯一名称
  /// [name] 名称
  /// [targetFolder] 目标文件夹
  /// [nameAppend] 名称后缀
  String getUniqueName(
    String name,
    String targetFolder, {
    String nameAppend = "-Patched",
  }) {
    // 获取文件的扩展名
    String ext = name.contains('.') ? name.split('.').last : '';
    // 去除扩展名部分
    if (ext.isNotEmpty) {
      name = name.substring(0, name.length - ext.length - 1);
    }
    // 如果有指定后缀，则添加
    if (nameAppend.isNotEmpty) {
      name = '$name$nameAppend';
    }
    // 检查文件名是否已经存在
    String checkName = ext.isNotEmpty ? '$name.$ext' : name;
    if (!File('$targetFolder/$checkName').existsSync()) {
      return checkName;
    }

    // 需要生成唯一的文件名
    int num = 1;
    while (true) {
      checkName = '$name-$num';
      if (ext.isNotEmpty) {
        checkName = '$checkName.$ext';
      }
      if (!File('$targetFolder/$checkName').existsSync()) {
        return checkName;
      }
      // 增加数字计数
      num++;
    }
  }

  /// 检查 iasl 工具是否存在
  bool checkIasl() {
    if (config.useLeagcyiAsl) {
      Log.warning(legacyWarning);
    }
    if (d.acpiTool.iasl.isEmpty) {
      Log.error("iasl工具准备失败!请先更新或者使用内置的iasl工具!");
      return false;
    }
    return true;
  }

  /// 加载 DSDT 或文件夹中的有效 ACPI 表
  /// [fileOrFolderPath] 文件或文件夹路径
  Future<String?> loadTables(String fileOrFolderPath) async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await d.acpiTool.initialize();
    }
    if (!checkIasl() || fileOrFolderPath.isEmpty) return null;
    final stopwatch = Stopwatch()..start();
    try {
      List<String> tables = [];
      List<String> exclude = [];
      String? externalDsdtPath;
      String? troubleDsdt;
      bool fixed = false;
      String? temp;
      // 备份 acpiTables
      final priorTables = Map<String, dynamic>.from(d.acpiTables);
      // 清空 acpiTables
      d.acpiTables.clear();
      if (Directory(fileOrFolderPath).existsSync()) {
        Log("正在从目录 $fileOrFolderPath 收集有效ACPI表...");
        final dir = Directory(fileOrFolderPath);
        final items = dir
            .listSync()
            .whereType<File>() // 只保留文件（排除目录）
            .where(
              (f) =>
                  f.path.toLowerCase().endsWith('.aml') ||
                  f.path.toLowerCase().endsWith('.dat'),
            ) // 只保留 .aml 或 .dat 文件
            .map((e) => path.basename(e.path))
            .toList();
        for (var item in sortedNicely(items)) {
          if (d.tableIsValid(fileOrFolderPath, tableName: item)) {
            tables.add(item);
          }
        }
        Log('共找到 ${items.length} 个ACPI表, 其中 ${tables.length} 个有效:');
        for (var table in tables) {
          Log('   $table');
        }
        if (tables.isEmpty) {
          final acpiDir = Directory(path.join(fileOrFolderPath, "ACPI"));
          if (acpiDir.existsSync()) {
            return await loadTables(path.join(fileOrFolderPath, "ACPI"));
          }

          Log.warning("未找到有效的 .aml 文件!\n");
          d.acpiTables.addAll(priorTables);
          return null;
        }

        final dsdtList = tables
            .where(
              (t) => d.tableSignature(path.join(fileOrFolderPath, t)) == "DSDT",
            )
            .toList();
        if (dsdtList.isEmpty) {
          Log.warning("未找到有效的 DSDT ！请先选择一个 DSDT 文件或包含 DSDT 的文件目录!");
          return null;
        }
        if (dsdtList.length > 1) {
          Log("多个带有 DSDT 签名的文件已通过验证：");
          for (var dsdt in sortedNicely(dsdtList)) {
            Log("=> $dsdt");
          }
          Log.warning("当前检测到多个 DSDT 文件，每次仅允许处理一个.请保留一个 DSDT 文件，其余请移除后再试.\n");
          d.acpiTables = priorTables;
          return null;
        }

        final dsdt = dsdtList.isNotEmpty ? dsdtList.first : null;
        if (dsdt != null && dsdt.isNotEmpty) {
          Log("");
          Log("正在反编译 DSDT/SSDT，并检查是否需要应用预制补丁…");
          final mixedTables = tables
              .where(
                (table) => const {"DSDT", "SSDT"}.contains(
                  d.tableSignature(path.join(fileOrFolderPath, table)),
                ),
              )
              .toList();
          final otherTables = tables
              .where((table) => !mixedTables.contains(table))
              .toList();

          if (mixedTables.length == 1) {
            Log('正在反编译 ${mixedTables.first} 文件...');
          } else {
            Log('正在批量反编译 DSDT.aml 和 SSDT.aml 文件...');
          }

          final dsdtPath = path.join(fileOrFolderPath, dsdt);
          final (dsdtResult, dsdtFailed) = await d.loadTable(
            dsdtPath,
            logProgress: false,
          );
          if (dsdtResult.isNotEmpty) {
            externalDsdtPath = dsdtPath;
            Log('=> $dsdt 反编译成功！');

            final failed = <dynamic>[...dsdtFailed];
            final retryTables = <String>[];
            for (final table in mixedTables.where((table) => table != dsdt)) {
              final tablePath = path.join(fileOrFolderPath, table);
              final (tableResult, _) = await d.loadTable(
                tablePath,
                externalTables: [dsdtPath],
                logProgress: false,
              );
              if (tableResult.isNotEmpty) {
                Log('=> $table 反编译成功！');
              } else {
                Log.warning('=> $table 反编译失败！');
                retryTables.add(table);
              }
              await Log.yieldToUi();
            }

            if (retryTables.isNotEmpty) {
              Log('');
              Log('正在单独反编译失败的.aml 文件...');
              for (final table in retryTables) {
                final tablePath = path.join(fileOrFolderPath, table);
                final (tableResult, tableFailed) = await d.loadTable(
                  tablePath,
                  logProgress: false,
                );
                if (tableResult.isNotEmpty) {
                  Log('=> $table 反编译成功！');
                } else {
                  Log.error('=> $table 反编译失败！');
                  failed.addAll(
                    tableFailed.isEmpty ? [tablePath] : tableFailed,
                  );
                }
                await Log.yieldToUi();
              }
              Log('');
            }

            if (otherTables.isNotEmpty) {
              Log('正在反编译其他.aml文件...');
              for (final table in otherTables) {
                final (tableResult, tableFailed) = await d.loadTable(
                  path.join(fileOrFolderPath, table),
                  logProgress: false,
                );
                failed.addAll(tableFailed);
                if (tableResult.isNotEmpty) {
                  Log('=>  $table 反编译成功！');
                }
                await Log.yieldToUi();
              }
            }

            Log('=> 无需应用预制补丁!\n');
            if (failed.isNotEmpty) {
              Log.warning(
                '=> ${failed.length} 个非 DSDT 表反编译失败并已跳过: ${failed.map((item) => path.basename(item.toString())).join(', ')}',
              );
            }
            Log("所有有效ACPI表反编译完成!");
            return fileOrFolderPath;
          }
          troubleDsdt = dsdt;
          d.acpiTables.clear();
        }
      } else if (File(fileOrFolderPath).existsSync()) {
        Log("正在加载 ${path.basename(fileOrFolderPath)}...");
        final (result, failed) = await d.loadTable(fileOrFolderPath);
        if (d.tableSignature(fileOrFolderPath) != "DSDT") {
          Log.warning("无效 DSDT 文件！请重新选择一个有效 DSDT 文件!");
          d.acpiTables.addAll(priorTables);
          return null;
        }
        if (result.isNotEmpty || (result[0] != null && result[0].isNotEmpty)) {
          Log("已处理完成!\n");
          return path.dirname(fileOrFolderPath);
        }
        troubleDsdt = path.basename(fileOrFolderPath);
        tables.add(troubleDsdt);
        fileOrFolderPath = path.dirname(fileOrFolderPath);
      } else {
        Log("传入的文件或文件夹不存在!\n");
        d.acpiTables = priorTables;
        return null;
      }

      // 处理有问题的 DSDT 文件
      if (troubleDsdt != null && troubleDsdt.isNotEmpty) {
        Log("处理有问题的 DSDT 文件 ...");
        temp = Directory.systemTemp.createTempSync().path;
        for (var table in tables) {
          File(
            path.join(fileOrFolderPath, table),
          ).copySync(path.join(temp, table));
        }

        final troublePath = path.join(temp, troubleDsdt);
        Log("检查可用的预制补丁…");
        Log("正在将 $troubleDsdt 文件加载到内存…");
        var data = await File(troublePath).readAsBytes();
        final out = await util.checkPath(
          filePath: path.join(temp, "output"),
          onError: (error) => Log.error(error),
        );
        final targetName = getUniqueName(
          troubleDsdt,
          out,
          nameAppend: "-Patched",
        );

        List<Map<String, String>> patches = [];
        Log("正在逐个处理补丁…\n");
        for (var patch in prePatches) {
          if (!(patch.containsKey("PrePatch") &&
              patch.containsKey("Comment") &&
              patch.containsKey("Find") &&
              patch.containsKey("Replace"))) {
            continue;
          }
          Log(" => ${patch["PrePatch"]}");
          final find = Uint8List.fromList(List.from(patch["Find"]!.codeUnits));
          if (util.containsSublist(data, find)) {
            patches.add(patch);
            final replace = Uint8List.fromList(
              List.from(patch["Replace"]!.codeUnits),
            );
            Log("=> 已定位, 正在应用…");
            data = Uint8List.fromList(
              data.sublist(0, data.indexOf(find.first)) +
                  replace +
                  data.sublist(data.indexOf(find.first) + find.length),
            );
            File(troublePath).writeAsBytesSync(data);
            final (result, failed) = await d.loadTable(troublePath);
            if (result.isNotEmpty) {
              fixed = true;
              externalDsdtPath = troublePath;
              Log("=> 先前问题DSDT文件反编译成功!");
              exclude.remove(troublePath);
              makePlist(acpi: null, patches: patches);
              File(path.join(outputFolder, targetName)).writeAsBytesSync(data);
              Log("=> 补丁已应用到修改后的文件，文件保存在 Results 文件夹中：\n   $targetName");
              break;
            }
          }
        }

        if (!fixed) {
          Log.error("$troubleDsdt 反编译失败!\n");
          Directory(temp).deleteSync(recursive: true);
          d.acpiTables = priorTables;
          return null;
        }
      }

      if (tables.length > 1) {
        Log("正在加载 $fileOrFolderPath 中的有效ACPI表…");
      }
      final result = <String, dynamic>{};
      final failed = <dynamic>[];
      for (final table in tables) {
        if (exclude.contains(table)) continue;
        final tablePath = path.join(fileOrFolderPath, table);
        final isSsdt = d.tableSignature(tablePath) == "SSDT";
        final (tableResult, tableFailed) = await d.loadTable(
          tablePath,
          externalTables: isSsdt && externalDsdtPath != null
              ? [externalDsdtPath]
              : const [],
        );
        result.addAll(Map<String, dynamic>.from(tableResult));
        failed.addAll(tableFailed);
        await Log.yieldToUi();
      }

      if (result.isEmpty && failed.isNotEmpty) {
        d.acpiTables = priorTables;
      }
      Log("所有有效ACPI表反编译完成!");
      if (temp != null && temp.isNotEmpty) {
        Directory(temp).deleteSync(recursive: true);
      }
      return fileOrFolderPath;
    } finally {
      stopwatch.stop();
      final totalTimeMs = stopwatch.elapsedMilliseconds;
      final totalSeconds = (totalTimeMs / 1000).toStringAsFixed(2);
      Log('总耗时：$totalSeconds 秒\n');
    }
  }

  /// 写入 SSDT 文件
  /// [ssdtName] SSDT 名称
  /// [ssdt] SSDT 内容
  /// [delDsl] 是否删除 .dsl 文件
  Future<bool> writeSSDT(String ssdtName, String ssdt, {bool? delDsl}) async {
    delDsl ??= config.deleteDsl;

    // 确保输出路径存在
    final String res = await util.checkPath(
      filePath: path.join(config.outputDirectory ?? '', outputFolder),
      onError: (error) => Log.error(error),
    );

    // 唯一临时名（只用于编译）
    final String uid = DateTime.now().microsecondsSinceEpoch.toString();
    final String tmpDsl = path.join(res, '$ssdtName.$uid.dsl');
    final String tmpAml = path.join(res, '$ssdtName.$uid.aml');

    // 最终目标 AML（固定）
    final String finalDsl = path.join(res, '$ssdtName.dsl');
    final String finalAml = path.join(res, '$ssdtName.aml');

    final String iaslPath = d.acpiTool.iasl;
    // 写入临时 DSL
    await File(tmpDsl).writeAsString(ssdt);

    Log(
      '正在${config.useLeagcyiAsl ? '使用【iasl-legacy旧版编译器】' : ''}编译 $ssdtName.aml...',
      level: config.useLeagcyiAsl ? LogLevel.warning : LogLevel.info,
    );

    final List<String> iaslArgs = config.force
        ? [iaslPath, '-f', tmpDsl]
        : [iaslPath, tmpDsl];

    try {
      final out = await run.run([
        {'args': iaslArgs},
      ]);
      if (out[2] != '0') {
        Log.error('编译结果 : ${out[1]}');
        Log.error(
          '编译失败!'
          '${config.useLeagcyiAsl ? ' 建议更换新版 iasl 或开启强制编译再试!' : ''}',
        );
        return false;
      }

      Log('编译 $ssdtName.aml 成功!');
      // 编译成功，重命名 AML 文件
      await File(tmpAml).rename(finalAml);
      return true;
    } finally {
      // 始终清理临时 DSL
      final tmpDslFile = File(tmpDsl);
      if (await tmpDslFile.exists()) {
        // 用于日志提示删除操作
        if (delDsl) Log('删除 $ssdtName.dsl 源文件');
        await tmpDslFile.delete();
      }
      // 如果不保留 DSL，删除最终 DSL
      if (delDsl) {
        final finalDslFile = File(finalDsl);
        if (await finalDslFile.exists()) {
          await finalDslFile.delete();
        }
      } else {
        await File(finalDsl).writeAsString(ssdt);
      }
    }
  }

  /// 提取设备 Field 中的字段名称。
  List<String> getFieldVarWithPath(String devicePath) {
    final deviceInfo = getDeviceAllInfo(path: devicePath);
    final scopeFields = deviceInfo['scopeFields'] as List<dynamic>? ?? const [];
    return [
      for (final scopeField in scopeFields)
        if (scopeField is Map)
          for (final field
              in scopeField['fields'] as List<dynamic>? ?? const [])
            if (field is Map && field['name'] != null) field['name'].toString(),
    ];
  }

  /// 获取设备的 STA 变量
  /// [varS] STA 变量名称
  /// [device] 设备名称
  /// [devHid] 设备 HID
  /// [devName] 设备名称
  /// [table] ACPI 表
  Map<String, dynamic> getStaVar({
    String varS = "STAS",
    String? device,
    String devHid = "ACPI000E",
    String devName = "AWAC",
    Map<String, dynamic>? table,
  }) {
    table ??= d.getDsdt();
    bool hasVar = false;
    List<Map<String, dynamic>> patches = [];
    String? root;

    // 如果提供了设备,先定位设备
    List<List<dynamic>> devList;
    if (device != null && device.isNotEmpty) {
      devList = d.getDevicePaths(obj: device, table: table);
      if (devList.isEmpty) {
        Log("=> 无法定位 $device");
        return {"value": false};
      }
    } else {
      // 如果没有提供设备,直接定位 HID
      Log("正在定位 $devHid ($devName) 设备…");
      devList = d.getDevicePathsWithHid(hid: devHid, table: table);
      if (devList.isEmpty) {
        Log("=> 无法定位到任何 $devHid 设备");
        return {"valid": false};
      }
    }

    var dev = devList[0];
    Log("=> 找到 ${dev[0]}");

    root = dev[0].split(".")[0];
    Log("=> 正在查找验证 _STA…");

    // 先检查方法,再检查名称
    String staType = "MethodObj";
    var sta = d.getMethodPaths(obj: "${dev[0]}._STA", table: table);
    var xsta = d.getMethodPaths(obj: "${dev[0]}.XSTA", table: table);

    if (sta.isEmpty && xsta.isEmpty) {
      // 检查名称
      staType = "IntObj";
      sta = d.getNamePaths(obj: "${dev[0]}._STA", table: table);
      xsta = d.getNamePaths(obj: "${dev[0]}.XSTA", table: table);
    }

    /// 检查是否已经 XSTA 重命名
    if (xsta.isNotEmpty && sta.isEmpty) {
      Log("=> _STA 已经重命名为 XSTA！跳过其他检查…");
      Log("=> 请禁用DSDT中该设备的 _STA 到 XSTA 的重命名，重启后再试!\n");
      return {
        "valid": false,
        "break": true,
        "device": dev,
        "dev_name": devName,
        "dev_hid": devHid,
        "sta_type": staType,
      };
    }

    /// 检查 STA 变量是否存在
    if (sta.isNotEmpty) {
      if (varS.isNotEmpty) {
        var scope = d
            .getScope(
              startingIndex: sta[0][1],
              stripComments: true,
              table: table,
            )
            .join("\n");
        hasVar = scope.contains(varS);
        Log("=> $varS 变量${hasVar ? '存在' : '不存在'}");
      }
    } else {
      Log("=> 未找到 _STA 方法/名称");
    }

    /// 检查是否需要为 _STA => XSTA 生成唯一的补丁
    if (sta.isNotEmpty && !hasVar) {
      var staIndex = d.findNextHex(index: sta[0][1], table: table).$2;
      Log("=> 在索引 $staIndex 处找到 _STA 方法!");
      String staHex = "5F535441"; // _STA
      String xstaHex = "58535441"; // XSTA
      Log("=> 正在生成 _STA 到 XSTA 的重命名");
      final (padl, padr) = d.getShortestUniquePad(
        currentHex: staHex,
        index: staIndex,
        table: table,
      );
      patches.add({
        "Comment": "$devName _STA to XSTA rename",
        "Find": padl + staHex + padr,
        "Replace": padl + xstaHex + padr,
      });
    }

    return {
      "valid": true,
      "has_var": hasVar,
      "sta": sta,
      "patches": patches,
      "device": dev,
      "dev_name": devName,
      "dev_hid": devHid,
      "root": root,
      "sta_type": staType,
    };
  }

  /// 检查 STA 设备是否需要补丁
  /// [sta] STA 设备信息
  /// [table] ACPI 表
  bool staNeedsPatching(Map<String, dynamic>? sta, Map<String, dynamic> table) {
    // 检查输入是否有效
    if (sta == null || !sta.containsKey("sta")) {
      return false;
    }

    // 处理 IntObj 类型
    if (sta["sta_type"] == "IntObj") {
      try {
        String staScope = table["lines"][sta["sta"][0][1]];
        if (!staScope.contains("Name (_STA, 0x0F)")) {
          return true;
        }
      } catch (e) {
        Log.error("处理IntObj类型发生错误: $e");
        return true;
      }
    }
    // 处理 MethodObj 类型
    else if (sta["sta_type"] == "MethodObj") {
      try {
        String staScope = d
            .getScope(
              startingIndex: sta["sta"][0][1],
              stripComments: true,
              table: table,
            )
            .join("\n");
        if (staScope.split("Return (").length - 1 > 1 ||
            !staScope.contains("Return (0x0F)")) {
          Log('=> 存在多个返回语句，或者返回值不是 Return (0x0F)');
          return true;
        }
      } catch (e) {
        Log.error("处理MethodObj类型发生错误: $e");
        return true;
      }
    }

    // 默认返回 false
    return false;
  }

  /// 转换整数为16进制字符串
  /// [integer] 要转换的整数
  /// [padTo] 要填充的长度，默认为0
  String hexy(int integer, {int padTo = 0}) {
    String hexStr = integer.toRadixString(16).toUpperCase();
    String padded = hexStr.padLeft(padTo, '0');
    return '0x$padded';
  }

  /// 处理转换PCI路径
  /// [devicePath] 要转换的设备路径
  String? sanitizeDevicePath(String devicePath) {
    devicePath = devicePath.trim().toLowerCase();

    if (!devicePath.startsWith('pciroot(')) {
      // 不是有效的设备路径，返回 null
      return null;
    }

    // 去除 pciroot() 和 pci()，并按 / 或 # 分割
    final raw = devicePath
        .replaceAll('pciroot(', '')
        .replaceAll('pci(', '')
        .replaceAll(')', '');

    final segments = raw.split(RegExp(r'[#/\\]'));
    final newPath = <String>[];

    for (var i = 0; i < segments.length; i++) {
      final adr = segments[i];
      if (i == 0) {
        // PciRoot 地址
        if (adr.contains(',')) return null;
        try {
          final value = int.parse(adr.replaceFirst('0x', ''), radix: 16);
          newPath.add('PciRoot(${hexy(value)})');
        } catch (_) {
          return null;
        }
      } else {
        try {
          int adr1, adr2;
          if (adr.contains(',')) {
            final parts = adr.split(',');
            adr1 = int.parse(parts[0].replaceFirst('0x', ''), radix: 16);
            adr2 = int.parse(parts[1].replaceFirst('0x', ''), radix: 16);
          } else {
            final value = int.parse(adr.replaceFirst('0x', ''), radix: 16);
            adr2 = value & 0xFF;
            adr1 = (value >> 8) & 0xFF;
          }
          newPath.add('Pci(${hexy(adr1)},${hexy(adr2)})');
        } catch (_) {
          return null;
        }
      }
    }

    return newPath.join('/');
  }

  /// 处理设备路径
  /// [inputPaths] 要处理的设备路径列表
  Map<String, String?> getDevicePath({List<String> inputPaths = const []}) {
    final Map<String, String?> paths = {};

    for (var pathEntry in inputPaths) {
      final parts = pathEntry.trim().split(RegExp(r'\s+'));
      String? path;
      String? dev;

      if (parts.length == 1) {
        path = parts[0];
      } else if (parts.length == 2) {
        path = parts[0];
        dev = parts[1];
      } else {
        // 格式错误，跳过
        continue;
      }

      // 处理 device 名称
      if (dev != null && dev.isNotEmpty) {
        dev = dev.replaceAll('_', '').toUpperCase();
        if (!RegExp(r'^[A-Z0-9]{1,4}$').hasMatch(dev)) {
          // 非法设备名,跳过
          continue;
        }
        dev = dev.padRight(4, '0');
      }

      path = sanitizeDevicePath(path);
      if (path == null || path.isEmpty) continue;
      paths[path] = dev;
    }

    return paths;
  }

  (Map<String, Map<String, dynamic>>, List<Map<String, dynamic>>)
  getDevicePaths() {
    Log("正在收集 ACPI 设备信息…");
    final deviceDict = <String, Map<String, dynamic>>{};
    final pciRootPaths = <Map<String, dynamic>>[];
    final orphanedDevices = <List<dynamic>>[];
    final sanitizedPaths = <List<dynamic>>[];

    for (final tableName in sortedNicely(d.acpiTables.keys.toList())) {
      final table = d.acpiTables[tableName];

      var pciRoots = d.getDevicePathsWithHid(hid: "PNP0A08", table: table);
      pciRoots += d.getDevicePathsWithHid(hid: "PNP0A03", table: table);
      pciRoots += d.getDevicePathsWithHid(hid: "ACPI0016", table: table);

      final paths = d.getPathOfType(objType: "Name", obj: "_ADR", table: table);

      for (final path in pciRoots) {
        if (deviceDict.containsKey(path[0])) continue;

        final deviceUid = d.getNamePaths(obj: "${path[0]}._UID", table: table);
        final adr = (deviceUid.isNotEmpty && deviceUid.length == 1)
            ? getAddressFromLine(
                deviceUid[0][1],
                splitBy: "_UID, ",
                table: table,
              )
            : 0;

        deviceDict[path[0]] = {"path": "PciRoot(${hexy(adr ?? 0)})"};
        pciRootPaths.add(deviceDict[path[0]]!);
      }

      for (final x in paths) {
        sanitizedPaths.add([
          x[0].substring(0, x[0].length - 5),
          x[1],
          x[2],
          getAddressFromLine(x[1], table: table),
        ]);
      }
    }

    Log("正在收集 ACPI 设备路径…");

    bool checkPath(List<dynamic> path) {
      final adr = path[3];
      bool adrOverflow = false;

      try {
        int adr1 = (adr >> 16) & 0xFFFF;
        int adr2 = adr & 0xFFFF;
        int radr1 = adr1;
        int radr2 = adr2;

        if (adr1 > 0xFF) {
          adrOverflow = true;
          radr1 = 0;
        }
        if (adr2 > 0xFF) {
          adrOverflow = true;
          radr2 = 0;
        }

        final pathKey = path[0];
        if (deviceDict.containsKey(pathKey)) return true;

        final parent = pathKey.split('.')..removeLast();
        final parentKey = parent.join('.');
        final parentDevice = deviceDict[parentKey];

        if (parentDevice == null || parentDevice["path"] == null) {
          return false;
        }

        var devicePath = parentDevice["path"] as String;
        devicePath += "/Pci(${hexy(adr1)},${hexy(adr2)})";
        deviceDict[pathKey] = {"path": devicePath};

        if (adrOverflow || parentDevice.containsKey("adr_overflow")) {
          deviceDict[pathKey]!["adr_overflow"] = true;
          final parentPath = parentDevice["adj_path"] ?? parentDevice["path"];
          deviceDict[pathKey]!["adj_path"] =
              "$parentPath/Pci(${hexy(radr1)},${hexy(radr2)})";

          if (adrOverflow) {
            final devOverflow =
                (deviceDict[pathKey]!["dev_overflow"] ?? <String>[])
                    as List<String>;
            devOverflow.add(pathKey);
            deviceDict[pathKey]!["dev_overflow"] = devOverflow;
          }
        }

        return true;
      } catch (_) {
        return true;
      }
    }

    sanitizedPaths.sort((a, b) => a[0].compareTo(b[0]));

    for (final path in sanitizedPaths) {
      if (!checkPath(path)) {
        orphanedDevices.add(path);
      }
    }

    if (orphanedDevices.isNotEmpty) {
      Log("正在重新检查孤立设备…");
      while (true) {
        final removed = <List<dynamic>>[];
        for (final path in orphanedDevices) {
          if (checkPath(path)) {
            removed.add(path);
          }
        }
        if (removed.isEmpty) break;
        for (final r in removed) {
          orphanedDevices.removeWhere((x) => x[0] == r[0]);
        }
      }
    }

    return (deviceDict, pciRootPaths);
  }

  /// 将形如 "Pci(0x1,0x0)/Pci(0x2,0x0)" 的路径解析为桥接地址列表
  List<int> getBridgeDevices(String path) {
    // 清理并拆分路径（去除 PciRoot/Pci/括号，按 # 或 / 分隔）
    final cleanedPath = path
        .toLowerCase()
        .replaceAll('pciroot(', '')
        .replaceAll('pci(', '')
        .replaceAll(')', '');

    final adrs = cleanedPath.split(RegExp(r'#|/'));
    final bridges = <int>[];

    for (final bridge in adrs) {
      if (bridge.isEmpty) continue;

      /// 出错，不支持桥接 PciRoot
      if (!bridge.contains(',')) return [];

      try {
        final parts = bridge.split(',');
        final adr1 = int.parse(parts[0].replaceFirst('0x', ''), radix: 16);
        final adr2 = int.parse(parts[1].replaceFirst('0x', ''), radix: 16);
        final adrInt = (adr1 << 16) + adr2;
        bridges.add(adrInt);
      } catch (_) {
        // 出错时直接返回空列表
        return [];
      }
    }

    return bridges;
  }

  /// 获取所有匹配的路径（使用元组：设备名、设备信息、是否完全匹配、匹配路径长度）
  /// 例如：('PC00.BR1A', {info}, true, 12)
  /// [deviceDict] 设备字典
  /// [matchPath] 匹配路径
  /// [adj] 是否使用 adj_path
  List<(String, Map<String, dynamic>, bool, int)> getAllMatches(
    Map<String, Map<String, dynamic>> deviceDict,
    String matchPath, {
    bool adj = false,
  }) {
    final key = adj ? 'adj_path' : 'path';
    final matches = <(String, Map<String, dynamic>, bool, int)>[];

    for (final entry in deviceDict.entries) {
      final device = entry.value[key];
      if (device is! String || device.isEmpty) continue;

      final pathLower = matchPath.toLowerCase();
      final deviceLower = device.toLowerCase();

      if (pathLower.startsWith(deviceLower)) {
        matches.add((
          entry.key,
          entry.value,
          deviceLower == pathLower,
          device.length,
        ));
      }
    }

    return matches;
  }

  /// 返回最长路径匹配的元组 (String, Map, bool, int)
  /// 例如: ('_SB.PCI0', {device info...}, true, 5)
  /// [deviceDict] 设备字典
  /// [matchPath] 匹配路径
  /// [adj] 是否使用 adj_path
  (String, Map<String, dynamic>, bool, int)? getLongestMatch(
    Map<String, Map<String, dynamic>> deviceDict,
    String matchPath, {
    bool adj = false,
  }) {
    final matches = getAllMatches(deviceDict, matchPath, adj: adj);
    if (matches.isEmpty) return null;
    // 按元组第 4 项（路径深度）降序排序
    matches.sort((a, b) => b.$4.compareTo(a.$4));
    return matches.first;
  }

  /// 通过地址获取设备路径
  /// targetAdr 目标地址
  /// excludeNames 排除名称列表
  /// 返回值: 包含设备路径、父路径和表名的元组，如果未找到则返回null
  ({String busPath, String busParent, String tableName})? getDevAtAdr({
    int targetAdr = 0x001F0004,
    List<String> excludeNames = const ["XHC"],
  }) {
    for (var tableName in sortedNicely(d.acpiTables.keys.toList())) {
      var table = d.acpiTables[tableName];
      var paths = d.getPathOfType(objType: "Name", obj: "_ADR", table: table);
      for (var path in paths) {
        var adr = getAddressFromLine(path[1], table: table);
        if (adr == targetAdr) {
          // 去掉 ._ADR
          var pathParts = path[0].split('.')..removeLast();
          if (pathParts.length > 1) {
            final lastPart = pathParts.last.toLowerCase();
            final hasExcludedName = excludeNames.any(
              (x) => lastPart.contains(x.toLowerCase()),
            );

            if (!hasExcludedName) {
              final busPath = pathParts.join('.');
              final busParent = pathParts
                  .sublist(0, pathParts.length - 1)
                  .join('.');
              return (
                busPath: busPath,
                busParent: busParent,
                tableName: tableName,
              );
            }
          }
        }
      }
    }

    return null;
  }

  /// 分割 IRQ 串，处理子串，返回结果列表
  /// [line] IRQs字符串
  List<int> getIntForLine(String line) {
    List<int> irqList = [];
    for (var i in line.split(":")) {
      irqList.add(sameLineIrq(i));
    }
    return irqList;
  }

  /// 对同一行的 IRQ（中断请求）值求和，然后返回求和结果
  /// [irq] IRQs字符串
  int sameLineIrq(String irq) {
    int total = 0;
    for (var i in irq.split(",")) {
      if (i == "#") {
        /// 当IRQ值为#时,表示空值,直接跳过
        continue;
      }
      try {
        int irqValue = int.parse(i.replaceFirst('0x', ''));
        if (irqValue > 15 || irqValue < 0) {
          /// 当IRQ值超出范围时,直接跳过
          continue;
        }
        total |= util.convertIrqToInt(irqValue);
      } catch (e) {
        /// 当IRQ值不是整数时,直接跳过
        continue;
      }
    }
    return total;
  }

  /// 从IRQs字符串中提取十六进制值
  /// [irq] IRQs字符串
  /// [remIrq] 要移除的IRQs列表
  List<Map<String, dynamic>> getHexFromIrqs(String irq, List<int>? remIrq) {
    List<Map<String, dynamic>> lines = [];
    List<int> remd = [];

    for (var a in irq.split("-")) {
      var parts = a.split("|");
      int index = int.parse(parts[0].replaceFirst('0x', ''));
      String i = parts[1];

      List<int> find = getIntForLine(i);
      List<int> repl = List.filled(find.length, 0);

      if (remIrq != null && remIrq.isNotEmpty) {
        /// 复制find列表到repl列表
        repl = List.from(find);
        for (var x in remIrq) {
          int rem = util.convertIrqToInt(x);
          // 按位操作
          List<int> repl1 = repl
              .map((y) => y >= rem ? y & (rem ^ 0xFFFF) : y)
              .toList();

          if (!util.deepEquals(repl, repl1)) {
            /// 当repl和repl1不相等时,说明有IRQ被移除
            /// 记录移除的IRQ
            remd.add(x);
          }

          /// 更新repl列表为repl1
          repl = List.from(repl1);
        }
      }

      String findHex = find.map((x) => "22${util.getHexFromInt(x)}").join('');
      String replHex = repl.map((x) => "22${util.getHexFromInt(x)}").join('');

      Map<String, dynamic> patch = {
        "irq": i,
        "find": findHex,
        "repl": replHex,
        "remd": remd,
        "index": index,
        "changed": findHex != replHex,
      };

      lines.add(patch);
    }

    return lines;
  }

  /// 从IRQs字符串中提取所有IRQ值
  /// [irq] IRQs字符串
  List<int> getAllIrqs(String irq) {
    Set<int> irqList = {};
    // 按 "-" 分割输入字符串
    for (String a in irq.split("-")) {
      // 按 "|" 分割并取第二个元素
      String i = a.split("|")[1];
      // 按 ":" 分割
      for (String x in i.split(":")) {
        // 按 "," 分割
        for (String y in x.split(",")) {
          if (y == "#") {
            continue;
          }
          irqList.add(int.parse(y));
        }
      }
    }
    // 将集合转换为列表并排序
    return irqList.toList()..sort();
  }

  ///   根据选择,获取IRQ
  ///   选择的选项（C, O, L等）
  ///   O:选择冲突的 IRQ，并将其与 targetIrqs 关联
  ///   L:选择 Legacy IRQ，并将其与空列表关联
  ///   C:选择 Legacy IRQ，并将其与 targetIrqs 关联
  ///   自定义输入格式：DEV1:IRQ1,IRQ2
  (Map<String, List<int>> irqPatches, List<String> currentLegacyIRQs)
  getIrqChoice(
    Map<String, Map<String, dynamic>>? irqs, {
    List<String> namesAndHids = const [
      "PIC",
      "IPIC",
      "TMR",
      "TIMR",
      "RTC",
      "RTC0",
      "RTC1",
      "PNPC0000",
      "PNP0100",
      "PNP0B00",
    ],
    String selectedOption = "",
  }) {
    // 检查是否有 IRQ 信息
    if (irqs == null || irqs.isEmpty) {
      Log.warning("没有发现任何 IRQ 信息!");
      return ({}, []);
    }

    if (selectedOption.isEmpty) {
      Log.warning("当前选项或者自定义IRQs为空!无法生成IRQ补丁!");
      return ({}, []);
    }

    final validOptions = {'C', 'O', 'L'};
    final upperCaseOption = selectedOption.toUpperCase();
    if (!validOptions.contains(upperCaseOption)) {
      Log("当前自定义IRQs: $upperCaseOption");
    }

    int hidPad = irqs.values
        .map((irqData) => irqData['hid']?.length ?? 0)
        .reduce((a, b) => a > b ? a : b);
    // 根据设备名称和 HID 确定默认设备
    List<String> defaults = irqs.keys.where((key) {
      var irqData = irqs[key];
      return namesAndHids.contains(key.toUpperCase()) ||
          namesAndHids.contains(irqData?['hid']?.toUpperCase());
    }).toList();
    List<String> currentLegacyIRQs = [];
    if (irqs.isEmpty) {
      Log.warning("=> 未找到任何 IRQ 信息!");
    }
    const String kHighlightSymbol = '*';
    const String kEmptySymbol = ' ';
    const int kXPadLength = 4;
    irqs.forEach((x, value) {
      final isHighlighted = x.toUpperCase().containsAny(namesAndHids);
      final prefixSymbol = isHighlighted ? kHighlightSymbol : kEmptySymbol;
      final paddedX = x.padLeft(kXPadLength);
      final hidPart = hidPad == 0
          ? ''
          : value['hid'] != null
          ? "- ${value['hid'].toString().padLeft(hidPad)}"
          : ''.padLeft(hidPad + 2);

      final irqContent = getAllIrqs(value['irq']);
      final irqLine = hidPad == 0
          ? '$prefixSymbol $paddedX: $irqContent'
          : '$prefixSymbol $paddedX $hidPart: $irqContent';

      currentLegacyIRQs.add(irqLine);
    });
    Map<String, List<int>> devices = {};

    // 根据选择的选项来更新设备和IRQ配置
    if (selectedOption.toLowerCase() == "o") {
      // 仅冲突的 IRQ
      for (var x in irqs.keys) {
        // 将目标 IRQ 关联到所有设备
        devices[x] = List.from(targetIrqs);
      }
    } else if (selectedOption.toLowerCase() == "l") {
      // Legacy 设备，清空 IRQ 配置
      for (var x in defaults) {
        // 仅 Legacy 设备，不关联任何 IRQ
        devices[x] = [];
      }
    } else if (selectedOption.toLowerCase() == "c") {
      // 仅 Legacy 设备并且冲突 IRQ
      for (var x in defaults) {
        // 将目标 IRQ 关联到 Legacy 设备
        devices[x] = List.from(targetIrqs);
      }
    } else {
      // 提供了自定义输入
      if (selectedOption.isNotEmpty) {
        var inputs = selectedOption.split(" ");
        for (var i in inputs) {
          if (i.isEmpty) continue;

          try {
            var parts = i.split(":");
            var name = parts[0].toUpperCase();
            var val = parts.length > 1
                ? parts[1]
                      .split(",")
                      .where((e) => e.trim().isNotEmpty)
                      .map((e) => int.parse(e.trim().replaceFirst('0x', '')))
                      .toList()
                : <int>[];
            devices[name] = val;
          } catch (e) {
            Log.error("自定义 IRQ 列表格式错误！！!设备之间用空格分隔，IRQ之间用逗号分隔！！！");
            Log("=> 示例：RTC:0 IPIC:2 TMR:8,11 \n");
            // 错误,返回空字典
            return ({}, []);
          }
        }
      }
    }

    return (devices, currentLegacyIRQs);
  }

  /// 列出所有中断
  Future<Map<String, Map<String, String>>> listIrqs() async {
    if (!await ensureDSDT()) return {};
    // 存储设备及其中断信息
    Map<String, Map<String, String>> devices = {};
    String? currentDevice;
    String? currentHid;
    bool irq = false;
    bool lastIrq = false;
    int irqIndex = 0;

    // 遍历 DSDT 中的行
    var lines = d.getDsdt()?['lines'] ?? '';
    for (int index = 0; index < lines.length; index++) {
      String line = lines[index];

      if (d.isHex(line)) {
        // 跳过所有十六进制行
        continue;
      }

      if (irq) {
        // 获取 IRQ 值
        String num = line.split("{")[1].split("}")[0].replaceAll(r" ", "");
        num = num.isEmpty ? "#" : num;

        if (devices.containsKey(currentDevice)) {
          if (lastIrq) {
            // 如果是连续的 IRQ
            devices[currentDevice]!["irq"] =
                "${devices[currentDevice]!["irq"]!}:$num";
          } else {
            // 如果跳过了至少一行
            irqIndex = d.findNextHex(index: index).$2;
            devices[currentDevice]!["irq"] =
                "${devices[currentDevice]!["irq"]!}-$irqIndex|$num";
          }
        } else {
          irqIndex = d.findNextHex(index: index).$2;
          if (currentDevice != null && currentDevice.isNotEmpty) {
            devices[currentDevice] = {"irq": "$irqIndex|$num"};
          }
        }

        irq = false;
        lastIrq = true;
      } else if (line.contains("Device (")) {
        // 如果保留 _HID
        if (currentDevice != null &&
            currentDevice.isNotEmpty &&
            devices.containsKey(currentDevice) &&
            currentHid != null &&
            currentHid.isNotEmpty) {
          // 保存 _HID
          devices[currentDevice]!["hid"] = currentHid;
        }
        lastIrq = false;
        currentHid = null;

        try {
          currentDevice = line.split("(")[1].split(")")[0];
        } catch (e) {
          currentDevice = null;
          continue;
        }
      } else if (line.contains("_HID, ") &&
          currentDevice != null &&
          currentDevice.isNotEmpty) {
        if (line.contains('"')) {
          try {
            currentHid = line.split('"')[1];
            // "Name (_HID, EisaId ("PNP0C02") /* PNP Motherboard Resources */)  // _HID: Hardware ID"
            // 可以获取到 _HID  =  PNP0C02
            // Log("=> 找到 _HID: $currentHid");
          } catch (e) {
            // "                    Method (_HID, 0, NotSerialized)  // _HID: Hardware ID"
            // 无法获取到 _HID ,忽略错误，继续解析下一行
            Log.error("=> _HID 解析错误: $e");
          }
        } else {
          // 没有双引号，无法获取 _HID，跳过
          currentHid = null;
        }
      } else if (line.contains("IRQNoFlags") &&
          currentDevice != null &&
          currentDevice.isNotEmpty) {
        // 下一行是中断信息
        irq = true;
      }
      // 检查是否是填充行
      else if (line
          .replaceAll(r"{", "")
          .replaceAll(r"}", "")
          .replaceAll(r"(", "")
          .replaceAll(r")", "")
          .replaceAll(r" ", "")
          .split("//")[0]
          .isNotEmpty) {
        // 重置 lastIrq，因为它不是连续的
        lastIrq = false;
      }
    }

    // 如果需要，保留最后的 _HID
    if (currentDevice != null &&
        currentDevice.isNotEmpty &&
        devices.containsKey(currentDevice) &&
        currentHid != null &&
        currentHid.isNotEmpty) {
      devices[currentDevice]!["hid"] = currentHid;
    }

    return devices;
  }

  /// 生成 HPET 补丁
  /// [devs] 设备列表
  /// [targetIrqs] 目标 IRQ 列表
  Future<void> ssdtHPET({
    Map<String, Map<String, dynamic>>? devs,
    Map<String, List<int>>? targetIrqs,
  }) async {
    if (!await ensureDSDT()) return;
    // 校验 devs
    if (devs == null || devs.isEmpty) {
      Log.warning("未找到有效的设备,跳过 HPET 操作!");
      return;
    }
    // 校验 targetIrqs
    if (targetIrqs == null ||
        targetIrqs.isEmpty ||
        targetIrqs.values.every((list) => list.isEmpty)) {
      Log.warning("未提供有效的 IRQs 或者 IRQs 为空! 已终止操作!");
      return;
    }
    Log("正在定位 PNP0103 (HPET) 设备…");
    var hpets = d.getDevicePathsWithHid(hid: "PNP0103");
    bool hpetFake = hpets.isEmpty;
    List<Map<String, dynamic>> patches = [];
    bool hpetSTA = false;
    String? name;
    Map? sta;
    // 定义 CRS 和 XCRS 值
    String crs = "5F435253";
    String xcrs = "58435253";
    String padl = '', padr = '';
    String? memAccess, memBase, memLength;
    bool gotMem = false;
    List hpet = [];
    if (hpets.isNotEmpty) {
      name = hpets[0][0];
      Log("=> 定位于 $name");
      // 定位 _STA 方法
      sta = getStaVar(devHid: "PNP0103", devName: "HPET");
      if (sta['patches'] != null && sta['patches'].isNotEmpty) {
        hpetSTA = true;
        patches.addAll(sta['patches']);
      }
      // 定位 HPET 的 _CRS 方法/名称
      Log("正在定位 HPET 的 _CRS 方法/名称…");
      hpet = d.getMethodPaths(obj: "$name._CRS");
      if (hpet.isEmpty) {
        hpet = d.getNamePaths(obj: "$name._CRS");
      }
      if (hpet.isEmpty) {
        // 检查 XCRS 方法/名称是否已应用重命名
        var xcrsPaths = d.getMethodPaths(obj: "$name.XCRS");
        if (xcrsPaths.isEmpty) {
          xcrsPaths = d.getNamePaths(obj: "$name.XCRS");
        }
        if (xcrsPaths.isEmpty) {
          Log.warning("=> 无法定位 $name._CRS！已终止操作！");
        } else {
          Log.warning("=> 无法定位 $name._CRS！");
          Log.warning("=> _CRS似乎已经被命名为 XCRS！");
          Log.warning("=> 请禁用DSDT中该设备的 _CRS 到 XCRS 的重命名，重启后再试!\n");
        }
        return;
      }

      Log("=> 定位于 $name._CRS");
      var crsIndex = d.findNextHex(index: hpet[0][1]).$2;
      Log("=> 在索引: $crsIndex 处找到");
      Log("=> 类型: ${hpet[0].last}");
      // 在 HPET 的 _CRS 方法中查找 Memory32Fixed 部分
      Log("=> 正在检查 Memory32Fixed…");

      bool primed = false;

      // 迭代 HPET 作用域中的每一行
      for (var line in d.getScope(
        startingIndex: hpets[0][1],
        stripComments: true,
      )) {
        if (line.contains("Memory32Fixed (")) {
          try {
            // 从行中提取内存访问类型
            memAccess = line.split("(")[1].split(",")[0];
          } catch (e) {
            Log.warning("=> 无法确定内存访问类型！");
            break;
          }
          primed = true;
          continue;
        }
        if (!primed) {
          continue;
        } else if (line.contains(")")) {
          // 已到达作用域结束
          break;
        }
        // 已准备好并未到达作用域结束 - 尝试获取 Base 和 Length
        String val = "";
        try {
          val = line
              .trim()
              .split(",")[0]
              .replaceAll(r"Zero", "0x0")
              .replaceAll(r"One", "0x1");
        } catch (e) {
          // 无法将 Base 或 Length 转换为整数 - 可能使用了变量，回退到默认值
          Log.warning("=> 无法将 Base 或 Length 转换为整数！");
          break;
        }

        // 给 memBase 赋值
        if (memBase == null) {
          memBase = val;
        } else {
          memLength = val;
          // 已获取到 Base 和 Length，跳出循环
          break;
        }
      }
      // 检查是否获取到了所需的值
      gotMem =
          memAccess != null &&
          memAccess.isNotEmpty &&
          memBase != null &&
          memBase.isNotEmpty &&
          memLength != null &&
          memLength.isNotEmpty;
      if (gotMem) {
        Log("=> 获取到 $memAccess $memBase => $memLength");
      } else {
        memAccess = "ReadWrite";
        memBase = "0xFED00000";
        memLength = "0x00000400";
        Log.warning("=> 未找到！");
        Log.warning("=> 使用默认值 $memBase => $memLength");
      }

      /// 查找最短的唯一填充
      final pads = d.getShortestUniquePad(currentHex: crs, index: crsIndex);
      padl = pads.$1;
      padr = pads.$2;

      patches.add({
        "Comment":
            "${name?.split(".").last.replaceFirst(RegExp(r'\\'), "")} _CRS to XCRS rename",
        "Find": padl + crs + padr,
        "Replace": padl + xcrs + padr,
      });
    } else {
      Log.warning("=> 未找到！");
      name = getLpcName(skipEc: true, skipCommonNames: true);
      if (name == null) {
        return;
      }
    }

    Log("");
    Log("正在创建 IRQ 补丁…");
    if (sta != null &&
        sta.isNotEmpty &&
        sta['patches'] != null &&
        sta['patches'].isNotEmpty) {
      Log(
        "=> ${name?.split('.').last.replaceAll('\\', '')} _STA to XSTA rename:",
      );
      Log("           Find: ${patches[0]['Find']}");
      Log("     Replace: ${patches[0]['Replace']}");
      Log("");
    }
    if (!hpetFake) {
      Log(
        "=> ${name?.split('.').last.replaceAll('\\', '')} _CRS to XCRS rename:",
      );
      Log("           Find: $padl$crs$padr");
      Log("     Replace: $padl$xcrs$padr");
      Log("");
    }
    Log("正在检查 IRQ…");
    // 校验 targetIrqs
    if (targetIrqs.isEmpty) {
      Log("IRQ 为空!跳过…\n");
    }
    if (devs.isEmpty) {
      Log.warning("=> 没有需要修补的内容！");
      Log("");
    }

    var savedDSDT = d.getDsdt()?["raw"];
    var uniquePatches = {};
    var genericPatches = [];

    for (var dev in devs.keys) {
      if (!targetIrqs.containsKey(dev)) {
        continue;
      }

      var irqPatches = getHexFromIrqs(devs[dev]!['irq'] ?? '', targetIrqs[dev]);
      var i = irqPatches.where((x) => x['changed'] == true).toList();

      for (var t in i) {
        if (!t['changed']) {
          // 未进行任何修补 - 跳过
          continue;
        }

        // 尝试已知的结尾值：7900、4701 和 8609 —— 同时允许最多 8 个字符的填充
        String pattern = r"(" + t["find"] + r"(.{0,8})(7900|4701|8609))";
        var regExp = RegExp(pattern);
        var index = t['index'];
        var result = d.getHexStartingAt(index);
        var hex = result.$1;
        var matches = regExp.allMatches(hex).toList();
        // 如果有匹配，提取所有捕获组
        if (matches.isNotEmpty) {
          // List<String> result = [
          //   matches.first.group(1) ?? "",
          //   matches.first.group(2) ?? "",
          //   matches.first.group(3) ?? "",
          // ];
          // Log("  $result"); // 输出结果数组
        } else {
          Log("未找到匹配项。");
        }
        if (matches.isEmpty) {
          Log.warning("缺少 $dev 的 IRQ 补丁结尾（${t['find']}）！已跳过…");
          continue;
        }

        if (matches.length > 1) {
          // 找到多个匹配项！将它们全部添加为 find/replace 条目
          for (var match in matches) {
            genericPatches.add({
              'remd': ((t['remd'] as List).toSet().toList()..sort()).join(','),
              'orig': t['find'],
              'find': t['find'] + match.group(2)! + match.group(3)!,
              'repl': t['repl'] + match.group(2)! + match.group(3)!,
            });
          }
          continue;
        }

        // 如果只有一个匹配项
        var ending = matches.first.group(2)! + matches.first.group(3)!;
        final (padl, padr) = d.getShortestUniquePad(
          currentHex: t['find'] + ending,
          index: t['index'],
        );
        var tPatch = padl + t['find'] + ending + padr;
        var rPatch = padl + t['repl'] + ending + padr;

        if (!uniquePatches.containsKey(dev)) {
          uniquePatches[dev] = [];
        }

        uniquePatches[dev]!.add({
          'dev': dev,
          'remd': ((t['remd'] as List).toSet().toList()..sort()).join(','),
          'orig': t['find'],
          'find': tPatch,
          'repl': rPatch,
        });
      }
    }

    // 检查唯一的 IRQ 修补项
    if (uniquePatches.isNotEmpty) {
      uniquePatches.forEach((x, patchesList) {
        for (int i = 0; i < patchesList.length; i++) {
          var p = patchesList[i];
          String patchName = "$x IRQ ${p['remd']} Patch";

          if (patchesList.length > 1) {
            patchName += " - ${i + 1} of ${patchesList.length}";
          }

          patches.add({
            "Comment": patchName,
            "Find": p["find"],
            "Replace": p["repl"],
          });

          Log("=> $patchName");
          Log("            Find: ${p["find"]}");
          Log("      Replace: ${p["repl"]}");
          Log("");
        }
      });
    }

    if (genericPatches.isNotEmpty) {
      List<Map<String, dynamic>> genericSet = [];
      // 确保不会重复 find 值
      for (var x in genericPatches) {
        bool exists = genericSet.any((patch) => util.deepEquals(patch, x));
        if (!exists) {
          genericSet.add(x);
        }
      }

      Log.warning("以下可能不是唯一的，默认已禁用！\n");

      for (int i = 0; i < genericSet.length; i++) {
        var x = genericSet[i];
        String patchName =
            "Generic IRQ Patch ${i + 1} of ${genericSet.length} - ${x['remd']} - ${x['orig']}";

        patches.add({
          "Comment": patchName,
          "Find": x["find"],
          "Replace": x["repl"],
          "Disabled": true,
          "Enabled": false,
        });

        Log("=> $patchName");
        Log("         Find: ${x["find"]}");
        Log("   Replace: ${x["repl"]}");
        Log("");
      }
    }
    d.getDsdt()?["raw"] = savedDSDT;
    final String ssdtName = "SSDT-HPET";
    Log("正在创建预编译 $ssdtName.dsl...");
    var ssdt = '';
    if (hpetFake) {
      Log("正在创建一个仿冒 HPET 设备…");
      ssdt =
          """
DefinitionBlock ("", "SSDT", 2, "RAPID", "HPET", 0x00000000)
{
    External ([[name]], DeviceObj)

    Scope ([[name]])
    {
        Device (HPET)
        {
            Name (_HID, EisaId ("PNP0103") 
            Name (_CID, EisaId ("PNP0C01") 
            Method (_STA, 0, NotSerialized)  
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
            Name (_CRS, ResourceTemplate ()  
            {
                IRQNoFlags ()
                    {0,8}
                Memory32Fixed (ReadWrite, // Access Type
                    0xFED00000,           // Address Base
                    0x00000400,           // Address Length
                    )
            })
        }
    }
}"""
              .replaceAll(r"[[name]]", name ?? '');
    } else {
      // 初始化 SSDT 配置的基本部分
      ssdt = """//
// Supplementary HPET _CRS from Goldfish64
// requires at least the HPET's _CRS to XCRS rename
DefinitionBlock ("", "SSDT", 2, "RAPID", "HPET", 0x00000000)
{
    External ([[name]], DeviceObj)
    External ([[name]].XCRS, [[type]])

    Scope ([[name]])
    {
        Name (BUFX, ResourceTemplate ()
        {
            IRQNoFlags ()
                {0,8}
            // [[mem]]
            Memory32Fixed ([[mem_access]],
                [[mem_base]],           
                [[mem_length]],          
            )
        })
        Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
        {
            If (LOr (_OSI ("Darwin"), LNot(CondRefOf ([[name]].XCRS))))
            {
                Return (BUFX)
            }
            // Not macOS and XCRS exists - return its result
            Return ([[name]].XCRS[[method]])
        }""";
      // 替换 [[name]] 为传入的 `name`
      ssdt = ssdt.replaceAll(r"[[name]]", name ?? '');

      // 根据 hpet[0].last 的值选择 "MethodObj" 或 "BuffObj"
      ssdt = ssdt.replaceAll(
        r"[[type]]",
        hpet[0].last == "Method" ? "MethodObj" : "BuffObj",
      );

      // 根据 `gotMem` 来选择内存配置信息
      ssdt = ssdt.replaceAll(
        r"[[mem]]",
        gotMem
            ? "AccessType/Base/Length pulled from DSDT"
            : "Default AccessType/Base/Length - verify with your DSDT!",
      );

      // 替换内存配置信息
      ssdt = ssdt.replaceAll(r"[[mem_access]]", memAccess ?? '');
      ssdt = ssdt.replaceAll(r"[[mem_base]]", memBase ?? '');
      ssdt = ssdt.replaceAll(r"[[mem_length]]", memLength ?? '');

      // 根据 hpet[0].last 的值选择是否使用 "()"
      ssdt = ssdt.replaceAll(
        r"[[method]]",
        hpet[0].last == "Method" ? " ()" : "",
      );

      // 根据 hpetSta 和相关条件修改配置
      if (hpetSTA) {
        List<String> ssdtParts = [];
        bool external = false;

        // 逐行处理 ssdt 配置，插入外部引用 XSTA 方法
        ssdt.split("\n").forEach((line) {
          if (line.trim().contains("External (")) {
            external = true;
          } else if (external) {
            ssdtParts.add("    External ([[name]].XSTA, ${sta?['sta_type']})");
            external = false;
          }
          ssdtParts.add(line);
        });

        // 追加 XSTA 方法
        ssdt = ssdtParts.join("\n");
        ssdt += "\n";
        ssdt += """
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            // Return 0x0F if booting macOS or the XSTA method
            // no longer exists for some reason
            If (LOr (_OSI ("Darwin"), LNot (CondRefOf ([[name]].XSTA))))
            {
                Return (0x0F)
            }
            // Not macOS and XSTA exists - return its result
            Return ([[name]].XSTA[[called]])
        }""";
        ssdt = ssdt.replaceAll(r"[[name]]", name ?? '');
        ssdt = ssdt.replaceAll(
          r"[[called]]",
          sta?['sta_type'] == "MethodObj" ? " ()" : "",
        );
      }

      // 关闭最终的括号
      ssdt += "\n";
      ssdt += """
    }
}""";
    }
    //写入到SSDT文件
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": hpetFake
          ? "HPET Device Fake"
          : "${name?.split('.').last.replaceAll('\\', '')} _CRS - requires _CRS to XCRS rename",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, patches: patches);
  }

  Future<void> ssdtPNLF({
    bool prebuilt = false,
    int? uid = 99,
    bool? getIgpu = false,
    String? manualIGPUPath,
  }) async => prebuilt
      ? await _ssdtPNLFPrebuilt()
      : await _ssdtPNLF(
          uid: uid,
          getIgpu: getIgpu,
          manualIGPUPath: manualIGPUPath,
        );

  bool _isExactPnlfDevicePath(List<dynamic> pathInfo) {
    if (pathInfo.length < 3 || pathInfo[2] != "Device") return false;

    final lastSegment = pathInfo[0]
        .toString()
        .split(".")
        .last
        .replaceAll(RegExp(r"_+$"), "")
        .toUpperCase();
    return lastSegment == "PNLF";
  }

  List<_NativePnlfDevice> _findNativePnlfDevices() {
    final matches = <_NativePnlfDevice>[];
    final sortedTableNames = sortedNicely(d.acpiTables.keys.toList());

    for (final tableName in sortedTableNames) {
      final rawTable = d.acpiTables[tableName];
      if (rawTable is! Map<String, dynamic>) continue;

      final paths = d.getPathOfType(
        objType: "Device",
        obj: "PNLF",
        table: rawTable,
      );
      for (final pathInfo in paths) {
        if (!_isExactPnlfDevicePath(pathInfo)) continue;
        matches.add((tableName: tableName, table: rawTable, path: pathInfo));
      }
    }

    return matches;
  }

  String _normalizePnlfPath(String value) {
    final parts = value
        .replaceAll('\\', '')
        .split('.')
        .where((part) => part.isNotEmpty)
        .map((part) => part.replaceAll(RegExp(r'_+$'), ''))
        .toList();
    if (parts.isEmpty) return '';
    return '\\${parts.join('.')}';
  }

  String _normalizeManualPnlfPath(String value) {
    final parts = value
        .replaceAll('\\', '')
        .split('.')
        .where((part) => part.isNotEmpty)
        .toList();
    final segment = RegExp(r'^[A-Za-z_][A-Za-z0-9_]{0,3}$');
    if (parts.isEmpty || parts.any((part) => !segment.hasMatch(part))) {
      return '';
    }
    return _normalizePnlfPath(
      parts.map((part) => part.toUpperCase()).join('.'),
    );
  }

  String _pnlfLookupPath(String value) => value
      .replaceAll('\\', '')
      .split('.')
      .where((part) => part.isNotEmpty)
      .map((part) => part.replaceAll(RegExp(r'_+$'), '').toUpperCase())
      .join('.');

  List<String> _pnlfPciRootPaths() {
    final roots = <String>[];
    final seen = <String>{};
    for (final tableName in sortedNicely(
      d.acpiTables.keys.toList(),
      first: 'DSDT.aml',
    )) {
      final table = d.acpiTables[tableName] as Map<String, dynamic>?;
      if (table == null) continue;
      for (final hid in const ['PNP0A08', 'PNP0A03']) {
        for (final entry in d.getDevicePathsWithHid(hid: hid, table: table)) {
          final root = _normalizePnlfPath(entry[0].toString());
          if (root.isNotEmpty && seen.add(_pnlfLookupPath(root))) {
            roots.add(root);
          }
        }
      }
    }
    return roots;
  }

  bool _pnlfDevicePathExists(String value) {
    final expected = _pnlfLookupPath(value);
    for (final rawTable in d.acpiTables.values) {
      if (rawTable is! Map<String, dynamic>) continue;
      for (final entry in d.getDevicePaths(obj: value, table: rawTable)) {
        if (_pnlfLookupPath(entry[0].toString()) == expected) return true;
      }
    }
    return false;
  }

  bool _pnlfExternalDevicePathExists(String value) {
    final expected = _pnlfLookupPath(value);
    final external = RegExp(
      r'^\s*External\s*\(\s*([^,]+)\s*,\s*DeviceObj\s*\)',
      caseSensitive: false,
    );
    for (final rawTable in d.acpiTables.values) {
      if (rawTable is! Map<String, dynamic>) continue;
      for (final line in List<String>.from(rawTable['lines'] ?? const [])) {
        final match = external.firstMatch(line);
        if (match != null &&
            _pnlfLookupPath(match.group(1) ?? '') == expected) {
          return true;
        }
      }
    }
    return false;
  }

  int? _pnlfAddressValue(List<dynamic> entry, Map<String, dynamic> table) {
    final parsed = getAddressFromLine(entry[1] as int, table: table);
    if (parsed != null) return parsed;
    final lines = List<String>.from(table['lines'] ?? const []);
    final index = entry[1] as int;
    if (index < 0 || index >= lines.length) return null;
    final match = RegExp(
      r'\b_ADR\s*,\s*(Zero|One|0[xX][0-9A-Fa-f]+|[0-9]+)',
      caseSensitive: false,
    ).firstMatch(lines[index]);
    final literal = match?.group(1);
    if (literal == null) return null;
    if (literal.toLowerCase() == 'zero') return 0;
    if (literal.toLowerCase() == 'one') return 1;
    return literal.toLowerCase().startsWith('0x')
        ? int.tryParse(literal.substring(2), radix: 16)
        : int.tryParse(literal);
  }

  String _findPnlfIgpuByAddress() {
    final roots = _pnlfPciRootPaths();
    if (roots.isEmpty) return '';
    final rootLookups = roots.map(_pnlfLookupPath).toSet();
    for (final tableName in sortedNicely(
      d.acpiTables.keys.toList(),
      first: 'DSDT.aml',
    )) {
      final table = d.acpiTables[tableName] as Map<String, dynamic>?;
      if (table == null) continue;
      for (final entry in d.getPathOfType(
        objType: 'Name',
        obj: '_ADR',
        table: table,
      )) {
        if (_pnlfAddressValue(entry, table) != 0x00020000) continue;
        var devicePath = entry[0].toString();
        if (devicePath.toUpperCase().endsWith('._ADR')) {
          devicePath = devicePath.substring(0, devicePath.length - 5);
        }
        devicePath = _normalizePnlfPath(devicePath);
        final lookup = _pnlfLookupPath(devicePath);
        final dot = lookup.lastIndexOf('.');
        final parent = dot < 0 ? '' : lookup.substring(0, dot);
        if (rootLookups.contains(parent) && _pnlfDevicePathExists(devicePath)) {
          return devicePath;
        }
      }
    }
    return '';
  }

  String _findPnlfIgpuByCommonName() {
    final roots = _pnlfPciRootPaths();
    for (final name in const [
      'IGPU',
      'GFX0',
      '_VID',
      'VID0',
      'VID1',
      'VGA',
      '_VGA',
    ]) {
      for (final root in roots) {
        final candidate = _normalizePnlfPath('$root.$name');
        if (_pnlfDevicePathExists(candidate) ||
            _pnlfExternalDevicePathExists(candidate)) {
          return candidate;
        }
      }
    }
    return '';
  }

  String _indentAslBlock(String source, int spaces) {
    final lines = source.split('\n').toList();
    while (lines.isNotEmpty && lines.first.trim().isEmpty) {
      lines.removeAt(0);
    }
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }
    var commonIndent = 1 << 30;
    for (final line in lines.where((line) => line.trim().isNotEmpty)) {
      final leading = line.length - line.trimLeft().length;
      if (leading < commonIndent) commonIndent = leading;
    }
    if (commonIndent == 1 << 30) commonIndent = 0;
    final prefix = ' ' * spaces;
    return lines
        .map(
          (line) => line.trim().isEmpty
              ? ''
              : '$prefix${line.substring(commonIndent.clamp(0, line.length))}',
        )
        .join('\n');
  }

  String _buildPnlfRegisterBlock() => r'''
        Field (^RMP3, AnyAcc, NoLock, Preserve)
        {
            Offset (0x02), GDID, 16,
            Offset (0x10), BAR1, 32,
        }

        OperationRegion (RMB1, SystemMemory, BAR1 & ~0x0F, 0x0E1184)
        Field (RMB1, AnyAcc, Lock, Preserve)
        {
            Offset (0x48250),
            LEV2, 32,
            LEVL, 32,
            Offset (0x70040),
            P0BL, 32,
            Offset (0x0C2000),
            GRAN, 32,
            Offset (0x0C8250),
            LEVW, 32,
            LEVX, 32,
            LEVD, 32,
            Offset (0x0E1180),
            PCHL, 32,
        }

        Method (_INI, 0, Serialized)
        {
            If (_OSI ("Darwin"))
            {
                Local0 = GDID
                Local2 = Ones
                Local3 = 0

                If (LOr (LEqual (1, Local3), LNotEqual (Match (Package()
                {
                    0x010b, 0x0102,
                    0x0106, 0x1106, 0x1601, 0x0116, 0x0126,
                    0x0112, 0x0122,
                    0x0152, 0x0156, 0x0162, 0x0166,
                    0x016a,
                    0x0046, 0x0042,
                }, MEQ, Local0, MTR, 0, 0), Ones)))
                {
                    If (LEqual (Local2, Ones))
                    {
                        Store (0x710, Local2)
                    }
                    Store (LEVX >> 16, Local1)
                    If (LNot (Local1))
                    {
                        Store (Local2, Local1)
                    }
                    If (LNotEqual (Local2, Local1))
                    {
                        Store ((LEVL * Local2) / Local1, Local0)
                        Store (Local2 << 16, Local3)
                        If (LGreater (Local2, Local1))
                        {
                            Store (Local3, LEVX)
                            Store (Local0, LEVL)
                        }
                        Else
                        {
                            Store (Local0, LEVL)
                            Store (Local3, LEVX)
                        }
                    }
                }
            }
        }''';

  String _buildCustomPnlfDevice(
    int uid, {
    required bool includeRegisters,
    required bool hasIgpuPath,
  }) {
    var device =
        '''Device (PNLF)
{
    Name (_HID, EisaId ("APP0002"))
    Name (_CID, "backlight")
    Name (_UID, ${util.hexy(uid)})

    Method (_STA, 0, NotSerialized)
    {
        If (_OSI ("Darwin"))
        {
            Return (0x0B)
        }
        Else
        {
            Return (Zero)
        }
    }''';
    if (includeRegisters && hasIgpuPath) {
      device += '\n\n${_indentAslBlock(_buildPnlfRegisterBlock(), 4)}';
    }
    return '$device\n}';
  }

  /// 背光修复
  /// [uid] UID
  /// [getIgpu] UID=14时,是否包含GPU寄存器代码
  /// [manualIGPUPath] 手动指定 iGPU 路径
  Future<void> _ssdtPNLF({
    int? uid = 99,
    bool? getIgpu = false,
    String? manualIGPUPath,
  }) async {
    if (!await ensureDSDT()) return;
    if (uid == null) {
      Log.warning("未提供有效的 UID，终止操作！");
      return;
    }

    final uidList = PNLFUIDs.map((item) => item['UID']).toList();
    if (!uidList.contains(uid)) {
      Log.warning("$uid 是一个自定义的 UID，可能需要手动定制设置，或者可能根本不受支持!");
    }

    final String ssdtName = "SSDT-PNLF";
    Log("正在创建预编译 $ssdtName.dsl...");
    for (var item in PNLFUIDs) {
      if (item['UID'] == uid) {
        Log("=> 使用的UID: ${item['UID']}");
        Log("=> 适用平台: ${item['Platform']}");
        break;
      }
    }

    var igpu = _findPnlfIgpuByAddress();
    var guessed = false;
    var manual = false;
    var detectionLevel = igpu.isEmpty ? 3 : 1;
    if (uid == 14) {
      Log.warning("UID 14 平台建议提供正确的 iGPU 路径，并在需要时补充 iGPU 寄存器信息。");
    }
    if (igpu.isEmpty) {
      igpu = _findPnlfIgpuByCommonName();
      guessed = igpu.isNotEmpty;
      detectionLevel = guessed ? 2 : 3;
    }
    final providedPath = manualIGPUPath?.trim() ?? '';
    if (providedPath.isNotEmpty) {
      final normalized = _normalizeManualPnlfPath(providedPath);
      if (normalized.isEmpty) {
        Log.warning("无效的 iGPU 路径：$providedPath");
      } else {
        igpu = normalized;
        manual = true;
        guessed = false;
        detectionLevel = 0;
      }
    }
    if (manual) {
      Log("=> 使用手动指定的 iGPU 路径: $igpu");
    } else if (detectionLevel == 1) {
      Log("=> Level 1: 在 PCI Root 直属子设备中通过 _ADR = 0x00020000 定位 iGPU: $igpu");
    } else if (detectionLevel == 2) {
      Log("=> Level 2: 在 PCI 命名空间中通过设备名称推断 iGPU: $igpu");
    } else {
      Log.warning("=> Level 3: 无法可靠定位 iGPU，将生成根级 PNLF 设备。");
    }
    final includeRegisters = getIgpu ?? false;
    if (includeRegisters && igpu.isEmpty) {
      Log.warning("未定位到 iGPU，无法补充 PCI 配置及背光寄存器信息。");
    }

    List<Map<String, dynamic>> patches = [];

    final tableNameList = d.acpiTables.keys.toList();
    final sortedTableNames = sortedNicely(tableNameList);

    Log("正在检查 ACPI 表中是否存在原生 PNLF 设备…");
    final nativePnlfDevices = _findNativePnlfDevices();
    if (nativePnlfDevices.isNotEmpty) {
      final nativePnlf = nativePnlfDevices.first;
      Log("=> 已在 ${nativePnlf.tableName} 找到原生 PNLF 设备: ${nativePnlf.path[0]}");
      Log("=> 需要将原生 PNLF 重命名为 XNLF, 正在生成重命名补丁…");
      patches.add({
        "Comment": "PNLF to XNLF rename - requires $ssdtName.aml",
        "Find": "504E4C46",
        "Replace": "584E4C46",
        "Table": nativePnlf.table,
      });
    } else {
      Log("=> 未找到原生 PNLF 设备!");
      Log("=> 无需生成 PNLF to XNLF 重命名补丁!");
    }

    // NBCF 二进制模式
    final nbcfOld = util.getHexBytes("084E4243460A00");
    final nbcfNew = util.getHexBytes("084E42434600");
    // 初始化标志
    bool hasNbcfOld = false;
    bool hasNbcfNew = false;
    // 遍历所有 ACPI 表
    for (final tableName in sortedTableNames) {
      final table = d.acpiTables[tableName]!;

      // 检查 NBCF (旧版本)
      if (!hasNbcfOld &&
          table["raw"] != null &&
          table["raw"].isNotEmpty &&
          util.containsSublist(table["raw"], nbcfOld)) {
        Log("在 $tableName 中检测到 Name (NBCF, 0x00), 正在生成补丁…");
        hasNbcfOld = true;
        patches.add({
          "Comment": "NBCF 0x00 to 0x01 for BrightnessKeys.kext",
          "Enabled": true,
          "Disabled": false,
          "Count": 1,
          "Find": "084E4243460A00",
          "Replace": "084E4243460A01",
          "Table": table,
        });
      }

      // 检查 NBCF (新版本)
      if (!hasNbcfNew &&
          table["raw"] != null &&
          table["raw"].isNotEmpty &&
          util.containsSublist(table["raw"], nbcfNew)) {
        Log("在 $tableName 中检测到 Name (NBCF, Zero), 正在生成补丁…");
        hasNbcfNew = true;
        patches.add({
          "Comment": "NBCF Zero to One for BrightnessKeys.kext",
          "Enabled": true,
          "Disabled": false,
          "Count": 1,
          "Find": "084E42434600",
          "Replace": "084E42434601",
          "Table": table,
        });
      }

      // 如果两种模式都已检测到，则提前退出
      if (hasNbcfOld && hasNbcfNew) {
        break;
      }
    }

    String ssdt = """//
// Much of the info pulled from OpenCorePkg SSDT-PNLF samples.
//
DefinitionBlock ("", "SSDT", 2, "RAPID", "PNLF", 0x00000000)
{
""";
    if (igpu.isNotEmpty) {
      ssdt += "    External ($igpu, DeviceObj)\n";
    }
    final device = _buildCustomPnlfDevice(
      uid,
      includeRegisters: includeRegisters,
      hasIgpuPath: igpu.isNotEmpty,
    );
    if (igpu.isNotEmpty) {
      ssdt += "\n    Scope ($igpu)\n    {\n";
      if (includeRegisters) {
        ssdt += "        OperationRegion (RMP3, PCI_Config, Zero, 0x14)\n\n";
      }
      ssdt += '${_indentAslBlock(device, 8)}\n    }\n';
    } else {
      ssdt += '\n${_indentAslBlock(device, 4)}\n';
    }
    ssdt += '}\n';

    await writeSSDT(ssdtName, ssdt);
    Map<String, dynamic> acpi = {
      "Comment":
          "Defines PNLF device with a _UID of $uid for backlight control${patches.any((p) => p["Comment"].contains("XNLF")) ? " - requires PNLF to XNLF rename" : ""}",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };

    // 生成 plist 文件
    makePlist(acpi: acpi, patches: patches, replace: true);
    if (igpu.isNotEmpty) {
      if (guessed) {
        Log.warning("注意: iGPU 路径被猜测为 $igpu\n    使用前请验证!");
      }
      if (manual) {
        Log.warning("注意: iGPU 路径已手动设置为 $igpu  请在使用前务必确认该路径是否正确!");
      }
    }

    if (hasNbcfOld || hasNbcfNew) {
      Log.warning(
        "注意：已生成 NBCF 补丁（依赖 BrightnessKeys.kext），默认启用。如果亮度快捷键无法正常工作，请禁用该补丁。",
      );
    }
  }

  Future<void> ssdtEC({
    bool prebuilt = false,
    bool isLaptop = false,
    bool injectUSBPower = false,
  }) async => prebuilt
      ? await _ssdtECPrebuilt(
          isLaptop: isLaptop,
          injectUSBPower: injectUSBPower,
        )
      : await _ssdtEC(isLaptop: isLaptop, injectUSBPower: injectUSBPower);

  /// 仿冒EC控制器
  /// [isLaptop] 是否为笔记本
  /// [injectUSBPower]
  Future<void> _ssdtEC({
    bool isLaptop = false,
    bool injectUSBPower = false,
  }) async {
    if (!await ensureDSDT()) return;
    Log("正在定位 PNP0C09（EC）设备…");
    bool rename = false;
    bool namedEc = false;
    List<String> ecToPatch = [];
    List<String> ecToEnable = [];
    Map<String, dynamic> ecSta = {};
    Map<String, dynamic> ecEnableSta = {};
    List<Map<String, dynamic>> patches = [];
    String? lpcName;
    String ssdtName = injectUSBPower
        ? 'SSDT-EC-USBX-DESKTOP'
        : 'SSDT-EC-DESKTOP';
    bool ecLocated = false;
    for (var tableName in sortedNicely(d.acpiTables.keys.toList())) {
      var table = d.acpiTables[tableName];
      var ecList = d.getDevicePathsWithHid(hid: "PNP0C09", table: table);

      if (ecList.isNotEmpty) {
        lpcName = ecList.first[0]
            .split(".")
            .sublist(0, ecList.first[0].split(".").length - 1)
            .join(".");
        Log("=> 在 $tableName 找到 ${ecList.length} 个 PNP0C09（EC）设备");
        Log("=> 校验中...");

        for (var deviceInfo in ecList) {
          String device = deviceInfo[0];
          String origDevice = device;
          Log("=> 找到 $device");

          if (device.split(".").last == "EC") {
            namedEc = true;
            if (!isLaptop) {
              // 仅在非笔记本上重命名
              Log(" => PNP0C09（EC）设备命名为 EC，正在重命名");
              device =
                  "${device.split(".").sublist(0, device.split(".").length - 1).join(".")}.EC0";
              rename = true;
            }
          }

          var scope = d
              .getScope(
                startingIndex: deviceInfo[1],
                stripComments: true,
                table: table,
              )
              .join("\n");

          if (["_HID", "_CRS", "_GPE"].every((key) => scope.contains(key))) {
            Log("=> 有效的 PNP0C09（EC）设备");
            ecLocated = true;

            var sta = getStaVar(
              device: origDevice,
              devHid: "PNP0C09",
              devName: origDevice.split(".").last,
              table: table,
            );

            if (!isLaptop) {
              ecToPatch.add(device);
              if (sta["patches"] != null && sta["patches"].isNotEmpty) {
                patches.addAll(sta["patches"]);
                ecSta[device] = sta;
              }
            } else if (sta["patches"] != null && sta["patches"].isNotEmpty) {
              if (staNeedsPatching(sta, table)) {
                ecToEnable.add(device);
                ecEnableSta[device] = sta;
                for (var patch in sta["patches"]) {
                  patch["Enabled"] = false;
                  patch["Disabled"] = true;
                  patches.add(patch);
                }
              } else {
                Log("=> _STA 已正确启用, 跳过重命名");
              }
            }
          } else {
            Log("=> 无效的 PNP0C09（EC）设备");
          }
        }
      }
    }

    if (!ecLocated) {
      Log("=> 未找到有效的 PNP0C09（EC）设备, 只需仿冒一个EC设备即可");
    }

    if (isLaptop && namedEc && patches.isEmpty) {
      Log.warning("=> 已找到命名的 EC 设备, 无需仿冒!\n");
      return;
    }

    lpcName ??= getLpcName(skipEc: true, skipCommonNames: true);

    if (lpcName == null) {
      return;
    }

    String comment = "Faked Embedded Controller";
    if (isLaptop) {
      comment += ' For Laptop';
      ssdtName = injectUSBPower ? 'SSDT-EC-USBX-LAPTOP' : 'SSDT-EC-LAPTOP';
    }
    if (rename) {
      patches.insert(0, {
        "Comment":
            "EC to EC0${ecSta.isEmpty ? "" : " - must come before any EC _STA to XSTA renames!"}",
        "Find": "45435f5f",
        "Replace": "4543305f",
      });
      comment +=
          " - requires EC to EC0 ${ecSta.isEmpty ? "rename" : "and EC _STA to XSTA renames"}";
    } else if (ecSta.isNotEmpty) {
      comment += " - requires EC _STA to XSTA renames";
    }

    Log("正在创建 $ssdtName.dsl…");

    var ssdt = """
DefinitionBlock ("", "SSDT", 2, "RAPID", "SsdtEC", 0x00001000)
{
    External ([[LPCName]], DeviceObj)
""";
    ssdt = ssdt.replaceAll(r"[[LPCName]]", lpcName);

    for (var x in ecToPatch) {
      ssdt += "    External ($x, DeviceObj)\n";
      if (ecSta.containsKey(x)) {
        ssdt +=
            "    External ($x.XSTA, ${ecSta[x]?["sta_type"] ?? "MethodObj"})\n";
      }
    }

    // 遍历 ecToEnable
    for (var x in ecToEnable) {
      ssdt += "    External ($x, DeviceObj)\n";
      if (ecEnableSta.containsKey(x)) {
        // 添加 _STA 和 XSTA 引用，因为补丁可能未启用
        ssdt +=
            "    External ($x._STA, ${ecEnableSta[x]?["sta_type"] ?? "MethodObj"})\n";
        ssdt +=
            "    External ($x.XSTA, ${ecEnableSta[x]?["sta_type"] ?? "MethodObj"})\n";
      }
    }

    // 遍历 ecToPatch 并添加 _STA 方法
    for (var x in ecToPatch) {
      ssdt +=
          """
    Scope ($x)
    {
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If (_OSI ("Darwin"))
            {
                Return (Zero)
            }
            Else
            {
                Return (${ecSta.containsKey(x) ? "$x.XSTA${ecSta[x]?["sta_type"] == "MethodObj" ? " ()" : ""}" : "0x0F"})
            }
        }
    }
""";
    }

    // 遍历 ecToEnable 再次强制启用
    for (var x in ecToEnable) {
      ssdt +=
          """
    If (LAnd (CondRefOf ($x.XSTA), LNot (CondRefOf ($x._STA))))
    {
        Scope ($x)
        {
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (${ecEnableSta.containsKey(x) ? "$x.XSTA${ecEnableSta[x]?["sta_type"] == "MethodObj" ? " ()" : ""}" : "Zero"})
                }
            }
        }
    }
""";
    }

    // 创建虚拟 EC
    if (!isLaptop || !namedEc) {
      ssdt +=
          """
    Scope ($lpcName)
    {
        Device (EC)
        {
            Name (_HID, "ACID0001")  // _HID: Hardware ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
""";
    }

    if (injectUSBPower) {
      comment += ' with USB power property support';
      ssdt += """
    Scope (\\_SB)
    {
        Device (USBX)
        {
            Name (_ADR, Zero)  // _ADR: Address
            Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
                If (!Arg2)
                {
                    Return (Buffer (One)
                    {
                         0x03                                             // .
                    })
                }

                Return (Package (0x08)
                {
                    "kUSBSleepPowerSupply", 
                    0x13EC, 
                    "kUSBSleepPortCurrentLimit", 
                    0x0834, 
                    "kUSBWakePowerSupply", 
                    0x13EC, 
                    "kUSBWakePortCurrentLimit", 
                    0x0834
                })
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
""";
    }
    ssdt += """
}""";
    // 写入 SSDT 文件
    final acpi = {"Comment": comment, "Enabled": true, "Path": "$ssdtName.aml"};
    makePlist(acpi: acpi, patches: patches, replace: true);
    writeSSDT(ssdtName, ssdt);
  }

  Future<void> ssdtUSBX({
    bool prebuilt = false,
    Map<String, String>? usbxProps,
  }) async => prebuilt ? null : await _ssdtUSBX(usbxProps: usbxProps);

  /// SSDT-USBX
  /// [usbxProps] USBX 属性
  Future<void> _ssdtUSBX({Map<String, String>? usbxProps}) async {
    if (!await ensureDSDT()) return;
    if (usbxProps == null || usbxProps.isEmpty) {
      Log.warning("USBX属性补丁不能为空! 已终止操作!");
      return;
    }

    final String ssdtName = "SSDT-USBX";
    Log("正在创建预编译 $ssdtName.dsl...");
    final acpi = {
      "Comment": "Generic USBX device for USB power properties",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi);
    // 生成 SSDT 内容
    String ssdt = '''
// Generic USBX Device with power properties injected
DefinitionBlock ("", "SSDT", 2, "RAPID", "SsdtUsbx", 0x00001000)
{
    Scope (\\_SB)
    {
        Device (USBX)
        {
            Name (_ADR, Zero)  // _ADR: Address
            Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
                If (LNot (Arg2))
                {
                    Return (Buffer ()
                    {
                        0x03
                    })
                }
                Return (Package ()
                {''';

    // 添加 USBX 属性
    usbxProps.forEach((key, value) {
      ssdt +=
          '''
                    "$key",
                    $value,''';
    });

    // 移除最后的多余逗号
    ssdt = ssdt.trimRight().replaceAll(RegExp(r',$'), '');

    ssdt += '''
                })
            }
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
}''';

    // 写入 SSDT 文件
    writeSSDT(ssdtName, ssdt);
  }

  Future<void> ssdtPLUG({
    bool prebuilt = false,
    bool alderlakeOrLater = false,
  }) async => prebuilt
      ? ((alderlakeOrLater
            ? await _ssdtPLUGALTPrebuilt()
            : await _ssdtPLUGPrebuilt()))
      : await _ssdtPLUG(alderlakeOrLater: alderlakeOrLater);

  /// SSDT-PLUG
  Future<void> _ssdtPLUG({bool alderlakeOrLater = false}) async {
    if (!await ensureDSDT()) return;
    Log("正在确定 CPU 命名方案…");
    for (var tableName in sortedNicely(d.acpiTables.keys.toList())) {
      var ssdtName = "SSDT-PLUG";
      var table = d.acpiTables[tableName];

      if (!(table["signature"]?.toLowerCase() == "dsdt" ||
          table["signature"]?.toLowerCase() == "ssdt")) {
        /// 不检查数据表格,继续
        continue;
      }

      Log("正在检查 $tableName…");

      dynamic cpuName;
      try {
        cpuName = d.getProcessorPaths(table: table)[0][0];
      } catch (e) {
        cpuName = null;
      }

      if (cpuName != null && cpuName.isNotEmpty) {
        Log("=> 已找到 Processor 处理器：$cpuName");

        Log("正在创建 $ssdtName.dsl...");

        var ssdt =
            """
//
// Based on the sample found at https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/AcpiSamples/SSDT-PLUG.dsl
//
DefinitionBlock ("", "SSDT", 2, "RAPID", "CpuPlug", 0x00003000)
{
    External ([[CPUName]], ProcessorObj)
    Scope ([[CPUName]])
    {
            Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
            If (_OSI ("Darwin")) {
                If (LNot (Arg2))
                      {
                          Return (Buffer (One)
                          {
                              0x03
                          })
                      }
                      Return (Package (0x02)
                      {
                          "plugin-type", 
                          One
                      })
            }
            Else
            {
                Return (Buffer (One)
                {
                    Zero
                })
            }
        }
    }
}"""
                .replaceAll(r"[[CPUName]]", cpuName);

        final acpi = {
          "Comment":
              "Redefines modern CPU Devices as legacy Processor objects and sets plugin-type to 1 on the first",
          "Enabled": true,
          "Path": "$ssdtName.aml",
        };

        makePlist(acpi: acpi);
        writeSSDT(ssdtName, ssdt);
        return;
      } else {
        // 如果没有找到处理器对象，继续检查 ACPI0007 设备
        ssdtName += "-ALT";
        Log("=> 未找到任何 Processor 对象…");

        var procs = d.getDevicePathsWithHid(hid: "ACPI0007", table: table);
        if (procs.isEmpty) {
          Log("=> 未找到 ACPI0007 设备…");
          continue;
        }

        Log("=> 已找到 ${procs.length} 个 ACPI0007 设备");

        var parent = procs[0][0].split(".")[0];
        Log("=> 在 $parent 找到父设备，正在处理…");

        var procList = <Map<String, String>>[];
        for (var proc in procs) {
          Log("=> 正在检查 ${proc[0].split('.').last}…");

          var uid = d.getPathOfType(
            objType: "Name",
            obj: "${proc[0]}._UID",
            table: table,
          );
          if (uid.isEmpty) {
            Log("=> 未找到！跳过…");
            continue;
          }

          try {
            var uid0 = table["lines"][uid[0][1]]
                .split("_UID, ")[1]
                .split(")")[0];
            Log("=> UID: $uid0");
            procList.add({"proc": proc[0], "uid": uid0});
          } catch (e) {
            Log("=> 未找到！跳过…");
          }
        }

        if (procList.isEmpty) {
          continue;
        }

        Log("正在处理 ${procList.length} 个有效的处理器设备…");

        var ssdt =
            """
//
// Based on the sample found at https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/AcpiSamples/Source/SSDT-PLUG-ALT.dsl
//
DefinitionBlock ("", "SSDT", 2, "RAPID", "CpuPlugA", 0x00003000)
{
    External ([[parent]], DeviceObj)

    Scope ([[parent]])
    {"""
                .replaceAll(r"[[parent]]", parent);

        // 遍历处理器对象并将其添加到 SSDT 中
        for (var i = 0; i < procList.length; i++) {
          var procUid = procList[i];
          var proc = procUid["proc"];
          var uid = procUid["uid"];
          var adr = (i).toRadixString(16).toUpperCase();
          var name = "CP00".substring(0, 4 - adr.length) + adr;

          ssdt +=
              """
        Processor ([[name]], [[uid]], 0x00000510, 0x06)
        {
            // [[proc]]
            Name (_HID, "ACPI0007" /* Processor Device */)  // _HID: Hardware ID
            Name (_UID, [[uid]])
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }"""
                  .replaceAll(r"[[name]]", name)
                  .replaceAll(r"[[uid]]", uid ?? '')
                  .replaceAll(r"[[proc]]", proc ?? '');

          if (i == 0) {
            ssdt += """
            Method (_DSM, 4, NotSerialized)
            {
                If (LNot (Arg2)) {
                    Return (Buffer (One) { 0x03 })
                }

                Return (Package (0x02)
                {
                    "plugin-type",
                    One
                })
            }""";
          }

          ssdt += """
        }""";
        }

        ssdt += """
    }
}""";

        final acpi = {
          "Comment":
              "Redefines modern CPU Devices as legacy Processor objects and sets plugin-type to 1 on the first",
          "Enabled": true,
          "Path": "$ssdtName.aml",
        };

        makePlist(acpi: acpi);
        writeSSDT(ssdtName, ssdt);
        return;
      }
    }

    Log.warning("未找到有效的处理器设备！");
  }

  Future<void> ssdtPMC({bool prebuilt = false}) async =>
      prebuilt ? await _ssdtPMCPrebuilt() : await _ssdtPMC();

  /// 生成 SSDT-PMC
  Future<void> _ssdtPMC() async {
    if (!await ensureDSDT()) return;

    /// 获取 LPC 设备名称
    String? lpcName = getLpcName();
    if (lpcName == null) {
      Log("获取LPC Name失败...");
      return;
    }
    final String ssdtName = "SSDT-PMC";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = """
//
// SSDT-PMC source from Acidanthera
// Original found here: https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/AcpiSamples/SSDT-PMC.dsl
//
// Uses the CORP name to denote where this was created for troubleshooting purposes.
//
DefinitionBlock ("", "SSDT", 2, "RAPID", "PMCR", 0x00001000)
{
    External ([[LPCName]], DeviceObj)
    Scope ([[LPCName]])
    {
        Device (PMCR)
        {
            Name (_HID, EisaId ("APP9876"))  // _HID: Hardware ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0xFE000000,         // Address Base
                    0x00010000,         // Address Length
                    )
            })
        }
    }
}
""";

    ssdt = ssdt.replaceAll(r"[[LPCName]]", lpcName);

    final acpi = {
      "Comment": "PMCR for native 300-series NVRAM",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi);
    await writeSSDT(ssdtName, ssdt);
  }

  Future<void> ssdtRTC0RANGE({bool prebuilt = false}) async =>
      prebuilt ? await _ssdtRTC0RANGEPrebuilt() : await _ssdtRTC0RANGE();

  Future<void> ssdtAWAC({bool prebuilt = false}) async =>
      prebuilt ? await _ssdtAWACPrebuilt() : await _ssdtAWAC();

  Future<void> _ssdtRTC0RANGE() async {
    if (!await ensureDSDT()) return;
    bool rtcRangeNeeded = false;
    String? rtcCrsType;
    List<String> crsLines = [];
    String? lpcName;

    var rtcDict = getStaVar(varS: "STAS", devHid: "PNP0B00", devName: "RTC");

    /// 确定是否需要仿冒 RTC
    if (!(rtcDict["valid"] as bool)) {
      Log("=> 需要仿冒 RTC!");
      lpcName = getLpcName();
      if (lpcName == null) return;
    } else {
      /// 检查 RTC 是否有 _CRS 并验证其范围
      Log("=> 正在检查 _CRS…");
      var rtcCrs = d.getMethodPaths(obj: rtcDict["device"][0] + "._CRS");
      if (rtcCrs.isEmpty) {
        rtcCrs = d.getNamePaths(obj: rtcDict["device"][0] + "._CRS");
      }
      if (rtcCrs.isNotEmpty) {
        Log("=>  ${rtcCrs[0][0]}");
        rtcCrsType = rtcCrs[0].last == "Method" ? "MethodObj" : "BuffObj";

        if (rtcCrsType.toLowerCase() == "buffobj") {
          Log("=> _CRS 是一个缓冲区, 正在检查 RTC 范围…");
          int? lastAdr, lastLen, lastInd;
          var crsScope = d.getScope(startingIndex: rtcCrs[0][1]);
          // 清理 crsScope 范围 - 去除混乱部分
          var padLen = crsScope[0].length - crsScope[0].trimLeft().length;
          var pad = crsScope[0].substring(0, padLen);
          List<String> fixedScope = [];

          // 修正范围
          for (var line in crsScope) {
            if (line.startsWith(pad)) {
              // 完整行，去掉 pad 并保存
              fixedScope.add(line.substring(padLen));
            } else {
              // 可能是上一行的一部分
              fixedScope[fixedScope.length - 1] += line;
            }
          }

          for (var i = 0; i < fixedScope.length; i++) {
            var line = fixedScope[i];
            if (line.contains("Name (_CRS, ")) {
              // 重命名 _CRS 为 BUFX，并去掉注释避免混淆
              line = line
                  .replaceAll("Name (_CRS, ", "Name (BUFX, ")
                  .split("  //")[0];
            }

            if (line.contains("IO (Decode16,")) {
              // 获取起始行、下一行和第 4 行的值
              try {
                var currAdr = int.parse(
                  fixedScope[i + 1].trim().split(",")[0].replaceFirst('0x', ''),
                  radix: 16,
                );
                var currLen = int.parse(
                  fixedScope[i + 4].trim().split(",")[0].replaceFirst('0x', ''),
                  radix: 16,
                );
                var currInd = i + 4;

                if (lastAdr != null) {
                  // 比较范围值
                  var adjust = currAdr - (lastAdr + lastLen!);
                  if (adjust != 0) {
                    rtcRangeNeeded = true;
                    Log(
                      "=> 正在调整 IO 范围 ${util.hexy(lastAdr, padTo: 4)} 长度为 ${util.hexy(lastLen + adjust, padTo: 2)}",
                    );

                    try {
                      var hexFind = util.hexy(lastLen, padTo: 2);
                      var hexRepl = util.hexy(lastLen + adjust, padTo: 2);
                      if (lastInd != null) {
                        crsLines[lastInd] = crsLines[lastInd].replaceAll(
                          hexFind,
                          hexRepl,
                        );
                      }
                    } catch (e) {
                      Log("=> 无法调整值, 无法验证 RTC 范围.");
                      rtcRangeNeeded = false;
                      break;
                    }
                  }
                }

                // 保存最后的值
                lastAdr = currAdr;
                lastLen = currLen;
                lastInd = currInd;
              } catch (e) {
                // 处理值错误
                Log("=> 收集值失败, 无法验证 RTC 范围.");
                rtcRangeNeeded = false;
                break;
              }
            }

            crsLines.add(line);
          }
        } else {
          Log("=> _CRS 是一个方法, 无法验证 RTC 范围!");
        }
        if (rtcRangeNeeded) {
          // 需要生成一个将 _CRS 重命名为 XCRS 的补丁
          Log("=> 正在生成 _CRS 到 XCRS 的重命名…");

          // 获取 _CRS 的索引
          var crsIndex = d.findNextHex(index: rtcCrs[0][1]).$2;
          Log("=> 在索引 $crsIndex 处找到");

          // 定义十六进制字符串
          var crsHex = "5F435253"; // _CRS
          var xcrsHex = "58435253"; // XCRS

          // 获取唯一填充值
          final (padl, padr) = d.getShortestUniquePad(
            currentHex: crsHex,
            index: crsIndex,
          );
          // 添加补丁
          final patches = rtcDict["patches"] ?? [];
          patches.add({
            "Comment": "${rtcDict["dev_name"]} _CRS to XCRS rename",
            "Find": "$padl$crsHex$padr",
            "Replace": "$padl$xcrsHex$padr",
          });

          rtcDict["patches"] = patches;
          rtcDict["crs"] = true;
        }
      } else {
        Log("=>  未找到");
      }
    }

    /// 验证是否需要 SSDT
    if ((rtcDict["valid"] as bool) &&
        !(rtcDict["has_var"] as bool) &&
        rtcDict["sta"].isEmpty &&
        !rtcRangeNeeded) {
      Log.warning("=> 已找到有效的 PNP0B00 (RTC) 设备并通过验证,无需补丁及SSDT!已终止操作！");
      return;
    }

    String comment = rtcDict["valid"] == false
        ? "RTC Fake"
        : rtcRangeNeeded
        ? "Fixing RTC Range"
        : "Fixing RTC Enable";

    List<String> suffix = [];
    for (var x in [rtcDict]) {
      if (!(x["valid"] as bool)) continue;
      String val = "";
      if (x["sta"] != null && x["sta"].isNotEmpty && !(x["has_var"] as bool)) {
        val = "${x["dev_name"]} _STA to XSTA";
      }
      if (x["crs"] == true) {
        val += "${val.isNotEmpty ? ' and ' : x["dev_name"]} _CRS to XCRS";
      }
      if (val.isNotEmpty) {
        suffix.add(val);
      }
    }
    if (suffix.isNotEmpty) {
      comment += " - requires ${suffix.join(', ')} rename";
    }

    final String ssdtName = "SSDT-RTC0-RANGE";
    final acpi = {"Comment": comment, "Enabled": true, "Path": "$ssdtName.aml"};
    final patches = rtcDict["patches"] ?? [];
    makePlist(acpi: acpi, patches: patches, replace: true);
    Log("正在创建 $ssdtName.dsl...");

    String ssdt = """

    DefinitionBlock ("", "SSDT", 2, "RAPID", "RTC0RANGE", 0x00000000)
    {
    """;
    if ([rtcDict].any((x) => x["has_var"] == true)) {
      ssdt += """    External (STAS, IntObj)
          Scope (\\)
          {
              Method (_INI, 0, NotSerialized)  // _INI: Initialize
              {
                  If (_OSI ("Darwin"))
                  {
                      Store (One, STAS)
                  }
              }
          }
      """;
    }
    for (var x in [rtcDict]) {
      if (x["valid"] != true || x["has_var"] == true || x["device"] == null) {
        continue;
      }

      // 设备已找到，并且没有 STAS 变量 - 检查是否有 _STA（可能被重命名）
      var macos = x["dev_hid"] == "ACPI000E" ? "Zero" : "0x0F";
      var original = x["dev_hid"] == "ACPI000E" ? "0x0F" : "Zero";
      if (x["sta"] != null && x["sta"].isNotEmpty) {
        ssdt += """    External ([[DevPath]], DeviceObj)
        External ([[DevPath]].XSTA, [[sta_type]])
        Scope ([[DevPath]])
        {
            Name (ZSTA, [[Original]])
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return ([[macOS]])
                }
                // Default to [[Original]] - but return the result of the renamed XSTA if possible
                If (CondRefOf ([[DevPath]].XSTA))
                {
                    Store ([[DevPath]].XSTA[[called]], ZSTA)
                }
                Return (ZSTA)
            }
        }
    """;
        ssdt = ssdt
            .replaceAll(r"[[DevPath]]", x["device"][0])
            .replaceAll(r"[[Original]]", original)
            .replaceAll(r"[[macOS]]", macos)
            .replaceAll(r"[[sta_type]]", x["sta_type"])
            .replaceAll(
              r"[[called]]",
              x["sta_type"] == "MethodObj" ? " ()" : "",
            );
      } else if (x["dev_hid"] == "ACPI000E") {
        // AWAC 设备既没有 STAS 变量，也没有 _STA 方法，此时添加一个
        ssdt += """    External ([[DevPath]], DeviceObj)
              Scope ([[DevPath]])
              {
                  Method (_STA, 0, NotSerialized)  // _STA: Status
                  {
                      If (_OSI ("Darwin"))
                      {
                          Return (Zero)
                      }
                      Else
                      {
                          Return (0x0F)
                      }
                  }
              }
          """;
        ssdt = ssdt.replaceAll(r"[[DevPath]]", x["device"][0]);
      }
    }
    // 检查是否需要修正 RTC 范围
    if (rtcRangeNeeded &&
        rtcCrsType?.toLowerCase() == "buffobj" &&
        crsLines.isNotEmpty &&
        rtcDict["valid"] == true) {
      ssdt += """    External ([[DevPath]], DeviceObj)
              External ([[DevPath]].XCRS, [[type]])
              Scope ([[DevPath]])
              {
                  // Adjusted and renamed _CRS buffer ripped from DSDT with corrected range
          [[NewCRS]]
                  // End of adjusted _CRS and renamed buffer

                  // Create a new _CRS method that returns the result of the renamed XCRS
                  Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                  {
                      If (LOr (_OSI ("Darwin"), LNot (CondRefOf ([[DevPath]].XCRS))))
                      {
                          // Return our buffer if booting macOS or the XCRS method
                          // no longer exists for some reason
                          Return (BUFX)
                      }
                      // Not macOS and XCRS exists - return its result
                      Return ([[DevPath]].XCRS[[method]])
                  }
              }
          """;
      ssdt = ssdt
          .replaceAll("[[DevPath]]", rtcDict["device"][0])
          .replaceAll("[[type]]", rtcCrsType ?? '')
          .replaceAll("[[method]]", rtcCrsType == "Method" ? " ()" : "")
          .replaceAll(
            "[[NewCRS]]",
            crsLines.map((x) => "        $x").join("\n"),
          );
    }
    // 检查是否存在 RTC 设备
    if (!rtcDict.containsKey("valid") &&
        lpcName != null &&
        lpcName.isNotEmpty) {
      ssdt += """    External ([[LPCName]], DeviceObj)    // (from opcode)
          Scope ([[LPCName]])
          {
              Device (RTC0)
              {
                  Name (_HID, EisaId ("PNP0B00"))  // _HID: Hardware ID
                  Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                  {
                      IO (Decode16,
                          0x0070,             // Range Minimum
                          0x0070,             // Range Maximum
                          0x01,               // Alignment
                          0x08,               // Length
                          )
                      IRQNoFlags ()
                          {8}
                  })
                  Method (_STA, 0, NotSerialized)  // _STA: Status
                  {
                      If (_OSI ("Darwin"))
                      {
                          Return (0x0F)
                      }
                      Else
                      {
                          Return (Zero)
                      }
                  }
              }
          }
      """;
      ssdt = ssdt.replaceAll(r"[[LPCName]]", lpcName);
    }
    ssdt += "}";

    writeSSDT(ssdtName, ssdt);
  }

  Future<void> _ssdtAWAC() async {
    if (!await ensureDSDT()) return;
    var awacDict = getStaVar(varS: "STAS", devHid: "ACPI000E", devName: "AWAC");

    /// 验证是否需要 SSDT
    if (!(awacDict["valid"] as bool)) {
      Log.warning("=> 未找到 ACPI000E (AWAC) 设备,无需补丁及SSDT!已终止操作!");
      return;
    }

    String comment = "Fixing Incompatible AWAC";

    List<String> suffix = [];
    for (var x in [awacDict]) {
      if (!(x["valid"] as bool)) continue;
      String val = "";
      if (x["sta"] != null && x["sta"].isNotEmpty && !(x["has_var"] as bool)) {
        val = "${x["dev_name"]} _STA to XSTA";
      }
      if (x["crs"] == true) {
        val += "${val.isNotEmpty ? ' and ' : x["dev_name"]} _CRS to XCRS";
      }
      if (val.isNotEmpty) {
        suffix.add(val);
      }
    }
    if (suffix.isNotEmpty) {
      comment += " - requires ${suffix.join(', ')} rename";
    }
    final String ssdtName = "SSDT-AWAC";
    final acpi = {"Comment": comment, "Enabled": true, "Path": "$ssdtName.aml"};
    final patches = awacDict["patches"] ?? [];
    makePlist(acpi: acpi, patches: patches, replace: true);
    Log("正在创建 $ssdtName.dsl...");

    String ssdt = """
    DefinitionBlock ("", "SSDT", 2, "RAPID", "AWAC", 0x00000000)
    {
    """;
    if ([awacDict].any((x) => x["has_var"] == true)) {
      ssdt += """    External (STAS, IntObj)
          Scope (_SB)
          {
              Method (_INI, 0, NotSerialized)  // _INI: Initialize
              {
                  If (_OSI ("Darwin"))
                  {
                      Store (One, STAS)
                  }
              }
          }
        }
      """;
    }
    for (var x in [awacDict]) {
      if (x["valid"] != true || x["has_var"] == true || x["device"] == null) {
        continue;
      }

      // 设备已找到，并且没有 STAS 变量 - 检查是否有 _STA（可能被重命名）
      var macos = x["dev_hid"] == "ACPI000E" ? "Zero" : "0x0F";
      var original = x["dev_hid"] == "ACPI000E" ? "0x0F" : "Zero";
      if (x["sta"] != null && x["sta"].isNotEmpty) {
        ssdt += """    External ([[DevPath]], DeviceObj)
        External ([[DevPath]].XSTA, [[sta_type]])
        Scope ([[DevPath]])
        {
            Name (ZSTA, [[Original]])
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return ([[macOS]])
                }
                // Default to [[Original]] - but return the result of the renamed XSTA if possible
                If (CondRefOf ([[DevPath]].XSTA))
                {
                    Store ([[DevPath]].XSTA[[called]], ZSTA)
                }
                Return (ZSTA)
            }
        }
    """;
        ssdt = ssdt
            .replaceAll(r"[[DevPath]]", x["device"][0])
            .replaceAll(r"[[Original]]", original)
            .replaceAll(r"[[macOS]]", macos)
            .replaceAll(r"[[sta_type]]", x["sta_type"])
            .replaceAll(
              r"[[called]]",
              x["sta_type"] == "MethodObj" ? " ()" : "",
            );
      } else if (x["dev_hid"] == "ACPI000E") {
        // AWAC 设备既没有 STAS 变量，也没有 _STA 方法，此时添加一个
        ssdt += """    External ([[DevPath]], DeviceObj)
              Scope ([[DevPath]])
              {
                  Method (_STA, 0, NotSerialized)  // _STA: Status
                  {
                      If (_OSI ("Darwin"))
                      {
                          Return (Zero)
                      }
                      Else
                      {
                          Return (0x0F)
                      }
                  }
              }
          """;
        ssdt = ssdt.replaceAll(r"[[DevPath]]", x["device"][0]);
      }
    }

    writeSSDT(ssdtName, ssdt);
  }

  Future<void> ssdtRHUB({bool prebuilt = false}) async =>
      prebuilt ? await _ssdtRHUBPrebuilt() : await _ssdtRHUB();

  /// SSDT-RHUB
  Future<void> _ssdtRHUB() async {
    if (!await ensureDSDT()) return;
    Log('正在收集 RHUB/HUBN/URTH 设备...');
    var rHubs = d.getDevicePaths(obj: 'RHUB');
    var hHubs = d.getDevicePaths(obj: 'HUBN');
    var uHubs = d.getDevicePaths(obj: 'URTH');
    var hubs = rHubs + hHubs + uHubs;
    if (hubs.isEmpty) {
      Log.warning('=> 未找到任何设备！已终止操作！');
      return;
    }
    Log('=> 找到 ${hubs.length} 个设备');
    List<Map<String, dynamic>> patches = [];
    var tasks = [];
    List<String> usedNames = [];
    int xhcNum = 2;
    int ehcNum = 1;
    for (var x in hubs) {
      var task = <String, dynamic>{"device": x[0]};
      Log(
        "=>  ${x[0].split('.').sublist(0, x[0].split('.').length - 1).join('.')}",
      );

      var name = x[0].split('.').length >= 2
          ? x[0].split('.')[(x[0].split('.').length - 2)]
          : "";

      if (illegalNames.contains(name) || usedNames.contains(name)) {
        Log("=>  需要重命名!");
        task["device"] = task["device"]
            .split('.')
            .sublist(0, task["device"].split('.').length - 1)
            .join('.');
        task["parent"] = task["device"]
            .split('.')
            .sublist(0, task["device"].split('.').length - 1)
            .join('.');

        if (name.startsWith("EHC")) {
          final result = getUniqueDevice(
            task["parent"],
            "EH01",
            startingNumber: ehcNum,
            usedNames: usedNames,
          );
          task["rename"] = result.name;
          ehcNum = result.number;
          ehcNum += 1;
        } else {
          final result = getUniqueDevice(
            task["parent"],
            "XHCI",
            startingNumber: xhcNum,
            usedNames: usedNames,
          );
          task["rename"] = result.name;
          xhcNum = result.number;
          xhcNum += 1;
        }

        usedNames.add(task["rename"]);
      } else {
        usedNames.add(name);
      }

      final staMethod = d.getMethodPaths(obj: "${task["device"]}._STA");
      Log("=>  检查 ${task["device"].split('.').last}: 是否存在 _STA 方法");
      if (staMethod.isNotEmpty) {
        final staIndex = d.findNextHex(index: staMethod[0][1]).$2;
        Log("=>  在索引 $staIndex 找到 _STA 方法!");
        Log("=>  生成 _STA 到 XSTA 的补丁");

        const staHex = "5F535441";
        const xstaHex = "58535441";

        final (padl, padr) = d.getShortestUniquePad(
          currentHex: staHex,
          index: staIndex,
        );

        Log("");
        Log("           Find: ${padl + staHex + padr}");
        Log("     Replace: ${padl + xstaHex + padr}");
        Log("");

        patches.add({
          "Comment": "${task["device"].split('.').last} _STA to XSTA rename",
          "Find": padl + staHex + padr,
          "Replace": padl + xstaHex + padr,
        });
      } else {
        Log("=>  未找到 _STA 方法!");
      }

      final scopeAdr = d.getNamePaths(obj: "${task["device"]}._ADR");
      if (scopeAdr.isNotEmpty) {
        final line = d.getDsdt()?["lines"][scopeAdr[0][1]];
        task["address"] = line.trim();
      } else {
        task["address"] = "Name (_ADR, Zero)  // _ADR: Address";
      }

      tasks.add(task);
    }
    Log("");
    final ssdtName = "SSDT-RHUB";
    Log("正在创建 $ssdtName.dsl...");
    final acpi = {
      "Comment": "Disable USB RHUB/HUBN/URTH and rename devices",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, patches: patches);

    String ssdt = '''
//
// SSDT to disable RHUB/HUBN/URTH devices and rename PXSX, XHC1, EHC1, and EHC2 devices
//
DefinitionBlock ("", "SSDT", 2, "RAPID", "UsbRHUB", 0x00001000)
{
''';

    // 收集唯一的 parent 路径并排序
    final parents =
        tasks
            .where((t) => t.containsKey('parent'))
            .map((t) => t['parent']!)
            .toSet()
            .toList()
          ..sort();

    for (var p in parents) {
      ssdt += '    External ($p, DeviceObj)\n';
    }

    for (var t in tasks) {
      ssdt += '    External (${t["device"]}, DeviceObj)\n';
    }

    for (var t in tasks) {
      if (t.containsKey('rename')) {
        final device = t['device']!;
        final parent = t['parent']!;
        final newDevice = t['rename']!;
        final address = t['address'] ?? 'Name (_ADR, Zero)  // _ADR: Address';

        ssdt +=
            '''
    Scope ($device)
    {
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If (_OSI ("Darwin"))
            {
                Return (Zero)
            }
            Else
            {
                Return (0x0F)
            }
        }
    }

    Scope ($parent)
    {
        Device ($newDevice)
        {
            $address
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
''';
      } else {
        final device = t['device']!;
        ssdt +=
            '''
    Scope ($device)
    {
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If (_OSI ("Darwin"))
            {
                Return (Zero)
            }
            Else
            {
                Return (0x0F)
            }
        }
    }
''';
      }
    }

    ssdt += '\n}';

    writeSSDT(ssdtName, ssdt);
  }

  /// 打印未匹配的路径
  /// [unmatched] 未匹配的路径列表
  /// [pciRootPaths] PciRoot() 路径列表
  void debugPrintUnmatched({
    List<String>? unmatched,
    List<dynamic>? pciRootPaths,
  }) {
    Log("");
    if (unmatched != null && unmatched.isNotEmpty) {
      Log.warning("未找到以下路径的匹配项：");
      for (var path in unmatched..sort()) {
        Log("=> $path");
      }
    } else {
      Log.warning("未找到任何匹配项！");
    }

    if (pciRootPaths != null && pciRootPaths.isNotEmpty) {
      Log.warning("注意,设备路径必须以以下 PciRoot() 开头，才能与当前 ACPI 表匹配：");
      for (var item
          in pciRootPaths
            ..sort((a, b) => (a['path'] ?? a).compareTo(b['path'] ?? b))) {
        Log("=> ${item['path'] ?? item}");
      }
    }
  }

  /// 打印设备路径中存在 _ADR 地址溢出的情况
  /// [addrOverflow] 存在地址溢出的设备路径列表
  void debugPrintAddressOverflow(List<String> addrOverflow) {
    Log("");
    Log("=> 设备路径中存在 _ADR 地址溢出！");
    Log("=> 以下设备可能需要调整桥接才能正常工作：");
    for (var d in (addrOverflow.toSet().toList()..sort())) {
      Log("=> $d");
    }
  }

  /// 打印无法解析的桥接
  /// [failedBridges] 无法解析的桥接列表
  void debugPrintFailedBridges(List<String> failedBridges) {
    debugPrint("\n以下桥接无法解析：");
    for (var fb in failedBridges..sort()) {
      Log("=> $fb");
    }
  }

  /// SSDT 桥接设备
  /// [pciBridges] PCI 桥接设备列表
  Future<void> ssdtPCIBridge({List<String>? pciBridges}) async {
    if (!await ensureDSDT()) return;
    Log("正在收集 PCI 桥接设备…");
    if (pciBridges == null || pciBridges.isEmpty) {
      Log("PCI 桥接设备为空！已经终止操作！");
      return;
    }
    Log("正在构建桥接设备…");
    var pathDict = getDevicePath(inputPaths: pciBridges);
    if (pathDict.isEmpty) {
      Log("PCI 桥接设备为空！跳过…");
      return;
    }
    final (deviceDict, pciRootPaths) = getDevicePaths();
    final matches = <(String, (String, Map<String, dynamic>, bool, int))>[];
    List<String> unmatched = [];
    Log("正在匹配设备路径…");
    for (final p in pathDict.keys.toList()..sort()) {
      Log("=> $p");
      final match = getLongestMatch(deviceDict, p);
      if (match == null) {
        Log("未找到匹配项!");
        unmatched.add(p);
      } else {
        if (match.$3) {
          Log("=> 匹配到 ${match.$1}, 无需桥接");
        } else {
          final b = '/'.allMatches(p.substring(match.$4 + 1)).length + 1;
          Log(
            "=> 匹配到 ${match.$1}, 需要 ${b.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} 个桥接设备",
          );
        }
        matches.add((p, match));
      }
    }

    if (matches.isEmpty) {
      debugPrintUnmatched(unmatched: unmatched, pciRootPaths: pciRootPaths);
      Log("未找到匹配项!\n");
      return;
    }

    final addrOverflow = <String>[];
    for (final (_, match) in matches) {
      if (match.$2["adr_overflow"] == true) {
        final overFlow = getAllMatches(deviceDict, match.$2["path"]);
        for (final d in overFlow) {
          if (d.$2["dev_overflow"] != null && d.$2["dev_overflow"].isNotEmpty) {
            addrOverflow.addAll(List<String>.from(d.$2["dev_overflow"]));
          }
        }
      }
    }

    final allNoBridge = matches.every((m) => m.$2.$3);
    if (allNoBridge) {
      if (unmatched.isNotEmpty) {
        debugPrintUnmatched(unmatched: unmatched, pciRootPaths: pciRootPaths);
      }
      if (addrOverflow.isNotEmpty) {
        debugPrintAddressOverflow(addrOverflow);
      }
      Log("无需桥接!\n");
      return;
    }

    Log("正在解析桥接设备…");
    final bridgeMatch = <String, String>{};
    final bridgeList = <String>[];
    final failedBridges = <String>[];
    final externalRefs = <String>[];

    for (final (testPath, match) in matches) {
      /// 无需桥接
      if (match.$3) continue;
      final remain = testPath.substring(match.$4 + 1);
      Log("=> $remain");
      final bridges = getBridgeDevices(remain);
      if (bridges.isEmpty) {
        Log("=> 无法解析!");
        failedBridges.add(testPath);
      } else {
        var path = match.$1;
        for (var i = 0; i < bridges.length; i++) {
          path += " ${bridges[i]}";
          if (!bridgeList.contains(path)) {
            bridgeList.add(path);
          }
          if (i == bridges.length - 1) {
            bridgeMatch[path] = testPath;
          }
        }
        if (!externalRefs.contains(match.$1)) {
          externalRefs.add(match.$1);
        }
      }
    }

    if (bridgeList.isEmpty) {
      if (failedBridges.isNotEmpty) {
        debugPrintFailedBridges(failedBridges);
      }
      if (unmatched.isNotEmpty) {
        debugPrintUnmatched(unmatched: unmatched, pciRootPaths: pciRootPaths);
      }
      if (addrOverflow.isNotEmpty) {
        debugPrintAddressOverflow(addrOverflow);
      }
      Log("解析桥接设备时出错!\n");
      return;
    }
    final String ssdtName = "SSDT-Bridge";
    Log("正在创建 $ssdtName.dsl...");
    final pad = '    ';
    String ssdt = '''
// Source and info from:
// https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/AcpiSamples/Source/SSDT-BRG0.dsl
DefinitionBlock ("", "SSDT", 2, "RAPID", "PCIBRG", 0x00000000)
{
    /*
     * Start copying here if you're adding this info to an existing SSDT-Bridge!
     */
''';

    for (final acpi in externalRefs) {
      ssdt += '    External ($acpi, DeviceObj)\n';
    }
    ssdt += '\n';

    /// 关闭括号
    /// [input] 输入字符串
    /// [depth] 深度
    /// [iterations] 迭代次数
    /// [pad] 填充字符串
    String closeBrackets(String input, int depth, int iterations, String pad) {
      while (iterations > 0) {
        input += '${pad * depth}}\n';
        iterations--;
        depth--;
      }
      return input;
    }

    List<String> lastPath = [];
    String? acpiString;
    final bridgeNames = <String, List<String>>{};
    final acpiPaths = <String, String>{};

    for (final element in bridgeList..sort()) {
      final comp = element.split(' ');
      final acpi = comp.first;
      int match = 0;
      for (int i = 0; i < comp.length && i < lastPath.length; ++i) {
        if (comp[i] != lastPath[i]) break;
        match++;
      }

      if (lastPath.isNotEmpty) {
        ssdt = closeBrackets(
          ssdt,
          lastPath.length,
          lastPath.length - match,
          pad,
        );
      }

      lastPath = comp;

      if (acpi != acpiString) {
        acpiString = acpi;
        ssdt += '    Scope ($acpiString)\n    {\n';
      }

      final currDepth = comp.length;
      if (currDepth == 0) continue;

      final parentPath = comp.sublist(0, currDepth - 1).join(' ');
      bridgeNames.putIfAbsent(parentPath, () => []);

      final parentAcpi = acpiPaths[parentPath] ?? acpi;
      final baseName = pathDict[bridgeMatch[element]];
      final unique = getUniqueDevice(
        parentAcpi,
        baseName ?? 'BRG0',
        startingNumber: -1,
        usedNames: bridgeNames[parentPath]!,
      );
      final name = unique.name;
      bridgeNames[parentPath]!.add(name);
      acpiPaths[element] = '$parentAcpi.$name';

      String p = pad * currDepth;
      if (bridgeMatch.containsKey(element)) {
        final base = pathDict[bridgeMatch[element]];
        if (base != null && base.isNotEmpty && base != name) {
          ssdt +=
              '$p// User-provided name \'$base\' supplied, incremented for uniqueness\n';
        } else if (base != null && base.isNotEmpty) {
          ssdt += '$p// User-provided name \'$base\' supplied\n';
        } else {
          ssdt +=
              '$p// Customize the following device name if needed, eg. GFX0\n';
        }
      }

      ssdt += ' Device ($name)\n$p{\n';
      p += pad;

      if (bridgeMatch.containsKey(element)) {
        ssdt += '$p// Target Device Path:\n$p// ${bridgeMatch[element]}\n';
      }

      final adrInt = int.parse(comp.last.replaceFirst('0x', ''));
      final adr = switch (adrInt) {
        0 => 'Zero',
        1 => 'One',
        _ =>
          adrInt > 0xFFFF
              ? '0x${adrInt.toRadixString(16).toUpperCase().padLeft(8, '0')}'
              : '0x${adrInt.toRadixString(16).toUpperCase()}',
      };

      ssdt += '$p Name (_ADR, $adr)\n';
    }

    if (lastPath.isNotEmpty) {
      final depth = lastPath.length;
      ssdt = closeBrackets(ssdt, depth, depth, pad);
    }

    ssdt += '''
}
''';

    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Defines missing PCI bridges for property injection",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi);
  }

  Future<void> ssdtALS0({bool prebuilt = false}) async =>
      prebuilt ? await _ssdtALS0Prebuilt() : await _ssdtALS0();

  /// 光线传感器 (适用于笔记本)
  Future<void> _ssdtALS0() async {
    if (!await ensureDSDT()) return;
    Log("正在定位 ACPI0008（ALS）设备…");
    var sortedTables = sortedNicely(d.acpiTables.keys.toList());
    final String ssdtName = "SSDT-ALS0";
    for (var tableName in sortedTables) {
      var table = d.acpiTables[tableName];
      Log("正在检查 $tableName…");
      // 尝试在当前表格中查找任何环境光传感器设备
      var als = d.getDevicePathsWithHid(hid: "ACPI0008", table: table);
      if (als.isNotEmpty) {
        Log("=> 在$tableName 表: ${als[0][0]} 处找到ALS设备!");
        Log("=> 不需要仿冒!\n");

        var sta = getStaVar(
          varS: '',
          device: als[0][0],
          devHid: 'ACPI0008',
          devName: als[0][0].split('.').last,
          table: table,
        );
        if (sta['patches'] != null && sta['patches'].isNotEmpty) {
          if (staNeedsPatching(sta, table)) {
            Log("正在创建 $ssdtName.dsl...");
            var ssdt = """
  DefinitionBlock ("", "SSDT", 2, "RAPID", "ALS0", 0x00000000)
  {
      External ([[als0_path]], DeviceObj)
      External ([[als0_path]].XSTA, [[sta_type]])

      Scope ([[als0_path]])
      {
          Method (_STA, 0, NotSerialized)
          {
              If (_OSI ("Darwin"))
              {
                  Return (0x0F)
              }
              Else
              {
                  Return ([[XSTA]])
              }
          }
      }
  }
""";
            ssdt = ssdt.replaceAll('[[als0_path]]', als[0][0]);
            ssdt = ssdt.replaceAll(
              '[[sta_type]]',
              sta["sta_type"] ?? "MethodObj",
            );
            ssdt = ssdt.replaceAll(
              '[[XSTA]]',
              "${als[0][0]}.XSTA${sta.containsKey("sta_type") && sta["sta_type"] == "MethodObj" ? " ()" : ""}",
            );
            writeSSDT("SSDT-ALS0", ssdt);
            final acpi = {
              "Comment":
                  "Enables ${sta["dev_name"]} for macOS - requires _STA to XSTA rename",
              "Enabled": true,
              "Path": "SSDT-ALS0.aml",
            };
            makePlist(acpi: acpi, patches: sta["patches"] ?? []);
            return;
          } else {
            Log("已正确启用_STA,无需补丁！\n");
          }
        } else {
          Log("未找到，不需要补丁!\n");
        }
        return;
      }
    }

    /// 没有找到任何 ALS 设备
    Log("未找到 ACPI0008（ALS）设备, 需要仿冒设备…");
    Log("正在创建 $ssdtName.dsl...");
    var ssdt = """//
// Original source from:
// https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/AcpiSamples/Source/SSDT-ALS0.dsl
//
DefinitionBlock ("", "SSDT", 2, "RAPID", "ALS0", 0x00000000)
{
    Scope (_SB)
    {
        Device (ALS0)
        {
            Name (_HID, "ACPI0008" /* Ambient Light Sensor Device */)  // _HID: Hardware ID
            Name (_CID, "smc-als")  // _CID: Compatible ID
            Name (_ALI, 0x012C)  // _ALI: Ambient Light Illuminance
            Name (_ALR, Package (0x01)  // _ALR: Ambient Light Response
            {
                Package (0x02)
                {
                    0x64, 
                    0x012C
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
}""";
    final acpi = {
      "Comment": "Faked Ambient Light Sensor",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    writeSSDT(ssdtName, ssdt);
    makePlist(acpi: acpi);
  }

  Future<void> ssdtXOSI({bool prebuilt = false, String? targetString}) async =>
      prebuilt
      ? await _ssdtXOSIPrebuilt()
      : await _ssdtXOSI(targetString: targetString);

  /// XOSI 方案
  /// [targetString] 目标字符串
  Future<void> _ssdtXOSI({String? targetString}) async {
    if (!await ensureDSDT()) return;
    String? highestOsi;
    osiStrings.forEach((key, value) {
      var dsdtTable = d.getDsdt()!['table'];
      if (dsdtTable.contains(value)) {
        highestOsi = key;
      }
    });
    final String ssdtName = "SSDT-XOSI";
    Log("正在检测XOSI方案...");
    if (targetString == null ||
        targetString.isEmpty ||
        !osiStrings.containsKey(targetString)) {
      if (highestOsi != null && highestOsi!.isNotEmpty) {
        Log("=> 已自动检测到：$highestOsi（${osiStrings[highestOsi]}）");
      }
      // 自动选择默认项
      if (highestOsi != null && highestOsi!.isNotEmpty) {
        targetString = highestOsi;
      } else {
        targetString = osiStrings.keys.first;
      }
      Log(
        "=> 已自动选择用于 $targetString (${osiStrings[targetString]}) 版本的$ssdtName",
      );
    } else {
      Log(
        "=> 已手动选择用于 $targetString (${osiStrings[targetString]}) 版本的$ssdtName",
      );
    }

    Log(
      "正在创建支持 $targetString (${osiStrings[targetString]}) 版本的 $ssdtName.dsl…",
    );

    String ssdt = """
DefinitionBlock ("", "SSDT", 2, "RAPID", "XOSI", 0x00001000)
{
    Method (XOSI, 1, NotSerialized)
    {
        /* Edited from:
         * https://github.com/dortania/Getting-Started-With-ACPI/blob/master/extra-files/decompiled/SSDT-XOSI.dsl
         * Based off of: 
         * https://docs.microsoft.com/en-us/windows-hardware/drivers/acpi/winacpi-osi#_osi-strings-for-windows-operating-systems
         * Add OSes from the below list as needed, most only check up to Windows 2015
         * but check what your DSDT looks for
         */
        Store (Package ()
        {
""";

    for (var i = 0; i < osiStrings.length; i++) {
      var x = osiStrings.keys.elementAt(i);
      var osiString = osiStrings[x];
      ssdt += '                "$osiString"';
      if (x == targetString || i == osiStrings.length - 1) {
        // 最后一项 - 停止
        ssdt += " // $x";
        break;
      }
      // 添加逗号和换行符
      ssdt += ", // $x\n";
    }
    ssdt += "\n";
    ssdt += """
        }, Local0)
        If (_OSI ("Darwin"))
        {
            Return (LNotEqual (Match (Local0, MEQ, Arg0, MTR, Zero, Zero), Ones))
        }
        Else
        {
            Return (_OSI (Arg0))
        }
    }
}""";

    Log("正在检查 OSID 方法…");
    List osid = d.getMethodPaths(obj: "OSID");
    List<Map<String, String>> patches = [];

    if (osid.isNotEmpty) {
      Log("=> 在偏移量 ${osid[0][1]} 处找到了 ${osid[0][0]} 方法");
      patches.add({
        "Comment":
            "OSID to XSID rename - must come before _OSI to XOSI rename!",
        "Find": "4F534944",
        "Replace": "58534944",
      });
    } else {
      Log("=> 未找到，无需将 OSID 重命名为 XSID");
    }
    Log("正在创建 _OSI 到 XOSI 的重命名…");
    patches.add({
      "Comment": "_OSI to XOSI rename - requires $ssdtName.aml",
      "Find": "5F4F5349",
      "Replace": "584F5349",
    });
    final acpi = {
      "Comment":
          "_OSI override to return true through $targetString - requires _OSI to XOSI rename",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, patches: patches, replace: true);
    writeSSDT(ssdtName, ssdt);
  }

  /// 加载指定 ACPI 表
  /// [tableSignature] 表签名
  /// [tablePath] 表路径
  Future<Map<String, dynamic>?> loadTable(
    String tableSignature, {
    String? tablePath,
  }) async {
    if (!checkIasl()) return null;
    Log("正在查找 $tableSignature 表…");
    Map<String, dynamic>? table;
    // 如果未传入 ACPI 表路径,则从已加载的 ACPI 表中查找
    if (tablePath == null || tablePath.isEmpty) {
      final tableList = d.acpiTables.values
          .where(
            (t) =>
                t['signature']?.toUpperCase() == tableSignature.toUpperCase(),
          )
          .toList();
      if (tableList.isNotEmpty) table = tableList.first;
    } else {
      // 从已传入 ACPI 表路径加载表
      // 检查并确保路径有效
      tablePath = await util.checkPath(
        filePath: tablePath,
        onError: (e) => Log.error(e),
      );
      if (tablePath.isNotEmpty) {
        // 加载表
        final result = await d.loadTable(tablePath);
        final tableList = result.$1.values
            .where(
              (t) =>
                  t['signature']?.toUpperCase() == tableSignature.toUpperCase(),
            )
            .toList();
        if (tableList.isNotEmpty) table = tableList.first;
      }
    }

    if (table == null || table.isEmpty) {
      Log.warning(
        config.acpiDirectory != null && config.acpiDirectory!.isNotEmpty
            ? "在当前目录 ${config.acpiDirectory} 未发现有效 $tableSignature 表!"
            : "未发现有效 $tableSignature 表!",
      );
      return null;
    }

    return table;
  }

  /// 从 FACP lines 中查找第一个包含关键字的字段值
  String findFacpField(List<dynamic> lines, String key) {
    for (var line in lines) {
      if (line.contains(key)) {
        final parts = line.split(" : ");
        return parts.length > 1 ? parts[1].trim() : "";
      }
    }
    return "";
  }

  /// 验证 SSDT 表签名
  /// [tableSignature] 表签名
  /// [tablePath] 表路径
  Future<(bool, Map)> validateTableSignature(
    String tableSignature, {
    String? tablePath,
  }) async {
    final targetTable = await loadTable(tableSignature, tablePath: tablePath);
    if (targetTable == null) return (false, {});
    Log("已找到 $tableSignature 表,正在验证签名…");
    bool gotSig = false;
    final List<String> lines = targetTable['lines'] ?? [];
    for (var l in lines) {
      if (l.contains('Signature : "$tableSignature"')) {
        Log("=> $tableSignature 表签名验证通过!");
        gotSig = true;
        break;
      }
    }
    if (!gotSig) {
      Log.warning("=> 未找到，似乎不是一个有效的 $tableSignature 表!\n");
    }
    return (gotSig, targetTable);
  }

  /// SSDT-FACP
  /// [facpPath] FACP 表路径
  Future<void> ssdtFACP({String? facpPath}) async {
    final (valid, table) = await validateTableSignature(
      'FACP',
      tablePath: facpPath,
    );
    if (!valid) return;
    final String valueToCauseReset = 'Value to cause reset';
    Log("正在检查 $valueToCauseReset 值…");
    List<String> lines = table['lines'] ?? [];
    String valueCauseReset = findFacpField(lines, '$valueToCauseReset :');
    if (valueCauseReset.isEmpty) {
      Log.warning("未找到 $valueToCauseReset 值! 已终止操作!");
      return;
    }
    Log("获取到 $valueToCauseReset 值 : $valueCauseReset");

    // 提取 Reset Register Address（通常在前面两行）
    String addressValue = "";
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('$valueToCauseReset :')) {
        if (i > 2 && lines[i - 2].contains('Address :')) {
          addressValue = findFacpField([lines[i - 2]], 'Address :');
        }
        break;
      }
    }

    if (addressValue.isEmpty) {
      Log.warning("未找到 Reset Register Address 值! 已终止操作!");
      return;
    }
    Log("获取到 Reset Register Address 值 : $addressValue");

    final findAddrHeader = util.splitHexStringIntoReversedChunks(addressValue);
    final findAddress = "$findAddrHeader$valueCauseReset";
    final replaceAddress = "${findAddrHeader}0E";

    Log("需要修补的ACPI 补丁如下: ");
    Log("=>       Find : $findAddress");
    Log("=> Replace : $replaceAddress");

    final patches = [
      {
        "Signature": "FACP",
        "Comment": "Force cold reboot (reset value 0x0E for macOS)",
        "Find": findAddress,
        "Replace": replaceAddress,
      },
    ];

    makePlist(patches: patches, replace: true);
  }

  /// SSDT-APIC
  /// [apicPath] APIC 表路径
  Future<void> ssdtAPIC({String? apicPath}) async {
    if (!await ensureDSDT()) return;
    final (valid, table) = await validateTableSignature(
      'APIC',
      tablePath: apicPath,
    );
    if (!valid) return;

    Log("正在修补 APIC 表…");
    int processorIndex = 0;
    final lines = List<String>.from(table['lines'] ?? []);
    final int apicLength = lines.length;
    String ssdt = '';
    for (final tableName in sortedNicely(d.acpiTables.keys.toList())) {
      final table = d.acpiTables[tableName]!;
      final processors = d.getProcessorPaths(table: table);
      if (processors.isEmpty) continue;
      for (int index = 0; index < apicLength; index++) {
        final line = lines[index];
        final bool isValidProcessorApic =
            line.contains('Subtable Type :') &&
            line.contains('[Processor Local APIC]') &&
            !line.contains('Unknown');

        if (!isValidProcessorApic) {
          ssdt += '$line\n';
          continue;
        }

        final int idLineIndex = index + 2;
        if (idLineIndex >= apicLength) {
          ssdt += '$line\n';
          continue;
        }

        final idLine = lines[idLineIndex].trimRight();

        /// 从 APIC 表中提取 Processor ID（最后两位）
        final String apicProcessorId = idLine.substring(idLine.length - 2);
        String processorId;
        try {
          processorId = table['lines'][processors[processorIndex][1]]
              .split(', ')[1]
              .substring(2);
        } catch (_) {
          Log.warning("无法解析 $tableName 中的 Processor ID，终止修补");
          return;
        }

        /// 第一个 CPU 已匹配,直接退出
        if (processorIndex == 0 && apicProcessorId == processorId) {
          Log.warning("在 $tableName 中第一个 CPU 已匹配, 无需修补 APIC 表!");
          return;
        }

        Log("=> 修正 APIC Processor ID: $apicProcessorId → $processorId");

        /// 修补 Processor ID
        lines[idLineIndex] =
            idLine.substring(0, idLine.length - 2) + processorId;

        processorIndex++;

        ssdt += '$line\n';
      }
    }
    if (ssdt.isEmpty) {
      Log.warning("=> 未找到 Processor 匹配项! 已终止操作!");
      return;
    }
    Log("=> APIC 表修补完成!");
    final String ssdtName = "SSDT-APIC";
    Log("正在创建 $ssdtName.dsl…");
    writeSSDT(ssdtName, ssdt);

    final acpi = {
      "Comment": "Pathing APIC table - requires original table dropped",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };

    final drops = [
      {
        "Comment": "Drop APIC Table",
        "Table": table,
        "Signature": table['signature'] ?? 'APIC',
      },
    ];

    makePlist(acpi: acpi, drops: drops);
  }

  /// SSDT-DMAR
  /// [dmarPath] DMAR 表路径
  Future<void> ssdtDMAR({String? dmarPath}) async {
    final (valid, table) = await validateTableSignature(
      'DMAR',
      tablePath: dmarPath,
    );
    if (!valid) return;
    bool reserved = false;
    int regionCount = 0;
    List<String> newDMAR = [];
    List<String> lines = table['lines'] ?? [];
    Log("正在检查 DMAR 表保留内存区域…");
    for (var line in lines) {
      if (line.contains("Subtable Type : 0001 [Reserved Memory Region]")) {
        regionCount++;
        reserved = true;
      } else if (line.contains("Subtable Type : ")) {
        reserved = false;
      }
      if (!reserved) {
        // 确保 "Reserved : XX" 中的任何数字都是 0
        if (line.contains("Reserved : ")) {
          List<String> parts = line.split(" : ");
          if (parts.length == 2) {
            String res = parts[0];
            String value = parts[1];
            StringBuffer newVal = StringBuffer();

            for (int i = 0; i < value.length; i++) {
              String char = value[i];
              if (!" 0123456789ABCDEF".contains(char)) {
                // 直接将剩余内容原样存入变量中。
                newVal.write(value.substring(i));
                break;
              } else if (char != "0" && char != " ") {
                // 确保将所有非 0、非空格值设置为 0
                char = "0";
              }
              newVal.write(char);
            }

            line = "$res : $newVal";
          }
        }
        newDMAR.add(line);
      }
    }

    if (regionCount == 0) {
      Log("=> 未发现保留内存区域, 无需修补 DMAR!\n");
      return;
    }
    final String ssdtName = "SSDT-DMAR";
    Log("发现 $regionCount 个保留内存区域, 正在生成新表…");
    writeSSDT(ssdtName, newDMAR.join("\n"));
    final acpi = {
      "Comment":
          "Replacement DMAR table with Reserved Memory Regions stripped - requires DMAR table be dropped",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };

    final drops = [
      {
        "Comment": "Drop DMAR Table",
        "Table": table,
        "Signature": table['signature'] ?? 'DMAR',
      },
    ];
    makePlist(acpi: acpi, drops: drops);
  }

  Future<void> ssdtIMEI({bool prebuilt = false, String? fakeid}) async =>
      prebuilt
      ? await _ssdtIMEIPrebuilt(fakeid: fakeid)
      : await _ssdtIMEI(fakeid: fakeid);

  /// SSDT-IMEI
  /// 用于桥接仿冒IMEI 设备，适用于 Ivy Bridge 6系主板和 Sandy Bridge 7系主板
  /// 6系主板需要fakeid为3A1E，7系主板需要fakeid为3A1C
  /// [fakeid] 仿冒设备ID
  Future<void> _ssdtIMEI({String? fakeid}) async {
    if (!await ensureDSDT()) return;
    if (fakeid == null) {
      Log.warning("请选择IMEI补丁!");
      return;
    }
    Log("正在通过地址 0x00160000 查找 IMEI 设备...");
    ({String busParent, String busPath, String tableName})? imei = getDevAtAdr(
      targetAdr: 0x00160000,
    );
    if (imei != null && imei.busParent.isNotEmpty) {
      Log.warning("=> 已在 ${imei.busPath} 找到 IMEI 设备, 无需桥接仿冒!已终止操作！");
      Log("");
      return;
    }
    Log("未找到 IMEI 设备, 需要仿冒该设备…");
    Log("正在校验父设备...");
    Log("正在寻找位于 0x00020000 的 iGPU 设备…");
    dynamic parent;
    var igpu = getDevAtAdr(targetAdr: 0x00020000);
    if (igpu == null || igpu.busParent.isEmpty) {
      Log("=> 未找到 iGPU 设备!");
      Log("正在尝试定位 PCI 根设备...");
      var pciRoots = [];
      for (var tableName in sortedNicely(d.acpiTables.keys.toList())) {
        var table = d.acpiTables[tableName];
        pciRoots = d.getDevicePathsWithHid(hid: "PNP0A08", table: table);
        pciRoots += d.getDevicePathsWithHid(hid: "PNP0A03", table: table);
        pciRoots += d.getDevicePathsWithHid(hid: "ACPI0016", table: table);
        if (pciRoots.isNotEmpty) {
          break;
        }
      }
      if (pciRoots.isEmpty) {
        Log.warning("=> 未找到 PCI 根设备!已终止操作!");
        return;
      }
      parent = pciRoots[0][0];
      Log("=> 找到 PCI 根设备: $parent");
    } else {
      Log("=> 找到 iGPU 设备: ${igpu.busPath}");
      parent = igpu.busParent;
      Log("=> 使用父设备: $parent");
    }
    Log("正在收集仿冒device-id方案…");
    if (fakeid.toUpperCase() == '3A1E') {
      Log("=> 仿冒为7系主板IMEI (device-id: $fakeid),以匹配第3代 Ivy Bridge处理器");
    } else if (fakeid.toUpperCase() == '3A1C') {
      Log("=> 仿冒为6系主板IMEI (device-id: $fakeid),以匹配第2代Sandy Bridge处理器");
    } else {
      Log.warning("=> 未启用 SSDT 仿冒 IMEI，必须通过 DeviceProperties 设置 device-id!");
    }
    final String ssdtName = "SSDT-IMEI";
    Log("正在创建 $ssdtName.dsl...");
    String ssdt = "";
    if (fakeid.isEmpty) {
      ssdt = """
//
// Original source from:
// https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/AcpiSamples/Source/SSDT-IMEI.dsl
//
DefinitionBlock ("", "SSDT", 2, "RAPID", "IMEI", 0x00000000)
{
    External ([[parent]], DeviceObj)

    Scope ([[parent]])
    {
        Device (IMEI)
        {
            Name (_ADR, 0x00160000)  // _ADR: Address
        }
    }
}
""";

      ssdt = ssdt.replaceAll('[[parent]]', parent);
    } else {
      ssdt = """
//
// Original source from:
// https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/AcpiSamples/Source/SSDT-IMEI.dsl
//
DefinitionBlock ("", "SSDT", 2, "RAPID", "IMEI", 0x00000000)
{
    External ([[parent]], DeviceObj)

    Scope ([[parent]])
    {
        Device (IMEI)
        {
            Name (_ADR, 0x00160000)  // _ADR: Address
            Method (_DSM, 4, NotSerialized)
            {
                If (LEqual (Arg2, Zero)) {
                    Return (Buffer (One) { 0x03 })
                }
                Return (Package (0x02)
                {
                    "device-id",
                    Buffer (0x04) { 0x3A, 0x1[[fake]], 0x00, 0x00 }
                })
            }
        }
    }
}
""";

      ssdt = ssdt
          .replaceAll('[[parent]]', parent)
          .replaceAll('[[fake]]', (fakeid.substring(fakeid.length - 1)));
    }

    final acpi = {
      "Comment": fakeid.toUpperCase() == '3A1C'
          ? "Faking IMEI as 6-series to match Sandy Bridge CPU"
          : "Faking IMEI as 7-series to match Ivy Bridge CPU",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi);
    writeSSDT(ssdtName, ssdt);
  }

  /// Fixing Uncore Bridges (X79/C602,X99/C612 Required)
  Future<void> ssdtUNC({bool prebuilt = false}) async =>
      prebuilt ? await _ssdtUNCPrebuilt() : await _ssdtUNC();

  Future<void> _ssdtUNC() async {
    if (!await ensureDSDT()) return;

    Log("正在查找 UNC (PNP0A03) 设备...");
    final devices = d.getDevicePathsWithHid(hid: "PNP0A03");

    if (devices.isEmpty ||
        devices[0].isEmpty ||
        !devices[0].first.split('.').last.startsWith('UNC')) {
      Log.warning("未找到 UNC (PNP0A03) 设备!无需 SSDT-UNC 补丁!已终止操作！\n");
      return;
    }

    Log("=> 共找到 ${devices.length} 个 UNC 设备");
    for (int i = 0; i < devices.length; i++) {
      Log("=> 第 ${i + 1} 个 UNC 设备: ${devices[i].first}");
    }

    final String ssdtName = "SSDT-UNC";
    String ssdt = '';
    Map<String, dynamic> acpi = {};
    List<Map<String, dynamic>> patches = [];

    const staHex = "5F535441"; // _STA
    const xstaHex = "58535441"; // XSTA

    /// 记录每个 UNC 是否原生存在 _STA
    final Map<String, bool> hasStaMap = {};

    for (var device in devices) {
      final devicePath = device.first;
      final devName = devicePath.split('.').last;

      final staMethod = d.getMethodPaths(obj: "$devicePath._STA");

      Log("=> 检查 $devName: _STA 方法是否存在");

      final bool hasSta = staMethod.isNotEmpty;
      hasStaMap[devicePath] = hasSta;

      if (!hasSta) {
        Log.warning("=> $devName: _STA 方法不存在!");
        continue;
      }

      final staIndex = d.findNextHex(index: staMethod[0][1]).$2;
      Log("=> 在索引 $staIndex 找到 $devName: _STA 方法!");
      Log("=> 生成 $devName: _STA 到 XSTA 的补丁");

      final (padl, padr) = d.getShortestUniquePad(
        currentHex: staHex,
        index: staIndex,
      );

      Log("");
      Log("           Find: ${padl + staHex + padr}");
      Log("     Replace: ${padl + xstaHex + padr}");
      Log("");

      patches.add({
        "Comment": "$devName _STA to XSTA rename - requires $ssdtName.aml",
        "Find": padl + staHex + padr,
        "Replace": padl + xstaHex + padr,
      });
    }

    ssdt += 'DefinitionBlock ("", "SSDT", 2, "RAPID", "UNC", 0x00001000)\n{\n';

    final List<String> basePaths = devices
        .map((e) => e.first.toString())
        .toList();

    for (String path in basePaths) {
      ssdt += '    External ($path, DeviceObj)\n';
      if (hasStaMap[path] == true) {
        ssdt += '    External ($path.XSTA, MethodObj)\n';
      }
    }

    ssdt += '\n';

    for (String path in basePaths) {
      final bool hasSta = hasStaMap[path] ?? false;

      String devName = path
          .replaceAll(RegExp(r'_+$'), '')
          .replaceAll('_SB_', '\\_SB');

      if (hasSta) {
        ssdt +=
            '''
    Scope ($devName)
    {
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If (_OSI ("Darwin"))
            {
                Return (Zero)
            }
            Return ($devName.XSTA ())
        }
    }
''';
      } else {
        ssdt +=
            '''
    Scope ($devName)
    {
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If (_OSI ("Darwin"))
            {
                Return (Zero)
            }
        }
    }
''';
      }
    }

    ssdt += "\n}\n";

    acpi = {
      "Comment":
          "Fixing Uncore Bridges with ${devices.map((e) => e.first.split('.').last).join(', ')} _STA patching",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };

    writeSSDT(ssdtName, ssdt);
    makePlist(acpi: acpi, patches: patches, replace: true);
  }

  Future<void> _ssdtUNCPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-UNC";
    Log("正在创建预编译 $ssdtName.dsl...");
    final ssdt = Prebuilt.ssdtUNC;
    writeSSDT(ssdtName, ssdt);

    final acpi = {
      "Comment": "Fixing Uncore Bridges (X79/C602,X99/C612 Required)",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  Future<void> ssdtDTGP({bool prebuilt = false}) async =>
      prebuilt ? await _ssdtDTGPPrebuilt() : await _ssdtDTGP();

  Future<void> _ssdtDTGP() async {
    if (!await ensureDSDT()) return;
    String methodPath = "";
    var sortedTables = sortedNicely(d.acpiTables.keys.toList());
    for (var tableName in sortedTables) {
      var table = d.acpiTables[tableName];
      Log("正在检查 $tableName…");
      if (methodPath.isEmpty) {
        // 查找是否存在 DTGP 方法
        Log("正在检查是否存在 DTGP 方法...");
        final dtgp = d.getMethodPaths(obj: "DTGP", table: table);
        if (dtgp.isNotEmpty && dtgp[0].isNotEmpty) {
          Log.warning(
            "=> 无需创建 SSDT-DTGP,已在 ${dtgp[0].first} 找到 DTGP 方法! 已终止操作！",
          );
        } else {
          Log("=> 未找到 DTGP 方法!");
        }
      }
    }
    if (methodPath.isEmpty) {
      Log("=> 在上述所有ACPI表中均未找到 DTGP 方法! \n");
      _ssdtDTGPPrebuilt();
    }
  }

  Future<void> _ssdtDTGPPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-DTGP";
    Log("正在创建预编译 $ssdtName.dsl...");
    final ssdt = Prebuilt.ssdtDTGP;
    writeSSDT(ssdtName, ssdt);

    final acpi = {
      "Comment": "Add DTGP method supported",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  Future<void> ssdtDMAC({bool prebuilt = false}) async =>
      prebuilt ? await _ssdtDMACPrebuilt() : await _ssdtDMAC();

  Future<void> _ssdtDMAC() async {
    if (!await ensureDSDT()) return;
    String devicePath = "";
    var sortedTables = sortedNicely(d.acpiTables.keys.toList());
    for (var tableName in sortedTables) {
      var table = d.acpiTables[tableName];
      Log("正在检查 $tableName…");

      /// 根据设备ID: PNP0200 查找 DMA 设备
      Log("正在查找 DMA (PNP0200) 设备...");
      final device = d.getDevicePathsWithHid(hid: "PNP0200", table: table);
      if (device.isNotEmpty && device[0].isNotEmpty) {
        Log.warning(
          "=> 无需仿冒DMA设备,已在 ${device[0].first} 找到 PNP0200 设备! 已终止操作！\n",
        );
        return;
      } else {
        Log("=> 未找到 DMA (PNP0200) 设备!");
      }
    }

    if (devicePath.isEmpty) {
      Log.warning("=> 在上述所有ACPI表中均未找到 DMA (PNP0200) 设备! 已终止操作！\n");
      return;
    }

    final lpc = getLpcName();
    if (lpc == null) {
      return;
    }
    String ssdt = """
    
    DefinitionBlock ("", "SSDT", 2, "RAPID", "DMAC", 0x00000000)
{
    External ([[LPC_PATH]], DeviceObj)

    Scope ([[LPC_PATH]])
    {
        Device (DMAC)
        {
            Name (_HID, EisaId ("PNP0200") /* PC-class DMA Controller */)  // _HID: Hardware ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                IO (Decode16,
                    0x0000,             // Range Minimum
                    0x0000,             // Range Maximum
                    0x01,               // Alignment
                    0x20,               // Length
                    )
                IO (Decode16,
                    0x0081,             // Range Minimum
                    0x0081,             // Range Maximum
                    0x01,               // Alignment
                    0x11,               // Length
                    )
                IO (Decode16,
                    0x0093,             // Range Minimum
                    0x0093,             // Range Maximum
                    0x01,               // Alignment
                    0x0D,               // Length
                    )
                IO (Decode16,
                    0x00C0,             // Range Minimum
                    0x00C0,             // Range Maximum
                    0x01,               // Alignment
                    0x20,               // Length
                    )
                DMA (Compatibility, NotBusMaster, Transfer8_16, )
                    {4}
            })
        }
    }
}
    
    """;
    ssdt = ssdt.replaceAll('[[LPC_PATH]]', lpc);
    final String ssdtName = "SSDT-DMAC";
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Spoof a DMA controller for macOS LPC bus and DMA recognition",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  Future<void> _ssdtDMACPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-DMAC";
    Log("正在创建预编译 $ssdtName.dsl...");
    final ssdt = Prebuilt.ssdtDMAC;
    writeSSDT(ssdtName, ssdt);

    final acpi = {
      "Comment": "Spoof a DMA controller for macOS LPC bus and DMA recognition",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  Future<void> ssdtLED({bool prebuilt = false}) async => _ssdtLED();

  String _methodFlag(List<dynamic> info) {
    if (info.length >= 5) return info[4].toString();
    return "NotSerialized";
  }

  Map<String, dynamic> _renameMethodPatch({
    required String method,
    required String renamed,
    required String flag,
    required String comment,
  }) {
    final methodHex = method.codeUnits
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    final renamedHex = renamed.codeUnits
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    final suffix = flag == "NotSerialized" ? "01" : "09";
    return {
      "Comment": comment,
      "Find": "$methodHex$suffix",
      "Replace": "$renamedHex$suffix",
    };
  }

  Future<void> ssdtSleepHook({
    required bool needsPts,
    required bool needsWak,
    bool includeLid = false,
    bool includeLed = false,
    bool includeWakeScreen = false,
    bool includeFixShutdown = false,
  }) async {
    if (!needsPts && !needsWak) return;
    if (!await ensureDSDT()) return;

    final lidHelper = includeLid
        ? getUniqueObjectName('\\_SB', 'RAPD', startingNumber: -1).name
        : '';
    final lidPrepareMethod = includeLid ? '\\_SB.$lidHelper.PLID' : '';
    final lidWakeMethod = includeLid ? '\\_SB.$lidHelper.WLID' : '';
    final wakeScreenMethod = includeWakeScreen
        ? '\\${getUniqueObjectName('\\', 'WSCN', startingNumber: -1).name}'
        : '';
    final ledMethod = includeLed
        ? '\\${getUniqueObjectName('\\', 'WLED', startingNumber: -1).name}'
        : '';

    List<dynamic> pts = [];
    List<dynamic> wak = [];
    var sortedTables = sortedNicely(d.acpiTables.keys.toList());
    for (var tableName in sortedTables) {
      var table = d.acpiTables[tableName];
      Log("正在检查 $tableName…");
      if (needsPts && pts.isEmpty) {
        Log("正在检查是否存在 _PTS 方法...");
        pts = d.getMethodInfo(obj: "_PTS", table: table);
        if (pts.isNotEmpty) {
          Log("=> 已找到 ${pts.first} 方法!");
        } else {
          Log("=> 未找到 _PTS 方法!");
        }
      }
      if (needsWak && wak.isEmpty) {
        Log("正在检查是否存在 _WAK 方法...");
        wak = d.getMethodInfo(obj: "_WAK", table: table);
        if (wak.isNotEmpty) {
          Log("=> 已找到 ${wak.first} 方法!");
        } else {
          Log("=> 未找到 _WAK 方法!");
        }
      }
      if ((!needsPts || pts.isNotEmpty) && (!needsWak || wak.isNotEmpty)) {
        break;
      }
    }

    if (needsPts && pts.isEmpty) {
      Log.warning("=> 未找到 _PTS 方法, 将不生成 _PTS 调度入口和重命名补丁!");
    }
    if (needsWak && wak.isEmpty) {
      Log.warning("=> 未找到 _WAK 方法, 将不生成 _WAK 调度入口和重命名补丁!");
    }
    final hasPtsEntry = needsPts && pts.isNotEmpty;
    final hasWakEntry = needsWak && wak.isNotEmpty;
    if (!hasPtsEntry && !hasWakEntry) {
      Log.warning("=> 未找到可调度的 _PTS/_WAK 方法, 已跳过 SSDT-SleepHook!\n");
      return;
    }

    final ssdtName = "SSDT-SleepHook";
    Log("正在创建 $ssdtName.dsl...");

    final buffer = StringBuffer();
    buffer.writeln(
      'DefinitionBlock ("", "SSDT", 2, "RAPID", "SLPHOOK", 0x00000000)',
    );
    buffer.writeln('{');
    if (pts.isNotEmpty) {
      buffer.writeln('    External (ZPTS, MethodObj)');
      if (includeLid) {
        buffer.writeln('    External ($lidPrepareMethod, MethodObj)');
      }
      if (includeFixShutdown) buffer.writeln('    External (PFSH, MethodObj)');
    }
    if (wak.isNotEmpty) {
      buffer.writeln('    External (ZWAK, MethodObj)');
      if (includeLid) {
        buffer.writeln('    External ($lidWakeMethod, MethodObj)');
      }
      if (includeWakeScreen) {
        buffer.writeln('    External ($wakeScreenMethod, MethodObj)');
      }
      if (includeLed) buffer.writeln('    External ($ledMethod, MethodObj)');
    }
    if (pts.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('    Method (_PTS, 1, ${_methodFlag(pts)})');
      buffer.writeln('    {');
      if (includeLid) {
        buffer.writeln('''
        If (CondRefOf ($lidPrepareMethod))
        {
            $lidPrepareMethod (Arg0)
        }''');
      }
      if (includeFixShutdown) {
        buffer.writeln('''
        If (CondRefOf (PFSH))
        {
            PFSH (Arg0)
        }''');
      }
      buffer.writeln('''
        ZPTS (Arg0)
    }
''');
    }
    if (wak.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('    Method (_WAK, 1, ${_methodFlag(wak)})');
      buffer.writeln('    {');
      if (includeLid) {
        buffer.writeln('''
        If (CondRefOf ($lidWakeMethod))
        {
            $lidWakeMethod (Arg0)
        }''');
      }
      if (includeWakeScreen) {
        buffer.writeln('''
        If (CondRefOf ($wakeScreenMethod))
        {
            $wakeScreenMethod (Arg0)
        }''');
      }
      if (includeLed) {
        buffer.writeln('''
        If (CondRefOf ($ledMethod))
        {
            $ledMethod (Arg0)
        }''');
      }
      buffer.writeln('''
        Return (ZWAK (Arg0))
    }
''');
    }
    buffer.writeln('}');

    if (!await writeSSDT(ssdtName, buffer.toString())) return;
    final acpi = {
      "Comment": "Dispatch _PTS/_WAK hooks for selected SSDTs",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    final patches = <Map<String, dynamic>>[];
    if (pts.isNotEmpty) {
      patches.add(
        _renameMethodPatch(
          method: "_PTS",
          renamed: "ZPTS",
          flag: _methodFlag(pts),
          comment: "_PTS to ZPTS rename - requires $ssdtName.aml",
        ),
      );
    }
    if (wak.isNotEmpty) {
      patches.add(
        _renameMethodPatch(
          method: "_WAK",
          renamed: "ZWAK",
          flag: _methodFlag(wak),
          comment: "_WAK to ZWAK rename - requires $ssdtName.aml",
        ),
      );
    }
    await makePlist(acpi: acpi, patches: patches, replace: true);
  }

  Future<void> _ssdtLED() async {
    if (!await ensureDSDT()) return;
    String sstPath = "";
    var sortedTables = sortedNicely(d.acpiTables.keys.toList());
    for (var tableName in sortedTables) {
      var table = d.acpiTables[tableName];
      Log("正在检查 $tableName…");
      if (sstPath.isEmpty) {
        Log("正在检查是否存在 _SST 方法...");
        final sst = d.getMethodPaths(obj: "_SST", table: table);
        if (sst.isNotEmpty && sst[0].isNotEmpty) {
          Log("=> 已在 ${sst[0].first} 找到 _SST 方法!");
          sstPath = sst[0].first;
        } else {
          Log("=> 未找到 _SST 方法!");
        }
      }
    }
    if (sstPath.isEmpty) {
      Log.warning("=> 在上述所有ACPI表中均未找到 _SST 方法! 已终止操作！\n");
      return;
    }
    final hookMethod = getUniqueObjectName(
      '\\',
      'WLED',
      startingNumber: -1,
    ).name;
    if (hookMethod != 'WLED') {
      Log("=> 根作用域 WLED 已被占用，改用 $hookMethod。");
    }
    final ssdtName = "SSDT-LED";
    Log("正在创建 $ssdtName.dsl...");
    final ssdt =
        '''
 DefinitionBlock ("", "SSDT", 1, "RAPID", "LED", 0x00000000)
{
    External ($sstPath, MethodObj)
    Method ($hookMethod, 1, NotSerialized)
    {
      
      If (_OSI ("Darwin"))
        {
            If (Arg0 == 0x03)
            {
                $sstPath (One)
            }
        }
    }
}
    ''';
    if (!await writeSSDT(ssdtName, ssdt)) return;
    final acpi = {
      "Comment": "Fixing LED issues - called by SSDT-SleepHook",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    await makePlist(acpi: acpi, replace: true);
  }

  Future<void> ssdtWakeScreen({bool prebuilt = false}) async =>
      _ssdtWakeScreen();

  Future<void> _ssdtWakeScreen() async {
    if (!await ensureDSDT()) return;
    String devicePath = "";
    var sortedTables = sortedNicely(d.acpiTables.keys.toList());
    for (var tableName in sortedTables) {
      var table = d.acpiTables[tableName];
      Log("正在检查 $tableName…");
      if (devicePath.isEmpty) {
        Log("正在检查是否存在 PNP0C0D 设备...");
        final device = d.getDevicePathsWithHid(hid: "PNP0C0D", table: table);
        if (device.isNotEmpty && device[0].isNotEmpty) {
          devicePath = device[0].first;
          Log("=> 已在 $devicePath 找到 PNP0C0D 设备!");
        } else {
          Log("=> 未找到 PNP0C0D 设备!");
        }
      }
    }
    if (devicePath.isEmpty) {
      Log.warning("=> 在上述所有ACPI表中均未找到 PNP0C0D 设备! 已终止操作！\n");
      return;
    }
    final hookMethod = getUniqueObjectName(
      '\\',
      'WSCN',
      startingNumber: -1,
    ).name;
    if (hookMethod != 'WSCN') {
      Log("=> 根作用域 WSCN 已被占用，改用 $hookMethod。");
    }
    final ssdtName = "SSDT-WakeScreen";
    Log("正在创建 $ssdtName.dsl...");
    String ssdt =
        '''
  DefinitionBlock("", "SSDT", 2, "RAPID", "WakeS", 0x00000000)
{
    External($devicePath, DeviceObj)
    Method ($hookMethod, 1, NotSerialized)
    {
        If (_OSI ("Darwin"))
        {
            If (Arg0 == 0x03)
            {
                Notify ($devicePath, 0x80)
            }
        }
    }
}      
      ''';
    if (!await writeSSDT(ssdtName, ssdt)) return;
    final acpi = {
      "Comment": "Fixing WakeScreen issues - called by SSDT-SleepHook",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    await makePlist(acpi: acpi, replace: true);
  }

  /// 检查系统状态支持情况（_S0, _S3, _S4, _S5）
  /// 返回值: (支持的系统状态列表, 不支持的系统状态列表)
  Future<(List?, List?)> checkSystemState({String? facpPath}) async {
    if (!await ensureDSDT()) return (null, null);
    bool? aoacState = await checkAOAC(facpPath: facpPath);
    final List<String> systemStatesCheck = ["_S0", "_S3", "_S4", "_S5"];
    List<String> systemStatesFound = [];
    var sortedTables = sortedNicely(d.acpiTables.keys.toList());
    for (var tableName in sortedTables) {
      var table = d.acpiTables[tableName];
      Log("正在检查 $tableName…");
      for (final systemState in systemStatesCheck) {
        if (systemStatesFound.contains(systemState)) continue;
        Log("正在检查是否存在 $systemState...");
        final nameSystemState = d.getNamePaths(obj: systemState, table: table);
        final methodSystemState = d.getMethodPaths(
          obj: systemState,
          table: table,
        );
        if (nameSystemState.isNotEmpty && nameSystemState[0].isNotEmpty) {
          Log("=> 已在 ${nameSystemState[0].first} 找到 $systemState");
          systemStatesFound.add(systemState);
        } else if (methodSystemState.isNotEmpty &&
            methodSystemState[0].isNotEmpty) {
          Log("=> 已在 ${methodSystemState[0].first} 找到 $systemState");
          systemStatesFound.add(systemState);
        } else {
          Log("=> 未找到 $systemState");
        }
      }
      if (systemStatesFound.length == systemStatesCheck.length) {
        break;
      }
    }
    Log("已检查所有ACPI表!");
    // 支持系统状态
    Log("=> 支持系统状态: ${systemStatesFound.join(", ")}");
    // 不支持的系统状态
    final systemStatesNotSupported = systemStatesCheck
        .where((element) => !systemStatesFound.contains(element))
        .toList();
    if (systemStatesNotSupported.isNotEmpty) {
      Log.warning("=> 不支持系统状态: ${systemStatesNotSupported.join(", ")}");
    }
    // 非AOAC机器
    if (false == aoacState) {
      if (systemStatesNotSupported.isEmpty) {
        Log("=> 当前固件支持常见系统状态!修复睡眠问题后,macOS可支持S3睡眠!");
      }
      if (systemStatesNotSupported.contains("_S3")) {
        Log.warning("=> 注意: 当前固件不支持 _S3 状态, 如果BIOS设置没有禁用 S3 功能, 那么机器不支持S3睡眠!");
      }
    } else if (true == aoacState) {
      // AOAC机器
      Log.warning("=> 注意: 当前是AOAC机器,macOS不支持S3睡眠!");
    } else {
      Log.warning("=> 当前未检测到是否是AOAC机器,请自行确认!");
      if (systemStatesNotSupported.isEmpty) {
        Log.warning(
          "=> 当前固件支持常见系统状态!如果不是AOAC机器,修复睡眠问题后,macOS可支持S3睡眠,反之不支持S3睡眠!",
        );
      }
    }
    Log("");
    return (systemStatesFound, systemStatesNotSupported);
  }

  Future<bool?> checkAOAC({String? facpPath}) async {
    final (valid, table) = await validateTableSignature(
      'FACP',
      tablePath: facpPath,
    );
    if (!valid) return null;
    Log("正在检查 Low Power S0 Idle (V5) 值…");
    List<String> lines = table['lines'] ?? [];
    final lowPower = findFacpField(lines, 'Low Power S0 Idle (V5) :');
    Log("获取到 Low Power S0 Idle (V5) : $lowPower");

    if (lowPower.isEmpty) {
      Log.warning("未找到 Low Power S0 Idle (V5) 值!");
      return null;
    }

    if (lowPower == '0') {
      Log("当前不是 AOAC 机器, 不影响macOS系统 S3 睡眠!");
    } else {
      Log.warning("当前是 AOAC 机器, macOS不支持 S3 睡眠!");
    }
    Log("");
    return lowPower == '1';
  }

  Future<void> ssdtS3Disable({bool prebuilt = false}) async =>
      prebuilt ? _ssdtS3DisablePrebuilt() : _ssdtS3Disable();

  Future<void> _ssdtS3Disable() async {
    if (!await ensureDSDT()) return;
    Log("正在检查是否存在 _S3...");
    String? externalLine;
    String ssdtBody = "";
    bool found = false;
    var sortedTables = sortedNicely(d.acpiTables.keys.toList());
    for (var tableName in sortedTables) {
      var table = d.acpiTables[tableName];
      Log("正在检查 $tableName…");
      final nameS3 = d.getNamePaths(obj: "_S3", table: table);
      final methodS3 = d.getMethodPaths(obj: "_S3", table: table);
      // 大多数都是 Name _S3
      if (nameS3.isNotEmpty && nameS3[0].isNotEmpty) {
        final target = nameS3[0].first;
        Log("=> 已在 $target 找到 Name _S3!");
        found = true;
        externalLine = 'External (XS3, IntObj)';
        ssdtBody = '''
            Method (_S3, 0, NotSerialized)
            {
                Return (XS3)
            }
    ''';
        break;
      } else if (methodS3.isNotEmpty && methodS3[0].isNotEmpty) {
        final target = methodS3[0].first;
        Log("=> 已在 $target 找到 Method _S3!");
        found = true;
        externalLine = 'External ($target, MethodObj)';
        ssdtBody = '''
            Method (_S3, 0, NotSerialized)
            {
                Return (XS3 ())
            }
    ''';
        break;
      } else {
        Log("=> 未找到 Name或Method _S3");
      }
    }
    if (!found) {
      Log.warning("=> 未找到 Name 或 Method _S3,当前配置不支持S3睡眠! 已终止操作!");
      return;
    }
    final String ssdtName = "SSDT-S3-Disable";
    Log("正在创建预编译 $ssdtName.dsl...");
    final ssdt =
        '''
    DefinitionBlock("", "SSDT", 2, "RAPID", "S3-OFF", 0x00000000)
    {
        $externalLine

        If (_OSI ("Darwin"))
        {
        }
        Else
        {
          $ssdtBody
        }
    }
    ''';

    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment":
          "Disable S3 System State for macOS - requires _S3 to XS3 rename",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    final patches = [
      {
        "Comment": "_S3 to XS3 rename - requires $ssdtName.aml",
        "Find": "5F53335F",
        "Replace": "5853335F",
      },
    ];
    makePlist(acpi: acpi, patches: patches, replace: true);
  }

  Future<void> _ssdtS3DisablePrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-S3-Disable";
    Log("正在创建预编译 $ssdtName.dsl...");
    final ssdt = Prebuilt.ssdtS3Disable;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Disable S3 Sleep Method for Darwin",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    final patches = [
      {
        "Comment": "_S3 to ZS3 rename - requires $ssdtName.aml",
        "Find": "5F53335F",
        "Replace": "5853335F",
      },
    ];
    makePlist(acpi: acpi, patches: patches, replace: true);
  }

  Future<void> ssdtLID({bool prebuilt = false}) async => _ssdtLID();

  Future<void> _ssdtLID() async {
    if (!await ensureDSDT()) return;
    String devicePath = "";
    List<dynamic> tts = [];
    bool foundMethodLID = false;
    var sortedTables = sortedNicely(d.acpiTables.keys.toList());
    for (var tableName in sortedTables) {
      var table = d.acpiTables[tableName];
      Log("正在检查 $tableName…");
      if (devicePath.isEmpty) {
        /// 根据设备ID: PNP0C0D 查找 LID 设备
        Log("正在查找 LID (PNP0C0D) 设备...");
        final device = d.getDevicePathsWithHid(hid: "PNP0C0D", table: table);
        if (device.isNotEmpty && device[0].isNotEmpty) {
          devicePath = device[0].first;
          Log("=> 已在 ${device[0].first} 找到 PNP0C0D 设备!");
        } else {
          Log("=> 未找到 LID (PNP0C0D) 设备!");
        }
      }
      if (!foundMethodLID) {
        // 开始检查是否存在_LID方法
        final methodLID = d.getMethodPaths(obj: "_LID", table: table);
        if (methodLID.isNotEmpty && methodLID[0].isNotEmpty) {
          foundMethodLID = true;
          Log("=> 已在 ${methodLID[0].first} 找到 Method _LID!");
        } else {
          Log("=> 未找到 Method _LID!");
        }
      }
      if (tts.isEmpty) {
        Log("正在检查是否存在 _TTS方法...");
        tts = d.getMethodInfo(obj: "_TTS", table: table);
        if (tts.isNotEmpty) {
          Log("=> 已找到 ${tts.first} 方法!");
        } else {
          Log("=> 未找到 _TTS 方法!");
          Log("正在检查是否存在 ZTTS 方法...");
          // 检查是否存在 ZTTS 方法
          final ztts = d.getMethodInfo(obj: "ZTTS");
          if (ztts.isNotEmpty) {
            Log.warning("=> 已找到 ${ztts.first} 方法!");
            Log.warning("=> 当前方法已经被重命名,可能非原始ACPI表!请重新获取原始ACPI表后再尝试!\n");
          } else {
            Log("=> 未找到 ZTTS 方法!");
          }
        }
      }
      if (tts.isNotEmpty) {
        Log("");
        break;
      }
    }
    if (devicePath.isEmpty) {
      Log.warning("=> 在上述ACPI表中均未找到 LID (PNP0C0D) 设备!已终止操作!\n");
      return;
    }
    if (!foundMethodLID) {
      Log.warning("=> 在上述ACPI表中均未找到 Method _LID!已终止操作!\n");
      return;
    }

    final helperDevice = getUniqueObjectName(
      '\\_SB',
      'RAPD',
      startingNumber: -1,
    ).name;
    if (helperDevice != 'RAPD') {
      Log("=> _SB.RAPD 已被占用，改用 _SB.$helperDevice。");
    }

    final ssdtName = "SSDT-LID";
    Log("正在创建 $ssdtName.dsl...");
    final ssdt =
        '''
DefinitionBlock("", "SSDT", 2, "RAPID", "LID", 0x00000000)
{
    External($devicePath, DeviceObj)
    External($devicePath.XLID, MethodObj)
    Scope (_SB)
    {
        Device ($helperDevice)
        {
            Name (_ADR, Zero)
            Name (FNOK, Zero)
            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (PLID, 1, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    If (Arg0 == 0x03)
                    {
                        \\_SB.$helperDevice.FNOK = One
                    }
                    Else
                    {
                        \\_SB.$helperDevice.FNOK = Zero
                    }
                }
            }

            Method (WLID, 1, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    \\_SB.$helperDevice.FNOK = Zero
                }
            }
        }
    }

    Scope ($devicePath)
    {
        Method (_LID, 0, NotSerialized)
        {
            If (_OSI ("Darwin"))
            {
                If (\\_SB.$helperDevice.FNOK == One)
                {
                    Return (Zero)
                }
                Else
                {
                    Return ($devicePath.XLID())
                }
            }
            Else
            {
                Return ($devicePath.XLID())
            }
        }
    }
}
''';

    if (!await writeSSDT(ssdtName, ssdt)) return;

    final acpi = {
      "Comment":
          "Spoof a PNP0C0E sleep button for macOS sleep and wake - requires _LID to XLID rename",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    final patches = [
      {
        "Comment": "_LID to XLID rename - requires $ssdtName.aml",
        "Find": "5F4C494400",
        "Replace": "584C494400",
      },
    ];
    await makePlist(acpi: acpi, patches: patches, replace: true);
  }

  Future<void> ssdtPWRB({bool prebuilt = false}) async =>
      prebuilt ? _ssdtPWRBPrebuilt() : _ssdtPWRB();

  Future<void> _ssdtPWRB() async {
    if (!await ensureDSDT()) return;
    String devicePath = "";
    var sortedTables = sortedNicely(d.acpiTables.keys.toList());
    for (var tableName in sortedTables) {
      var table = d.acpiTables[tableName];
      Log("正在检查 $tableName…");
      if (devicePath.isEmpty) {
        /// 根据设备ID: PNP0C0C 查找 PWRB 设备
        Log("正在查找 PWRB (PNP0C0C) 设备...");
        final device = d.getDevicePathsWithHid(hid: "PNP0C0C", table: table);
        if (device.isNotEmpty && device[0].isNotEmpty) {
          devicePath = device[0].first;
          Log.warning(
            "=> 无需仿冒PWRB设备,已在 ${device[0].first} 找到 PNP0C0C 设备! 已终止操作！\n",
          );
          return;
        } else {
          Log("=> 未找到 PWRB (PNP0C0C) 设备!");
        }
      }
    }
    if (devicePath.isEmpty) {
      Log.warning("=> 在上述ACPI表中均未找到 PWRB (PNP0C0C) 设备!仿冒一个即可！\n");
      _ssdtPWRBPrebuilt();
    }
  }

  void _ssdtPWRBPrebuilt() {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-PWRB";
    Log("正在创建预编译 $ssdtName.dsl...");
    final ssdt = Prebuilt.ssdtPWRB;
    writeSSDT(ssdtName, ssdt);

    final acpi = {
      "Comment": "Spoof a PNP0C0C power button for macOS sleep and wake",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  Future<void> ssdtSLPB({bool prebuilt = false}) async =>
      prebuilt ? await _ssdtSLPBPrebuilt() : await _ssdtSLPB();

  Future<void> _ssdtSLPB() async {
    if (!await ensureDSDT()) return;
    String devicePath = "";
    bool hasStaMethod = false;
    var sortedTables = sortedNicely(d.acpiTables.keys.toList());
    for (var tableName in sortedTables) {
      var table = d.acpiTables[tableName];
      Log("正在检查 $tableName…");
      if (devicePath.isEmpty) {
        /// 根据设备ID: PNP0C0E 查找 SLPB 设备
        Log("正在查找 SLPB (PNP0C0E) 设备...");
        final device = d.getDevicePathsWithHid(hid: "PNP0C0E", table: table);
        if (device.isNotEmpty &&
            device[0].isNotEmpty &&
            device[0].first.isNotEmpty) {
          devicePath = device[0].first;
          Log.warning("=> 无需仿冒SLPB设备,已在 $devicePath 找到 PNP0C0E 设备!");
          // 开始检查 PNP0C0E 设备是否存在 _STA 方法
          final staMethod = d.getMethodPaths(obj: "$devicePath._STA");
          if (staMethod.isNotEmpty) {
            Log.warning("=> PNP0C0E 设备 $devicePath 存在 _STA 方法!");
            hasStaMethod = true;
          } else {
            Log.warning("=> PNP0C0E 设备 $devicePath 不存在 _STA 方法!");
          }
          break;
        } else {
          Log("=> 未找到 SLPB (PNP0C0E) 设备!");
        }
      }
    }

    if (devicePath.isEmpty) {
      Log("=> 在上述ACPI表中均未找到 SLPB (PNP0C0E) 设备!仿冒一个即可！\n");
      _ssdtSLPBPrebuilt();
    } else {
      String ssdtName = "SSDT-SLPB";
      Log("正在创建 $ssdtName.sdl...");
      String ssdt = "";
      if (hasStaMethod) {
        ssdt =
            '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "SLPB", 0x00000000)
{
    External ($devicePath._STA, UnknownObj)

    Scope (\\)
    {
        If (_OSI ("Darwin"))
        {
            $devicePath._STA = 0x0B
        }
    }
}
    ''';
      } else {
        ssdt =
            '''
      DefinitionBlock("", "SSDT", 2, "RAPID", "SLPB", 0x00000000)
{
    Scope ($devicePath)
    {
       Method (_STA, 0, NotSerialized)
      {
                If (_OSI ("Darwin"))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
      }
    }
}
      ''';
      }

      final acpi = {
        "Comment": "Spoof a PNP0C0E sleep button for macOS sleep and wake",
        "Enabled": true,
        "Path": "$ssdtName.aml",
      };
      makePlist(acpi: acpi, replace: true);
      writeSSDT(ssdtName, ssdt);
    }
  }

  Future<void> _ssdtSLPBPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-SLPB";
    Log("正在创建预编译 $ssdtName.dsl...");
    final ssdt = Prebuilt.ssdtSLPB;
    writeSSDT(ssdtName, ssdt);

    final acpi = {
      "Comment": "Spoof a PNP0C0E sleep button for macOS sleep and wake",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  Future<void> ssdtMEM2({bool prebuilt = false}) async =>
      prebuilt ? await _ssdtMEM2Prebuilt() : await _ssdtMEM2();

  Future<void> _ssdtMEM2Prebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-MEM2";
    Log("正在创建预编译 $ssdtName.dsl...");
    final ssdt = Prebuilt.ssdtMEM2;
    writeSSDT(ssdtName, ssdt);

    final acpi = {
      "Comment": "Fixing IGPU issues and memory mapping",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  Future<void> _ssdtMEM2() async {
    if (!await ensureDSDT()) return;
    String devicePath = "";

    /// 设备ID: PNP0C01 查找 MEM2/RMEM/MEM/AMDN 常见设备
    List<String> posiaDevices = ["MEM2", "RMEM", "MEM", "AMDN"];
    var sortedTables = sortedNicely(d.acpiTables.keys.toList());
    for (var tableName in sortedTables) {
      var table = d.acpiTables[tableName];
      Log("正在检查 $tableName…");
      if (devicePath.isEmpty) {
        Log("正在查找 PNP0C01 设备...");
        final device = d.getDevicePathsWithHid(hid: "PNP0C01", table: table);
        if (device.isNotEmpty &&
            device[0].isNotEmpty &&
            posiaDevices.any((element) => device[0].first.contains(element))) {
          devicePath = device[0].first;
          Log.warning(
            "=> 无需仿冒MEM2设备,已在 ${device[0].first} 找到 PNP0C01 设备! 已终止操作！\n",
          );
          return;
        } else {
          Log("=> 未找到 PNP0C01 设备!");
        }
      }
    }

    if (devicePath.isEmpty) {
      Log("=> 在上述所有ACPI表中均未找到 PNP0C01 设备!\n");
      _ssdtMEM2Prebuilt();
    }
  }

  Future<void> ssdtFixShutdown({bool prebuilt = false}) async =>
      prebuilt ? await _ssdtFixShutdownPrebuilt() : await _ssdtFixShutdown();

  Future<void> _ssdtFixShutdownPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-FixShutdown";
    Log("正在创建预编译 $ssdtName.dsl...");
    final ssdt = Prebuilt.ssdtFixShutdown;
    if (!await writeSSDT(ssdtName, ssdt)) return;
    final acpi = {
      "Comment":
          "Fixing Shutdown for XHC Controllers - called by SSDT-SleepHook",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    await makePlist(acpi: acpi, replace: true);
  }

  /// SSDT-FixShutdown
  Future<void> _ssdtFixShutdown() async {
    if (!await ensureDSDT()) return;
    Log('正在收集 XHC/XHCI/XDCI/CNVW 设备...');
    var devices = [
      'XHCI',
      'XHC',
      'XHC0',
      'XHC1',
      'XHC2',
      'XHC3',
      'XHC4',
      'XDCI',
      'CNVW',
    ];
    var xhcis = [];
    for (var element in devices) {
      var xhciDevice = d.getDevicePaths(obj: element);
      if (xhciDevice.isNotEmpty &&
          xhciDevice[0].isNotEmpty &&
          xhciDevice[0][0].isNotEmpty) {
        Log('=> 正在检查 ${xhciDevice[0][0]} 设备是否支持 PMEE...');
        final fieldLines = getFieldVarWithPath(xhciDevice[0][0]);
        bool hasPMEE = fieldLines.any((line) => line.contains('PMEE'));
        if (!hasPMEE) {
          Log('=> ${xhciDevice[0][0]} 不支持 PMEE，已跳过');
          continue;
        } else {
          Log('=> ${xhciDevice[0][0]} 支持 PMEE');
          xhcis.add(xhciDevice[0][0]);
        }
      }
    }
    if (xhcis.isEmpty) {
      Log.warning('=> 未找到任何符合条件的 XHC/XHCI/XDCI/CNVW 设备！已终止操作！\n');
      return;
    }

    Log('');
    final String ssdtName = "SSDT-FixShutdown";
    Log("正在创建预编译 $ssdtName.dsl...");

    String ssdt = """
  /* Powers down the USB controller which is needed for proper shutdown.
 * When done incorrectly, macOS will not power down USB as it needs an
 * explicit call for S5 for proper shutdown procedure.
 * Do note this SSDT is called by SSDT-SleepHook from the unified _PTS hook.
 * Source for SSDT: Rehabman
 */

DefinitionBlock ("", "SSDT", 2, "RAPID", "PFSH", 0x00000000)
{
  """;

    for (String basePath in xhcis) {
      ssdt += '    External ($basePath.PMEE, FieldUnitObj)\n';
    }
    ssdt += '\n';

    ssdt += '''
    Method (PFSH, 1, NotSerialized)
    {
        If ((0x05 == Arg0))
        {  
            If (_OSI ("Darwin"))
              {
    ''';

    for (String basePath in xhcis) {
      ssdt += '            $basePath.PMEE = Zero \n';
    }

    ssdt += """
            }
        }
}
""";

    ssdt += "\n}\n";

    if (!await writeSSDT(ssdtName, ssdt)) return;
    final acpi = {
      "Comment":
          "Fixing Shutdown for XHC Controllers - called by SSDT-SleepHook",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    await makePlist(acpi: acpi, replace: true);
  }

  Future<void> ssdtGPRW({bool prebuilt = true}) async =>
      prebuilt ? await _ssdtGPRWPrebuilt() : await _ssdtGPRW();

  int _rawOccurrenceCount(dynamic raw, List<int> needle) {
    if (raw is! List || needle.isEmpty || raw.length < needle.length) return 0;

    var count = 0;
    for (var i = 0; i <= raw.length - needle.length;) {
      var matches = true;
      for (var j = 0; j < needle.length; j++) {
        if (raw[i + j] != needle[j]) {
          matches = false;
          break;
        }
      }
      if (matches) {
        count++;
        i += needle.length;
      } else {
        i++;
      }
    }
    return count;
  }

  bool _isTargetPrwPackage(Map<String, dynamic> table, int line) {
    if (line < 0) return false;

    final scope = d
        .getScope(
          startingIndex: line,
          stripComments: true,
          table: table,
        )
        .join(' ');
    final match = RegExp(
      r'Package\s*\([^\)]*\)\s*\{\s*(0x[0-9A-F]+|[0-9]+)\s*,\s*(0x[0-9A-F]+|[0-9]+)\b',
      caseSensitive: false,
    ).firstMatch(scope);
    if (match == null) return false;

    int? parseInteger(String? value) {
      if (value == null) return null;
      final text = value.trim();
      final hexadecimal = text.toLowerCase().startsWith('0x');
      return int.tryParse(
        hexadecimal ? text.substring(2) : text,
        radix: hexadecimal ? 16 : 10,
      );
    }

    return parseInteger(match.group(1)) == 0x6D &&
        parseInteger(match.group(2)) == 0x04;
  }

  Future<void> _ssdtGPRW() async {
    if (!await ensureDSDT()) return;

    const prwPackageHex = '1206020A6D0A04';
    const patchedPrwPackageHex = '1206020A6D0A00';
    final tableNames = sortedNicely(d.acpiTables.keys.toList());
    String gprwPath = '';
    var hasXprw = false;
    for (final tableName in tableNames) {
      final table = d.acpiTables[tableName]!;
      if (gprwPath.isEmpty) {
        final methods = d.getMethodPaths(obj: 'GPRW', table: table);
        if (methods.isNotEmpty) gprwPath = methods.first[0].toString();
      }
      if (!hasXprw) {
        hasXprw = d.getMethodPaths(obj: 'XPRW', table: table).isNotEmpty;
      }
    }

    Log('正在检查是否存在 GPRW 方法...');
    if (gprwPath.isNotEmpty) {
      Log('=> 已在 $gprwPath 找到 GPRW 方法！');
      await _ssdtGPRWPrebuilt();
      return;
    }

    Log.warning('=> 未找到 GPRW 方法，正在检查直接定义的 _PRW Package...');
    if (hasXprw) {
      Log.warning('=> 已找到 XPRW 方法，当前 ACPI 可能已被修改；仍将按实际 _PRW 内容继续检查。');
    }

    final targetBytes = util.getHexBytes(prwPackageHex);
    var totalRawOccurrences = 0;
    for (final tableName in tableNames) {
      totalRawOccurrences += _rawOccurrenceCount(
        d.acpiTables[tableName]!['raw'],
        targetBytes,
      );
    }

    final patches = <Map<String, dynamic>>[];
    final patchKeys = <String>{};
    for (final tableName in tableNames) {
      final table = d.acpiTables[tableName]!;
      if (_rawOccurrenceCount(table['raw'], targetBytes) == 0) continue;

      final prwObjects = <List<dynamic>>[
        ...d.getNamePaths(obj: '_PRW', table: table),
        ...d.getMethodPaths(obj: '_PRW', table: table),
      ];
      for (final object in prwObjects) {
        final objectLine = object[1] as int;
        if (!_isTargetPrwPackage(table, objectLine)) continue;

        var find = prwPackageHex;
        var replace = patchedPrwPackageHex;
        if (totalRawOccurrences > 1) {
          try {
            final hexLine = d.findNextHex(index: objectLine, table: table).$2;
            final (leftPad, rightPad) = d.getShortestUniquePad(
              currentHex: prwPackageHex,
              index: hexLine,
              table: table,
            );
            find = leftPad + prwPackageHex + rightPad;
            replace = leftPad + patchedPrwPackageHex + rightPad;
          } catch (_) {
            Log.warning(
              '=> $tableName 中 ${object[0]} 的目标字节不是唯一值，无法安全定位，已跳过。',
            );
            continue;
          }
        }

        final key = '$tableName:$find';
        if (!patchKeys.add(key)) continue;
        patches.add({
          'Comment': 'Instant Wake Fix (_PRW 0x6D, 0x04 to 0)',
          'Find': find,
          'Replace': replace,
        });
        Log('=> 已在 $tableName 的 ${object[0]} 找到目标 _PRW Package。');
        Log('           Find: $find');
        Log('     Replace: $replace');
      }
    }

    if (patches.isEmpty) {
      Log.warning(
        '=> 未找到可安全修复的 _PRW Package (0x6D, 0x04)，不生成 SSDT-GPRW 或二进制补丁。',
      );
      return;
    }

    await makePlist(patches: patches, replace: true);
    Log('=> 已生成 ${patches.length} 个 _PRW 即时唤醒修复补丁；此场景不需要 SSDT-GPRW。');
  }

  /// SSDT-GPRW
  Future<void> _ssdtGPRWPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-GPRW";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtGPRW;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Fixing instant awake - requires GPRW to XPRW rename",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    final patches = [
      {
        "Comment": "GPRW to XPRW rename - requires $ssdtName.aml",
        "Find": "4750525702",
        "Replace": "5850525702",
      },
    ];
    makePlist(acpi: acpi, patches: patches, replace: true);
  }

  Future<void> ssdtUPRW({bool prebuilt = true}) async =>
      prebuilt ? await _ssdtUPRWPrebuilt() : await _ssdtUPRW();

  Future<void> _ssdtUPRW() async {
    if (!await ensureDSDT()) return;
    // 检查是否存在 UPRW 方法
    Log('正在检查是否存在 UPRW 方法...');
    var uprw = d.getMethodPaths(obj: 'UPRW');
    if (uprw.isEmpty) {
      Log.warning('=> 未找到 UPRW 方法！');
      // 检查是否存在 XPRW 方法
      Log('正在检查是否存在 XPRW 方法...');
      var xprw = d.getMethodPaths(obj: 'XPRW');
      if (xprw.isNotEmpty) {
        Log.warning('=> 已找到 XPRW 方法！当前方法已经被重命名,可能非原始ACPI表!请重新获取原始ACPI表后再尝试!\n');
        return;
      } else {
        Log.warning('=> 未找到 XPRW 方法！已终止操作！');
      }
    }
    if (uprw.isNotEmpty) {
      Log('=> 已在 ${uprw[0][0]} 找到 UPRW 方法！');
      _ssdtUPRWPrebuilt();
    }
  }

  /// SSDT-UPRW
  Future<void> _ssdtUPRWPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-UPRW";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtUPRW;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Fixing instant awake - requires UPRW to XPRW rename",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    final patches = [
      {
        "Comment": "UPRW to XPRW rename - requires $ssdtName.aml",
        "Find": "5550525702",
        "Replace": "5850525702",
      },
    ];
    makePlist(acpi: acpi, patches: patches, replace: true);
  }

  Future<void> ssdtGPI0({bool prebuilt = true}) async =>
      prebuilt ? await _ssdtGPI0Prebuilt() : await _ssdtGPI0();

  Future<void> _ssdtGPI0() async {
    if (!await ensureDSDT()) return;
    Log("正在检查是否存在 GPI0 设备...");
    var gpi0s = d.getDevicePaths(obj: "GPI0");
    if (gpi0s.isEmpty || gpi0s[0].isEmpty) {
      Log.warning('=> 未找到 GPI0 设备！已终止操作！\n');
      return;
    }
    Log('=> 已在 ${gpi0s[0].first} 找到 GPI0 设备！');

    // 检查 GPI0 是否存在 _STA 方法
    Log("正在检查是否存在 _STA 方法...");
    final gpioPath = gpi0s[0][0];
    final staMethod = d.getMethodPaths(obj: "$gpioPath._STA");
    if (staMethod.isEmpty) {
      Log.warning('=> 未找到 _STA 方法！已终止操作！\n');
      return;
    }

    final staIndex = d.findNextHex(index: staMethod[0][1]).$2;
    Log("=> 在索引 $staIndex 找到 ${gpioPath.split('.').last}: _STA 方法!");
    Log("=> 生成 ${gpioPath.split('.').last}: _STA 到 XSTA 的补丁");

    List<Map<String, dynamic>> patches = [];
    const staHex = "5F535441"; // _STA
    const xstaHex = "58535441"; // XSTA
    final (padl, padr) = d.getShortestUniquePad(
      currentHex: staHex,
      index: staIndex,
    );
    final String ssdtName = "SSDT-GPI0";
    Log("");
    Log("           Find: ${padl + staHex + padr}");
    Log("     Replace: ${padl + xstaHex + padr}");
    Log("");

    patches.add({
      "Comment":
          "${gpioPath.split('.').last} _STA to XSTA - requires $ssdtName.aml",
      "Find": padl + staHex + padr,
      "Replace": padl + xstaHex + padr,
    });
    String devName = gpioPath
        .replaceAll(RegExp(r'_+$'), '')
        .replaceAll('_SB_', '\\_SB');
    String ssdt =
        '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "GPI0", 0x00000000)
{
  
   External ($devName, DeviceObj)
   External ($devName.XSTA, MethodObj)
    Scope ($devName)
    {
        Method (_STA, 0, NotSerialized)
           {
              If (_OSI ("Darwin"))
              {
                 Return (0x0F)
              }
             Return ($devName.XSTA())
           }
    }
}     
''';

    writeSSDT(ssdtName, ssdt);

    final acpi = {
      "Comment":
          "Enable GPI0 device for I2C TouchPads - requires _STA to XSTA rename",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, patches: patches, replace: true);
  }

  /// SSDT-GPI0
  Future<void> _ssdtGPI0Prebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-GPI0";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtGPI0;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Enable GPI0 device for a I2C TouchPads",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  /// SSDT-CPUR
  Future<void> ssdtCPUR({bool prebuilt = true}) async =>
      prebuilt ? _ssdtCPURPrebuilt() : _ssdtCPUR();

  /// SSDT-CPUR for AMD Ryzen
  Future<void> _ssdtCPUR() async {
    if (!await ensureDSDT()) return;
    Log("正在确定 CPU 命名方案…");
    bool found = false;
    for (var tableName in sortedNicely(d.acpiTables.keys.toList())) {
      var ssdtName = "SSDT-CPUR";
      var table = d.acpiTables[tableName];

      if (!(table["signature"]?.toLowerCase() == "dsdt" ||
          table["signature"]?.toLowerCase() == "ssdt")) {
        /// 不检查数据表格,继续
        continue;
      }

      Log("正在检查 $tableName…");

      List<List<dynamic>>? cpuName;
      try {
        cpuName = d.getProcessorPaths(table: table)[0][0];
      } catch (e) {
        cpuName = null;
      }

      if (cpuName != null && cpuName.isNotEmpty) {
        Log("=> 已找到 Processor 处理器：$cpuName");
        Log.warning("=> 当前Processor处理器命名方案符合CPU命名规范!无需此SSDT!已终止操作!");
        return;
      } else {
        // 如果没有找到处理器对象，继续检查 ACPI0007 设备
        Log("=> 未找到任何 Processor 对象…");
        var procs = d.getDevicePathsWithHid(hid: "ACPI0007", table: table);
        if (procs.isEmpty) {
          Log("=> 未找到 ACPI0007 设备…");
          continue;
        }

        Log("=> 已找到 ${procs.length} 个 ACPI0007 设备");
        found = true;
        // 分析 procs[0][0].split(".") 分割后判断是否存在PLTF设备
        if (!procs[0][0].split(".").contains("PLTF")) {
          Log.warning("=> 不存在 PLTF 设备,当前Intel平台不需要此SSDT!已终止操作…");
          return;
        }
        var parent = procs[0][0].split(".")[0];
        Log("=> 在 $parent 找到父设备，正在处理…");
        var procList = <Map<String, String>>[];
        for (var proc in procs) {
          Log("=> 正在检查 ${proc[0].split('.').last}…");

          var uid = d.getPathOfType(
            objType: "Name",
            obj: "${proc[0]}._UID",
            table: table,
          );
          if (uid.isEmpty) {
            Log("=> 未找到！跳过…");
            continue;
          }

          try {
            var uid0 = table["lines"][uid[0][1]]
                .split("_UID, ")[1]
                .split(")")[0];
            Log("=> UID: $uid0");
            procList.add({"proc": proc[0], "uid": uid0});
          } catch (e) {
            Log("=> 未找到！跳过…");
          }
        }

        if (procList.isEmpty) {
          continue;
        }

        Log("正在处理 ${procList.length} 个有效的处理器设备…");

        var ssdt = """
DefinitionBlock ("", "SSDT", 2, "RAPID", "CPUR", 0x00003000)
{
""";

        for (var i = 0; i < procList.length; i++) {
          var procUid = procList[i];
          var proc = procUid["proc"];
          ssdt += "External ($proc, DeviceObj)";
        }

        ssdt += """
    Scope (\\_SB)
    {""";

        // 遍历处理器对象并将其添加到 SSDT 中
        for (var i = 0; i < procList.length; i++) {
          var procUid = procList[i];
          var proc = procUid["proc"];
          var uid = procUid["uid"];
          var adr = (i).toRadixString(16).toUpperCase();
          var name = "PR00".substring(0, 4 - adr.length) + adr;

          ssdt +=
              """
        Processor ([[name]], [[uid]], 0x00000810, 0x06)
        {
            
             Return ($proc)
            
            """
                  .replaceAll(r"[[name]]", name)
                  .replaceAll(r"[[uid]]", uid ?? '')
                  .replaceAll(r"[[proc]]", proc ?? '');

          ssdt += """
        }""";
        }
        ssdt += """
    }
}""";

        final acpi = {
          "Comment": "B850,B650,B550,A520 Chipset Required",
          "Enabled": true,
          "Path": "$ssdtName.aml",
        };

        makePlist(acpi: acpi);
        writeSSDT(ssdtName, ssdt);
        return;
      }
    }
    if (!found) {
      Log.warning("=> 未发现符合要求的 CPU 设备,无需 SSDT-CPUR 补丁!已终止操作!");
    }
  }

  /// SSDT-CPUR 预编译文件
  Future<void> _ssdtCPURPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-CPUR";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtCPUR;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "B850,B650,B550,A520 Chipset Required",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  /// 生成SSDT-EC相关预编译文件
  /// [isLaptop] 是否为笔记本电脑（决定使用桌面还是笔记本版本）
  /// [injectUSBPower] 是否注入USB电源属性（决定是否包含USBX）
  Future<void> _ssdtECPrebuilt({
    bool isLaptop = false,
    bool injectUSBPower = false,
  }) async {
    // 检查工具是否可用
    if (!checkIasl()) return;
    // 根据参数确定文件名和内容
    late String fileName;
    late String ssdtContent;
    late String comment;

    if (injectUSBPower) {
      // 注入USB电源属性时：包含USBX标识
      if (isLaptop) {
        fileName = "SSDT-EC-USBX-LAPTOP";
        ssdtContent = Prebuilt.ssdtECUSBXLaptop;
        comment = "Fake EC on laptop systems with USB power property support";
      } else {
        fileName = "SSDT-EC-USBX-DESKTOP";
        ssdtContent = Prebuilt.ssdtECUSBXDesktop;
        comment =
            "Enable EC on desktop systems with USB power property support";
      }
    } else {
      // 不注入USB电源属性时：不含USBX标识
      if (isLaptop) {
        fileName = "SSDT-EC-LAPTOP";
        ssdtContent = Prebuilt.ssdtECLaptop;
        comment = "Fake EC for Laptop";
      } else {
        fileName = "SSDT-EC-DESKTOP";
        ssdtContent = Prebuilt.ssdtECDesktop;
        comment = "Enable EC for Desktop";
      }
    }

    Log("正在创建预编译 $fileName.dsl...");
    writeSSDT(fileName, ssdtContent);

    final acpi = {"Comment": comment, "Enabled": true, "Path": "$fileName.aml"};
    makePlist(acpi: acpi, replace: true);
  }

  /// SSDT-PLUG
  Future<void> _ssdtPLUGPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-PLUG";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtPLUG;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment":
          "Fixing Intel CPU power management for Intel 4th to 11th generation",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  /// SSDT-PLUG-ALT
  Future<void> _ssdtPLUGALTPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-PLUG-ALT";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtPLUGALT;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment":
          "Fixing Intel CPU power management for Intel 12th generation and newer",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  /// SSDT-AWAC
  /// 生成SSDT-AWAC预编译文件
  Future<void> _ssdtAWACPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-AWAC";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtAWAC;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Fixing Incompatible AWAC for intel 8th generation and newer",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  /// SSDT-PMC
  Future<void> _ssdtPMCPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-PMC";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtPMC;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Native 300-series NVRAM support",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  /// SSDT-PNLF
  Future<void> _ssdtPNLFPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-PNLF";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtPNLF;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Defines PNLF device for backlight control",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  /// SSDT-IMEI
  Future<void> _ssdtIMEIPrebuilt({String? fakeid}) async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-IMEI";
    Log("正在创建预编译 $ssdtName.dsl...");
    Log("正在收集仿冒device-id方案…");
    String ssdt = Prebuilt.ssdtIMEIFakeId;
    if (fakeid?.toUpperCase() == '3A1E') {
      Log("=> 仿冒为7系主板IMEI (device-id: $fakeid),以匹配第3代 Ivy Bridge处理器");
    } else if (fakeid?.toUpperCase() == '3A1C') {
      Log("=> 仿冒为6系主板IMEI (device-id: $fakeid),以匹配第2代Sandy Bridge处理器");
    } else {
      Log.warning("=> 未启用 SSDT 仿冒 IMEI，必须通过 DeviceProperties 设置 device-id!");
      ssdt = Prebuilt.ssdtIMEI;
    }
    ssdt = ssdt.replaceAll(
      '[[FAKEID]]',
      (fakeid != null && fakeid.isNotEmpty)
          ? fakeid.substring(fakeid.length - 1)
          : '',
    );
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment":
          "Adds missing IMEI device to fix Ivy Bridge and Sandy Bridge graphics",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  /// SSDT-ALS0
  Future<void> _ssdtALS0Prebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-ALS0";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtALS0;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Faked Ambient Light Sensor",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  /// SSDT-XOSI
  Future<void> _ssdtXOSIPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-XOSI";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtXOSI;
    final patches = [
      {
        "Comment": "_OSI to XOSI rename - requires $ssdtName.aml",
        "Find": "5F4F5349",
        "Replace": "584F5349",
      },
    ];
    final acpi = {
      "Comment": "_OSI override - requires _OSI to XOSI rename",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, patches: patches, replace: true);
    writeSSDT(ssdtName, ssdt);
  }

  Future<void> _ssdtRHUBPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-RHUB";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtRHUB;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Disable RHUB",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  Future<void> _ssdtRTC0RANGEPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-RTC0-RANGE";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtRTC0RANGE;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Fixing RTC Range",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  /// 仿冒有线网卡，适用于无有线网卡的笔记本
  Future<void> ssdtRMNE() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-RMNE";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtRMNE;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Fake Ethernet Device for NullEthernet",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  Future<void> ssdtPCIDISABLE({
    String? acpiPath,
    String? pciPath,
    String? disableMethod,
    String? type,
  }) async => await _ssdtPCIDISABLE(
    acpiPath: acpiPath ?? pciPath,
    disableMethod: disableMethod ?? 'OFF',
    type: type ?? 'GPU',
  );

  /// 屏蔽 PCI 设备/
  /// [acpiPath] 设备 ACPI 路径
  /// [disableMethod] 屏蔽方法（支持 "OFF" / "PS3" / "IOName"）
  /// [type] 设备类型
  Future<void> _ssdtPCIDISABLE({
    String? acpiPath,
    required String disableMethod,
    required String type,
  }) async {
    if (!checkIasl()) return;

    if (acpiPath == null || !util.checkACPIPath(acpiPath: acpiPath)) {
      Log.warning('未提供有效 ACPI 设备路径! 已终止操作!');
      return;
    }

    var pciPath = acpiPath;
    bool sureDsdtOrACPI = d.acpiTables.isNotEmpty;
    bool foundMethod = false;
    bool needBridge = false;
    bool adrOverflow = false;

    if (sureDsdtOrACPI) {
      if (disableMethod == 'OFF') {
        Log('正在检查设备 $pciPath 是否存在 _ON 或 _OFF 方法...');
        foundMethod = _hasMethodInTables(pciPath, ['_ON', '_OFF']);
        if (!foundMethod) {
          Log.warning('在 DSDT 或 SSDT 中未找到 $pciPath 对应的 _ON 或 _OFF 方法! 已终止操作!');
          return;
        }
      } else if (disableMethod == 'PS3') {
        Log('正在检查设备 $pciPath 是否存在 _PS3 或 _DSM 方法...');
        foundMethod = _hasMethodInTables(pciPath, ['_PS3', '_DSM']);
        if (!foundMethod) {
          Log.warning('在 DSDT 或 SSDT 中未找到 $pciPath 对应的 _PS3 或 _DSM 方法! 已终止操作!');
          return;
        }
      } else if (disableMethod == 'IOName') {
        Log('正在检查设备 $pciPath...');
        // 检查显卡设备是否存在
        final (pPath, overflow) = acpiDevicePath(sanitizeAcpiPath(pciPath));
        if (pPath != null && pPath.isNotEmpty) {
          adrOverflow = overflow;
          // 检查 pciPath 是否存在 Method: _PRT
          foundMethod = _hasMethodInTables(pciPath, ['_PRT']);
          if (!foundMethod) {
            Log('=> 在 DSDT 或 SSDT 中未找到 $pciPath 对应的 _PRT 方法!');
            needBridge = false;
          } else {
            Log.warning("=> 设备 $pciPath 存在 _PRT 方法,可能已隐藏真实设备,将注入一个 BRG0 桥接设备!");
            needBridge = true;
          }
        } else {
          Log.warning("=> 设备 $pciPath 不存在!");
          return;
        }
      }
    }

    if (needBridge) {
      Log.warning("当前设备路径 $pciPath 可能隐藏真实设备!");
    }
    if (adrOverflow) {
      needBridge = true;
      Log.warning("=> 显卡设备 $pciPath 的 _ADR 地址存在溢出情况!");
      pciPath = pciPath.substring(0, pciPath.lastIndexOf("."));
      Log.warning("=> 回溯至父设备路径: $pciPath 并注入一个 BRG0 桥接设备!");
    }

    final ssdtName = "SSDT-$type-DISABLE-$disableMethod";
    Log('正在创建 $ssdtName.dsl...');
    Log('=> 需要屏蔽的 $type 设备路径:  $pciPath');
    Log('=> 屏蔽方法: $disableMethod 方法');

    // 确保是绝对路径
    if (!pciPath.startsWith('\\')) {
      pciPath = '\\$pciPath';
      Log('=> 设备相对路径已转换成绝对路径: $pciPath');
    }

    // 生成 SSDT 源代码
    final ssdt = switch (disableMethod) {
      String m when m.contains('OFF') => _buildSsdtOFF(pciPath, type),
      String m when m.contains('PS3') => _buildSsdtPS3(pciPath, type),
      String m when m.contains('IOName') => _buildSsdtIOName(
        pciPath,
        type,
        needBridge: needBridge,
      ),
      _ => '',
    };

    if (ssdt.isEmpty) {
      Log.warning('未知的屏蔽方法: $disableMethod，操作已终止。');
      return;
    }

    final acpi = {
      "Comment": "$type disabled via $disableMethod method",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };

    makePlist(acpi: acpi, replace: true);
    await writeSSDT(ssdtName, ssdt);
  }

  /// OFF 方法
  String _buildSsdtOFF(String pciPath, String type) =>
      '''
/* Based off of RehabMan's SSDT-DDGPU.dsl */
DefinitionBlock("", "SSDT", 2, "RAPID", "OFF", 0)
{
    External($pciPath._OFF, MethodObj)

    Device(RMD1)
    {
        Name(_HID, "RMD10000")
        Method(_STA, 0, NotSerialized)
        {
            If (_OSI("Darwin")) { Return (0x0F) } Else { Return (Zero) }
        }

        Method(_INI)
        {
            If (_OSI("Darwin"))
            {
                // disable discrete GPU if present
                If (CondRefOf($pciPath._OFF)) { $pciPath._OFF() }
            }
        }
    }
}
''';

  /// PS3 方法
  String _buildSsdtPS3(String pciPath, String type) =>
      '''
DefinitionBlock("", "SSDT", 2, "RAPID", "PS3", 0)
{
    External($pciPath._DSM, MethodObj)
    External($pciPath._PS3, MethodObj)

    Device(NHG1)
    {
        Name(_HID, "NHG10000")
        Method(_STA, 0, NotSerialized)
        {
            If (_OSI("Darwin")) { Return (0x0F) } Else { Return (Zero) }
        }

        Method(_INI, 0, NotSerialized)
        {
            If (_OSI("Darwin"))
            {
                If (LAnd(CondRefOf($pciPath._DSM), CondRefOf($pciPath._PS3)))
                {
                    $pciPath._DSM(ToUUID("a486d8f8-0bda-471b-a72b-6042a6b5bee0"), 0x0100, 0x1A, Buffer(0x04) { 0x01,0x00,0x00,0x03 })
                    $pciPath._PS3()
                }
            }
        }
    }
}
''';

  /// IOName 方法
  String _buildSsdtIOName(
    String pciPath,
    String type, {
    bool needBridge = false,
  }) {
    final typeLower = type.toLowerCase();
    final ioName = switch (typeLower) {
      'gpu' => '#display',
      'nvme' => '#storage',
      'pcie' => '#pcie',
      _ => '#device',
    };

    // _DSM 方法内容
    final dsmMethod =
        '''
    Method (_DSM, 4, NotSerialized)
    {
        If ((!Arg2 || !_OSI ("Darwin")))
        {
            Return (Buffer (One)
            {
                 0x03
            })
        }

        Return (Package (0x0A)
        {
            "name", 
            Buffer (0x09)
            {
                "$ioName"
            }, 

            "IOName", 
            "$ioName", 
            "class-code", 
            Buffer (0x04)
            {
                 0xFF, 0xFF, 0xFF, 0xFF
            }, 

            "vendor-id", 
            Buffer (0x04)
            {
                 0xFF, 0xFF, 0x00, 0x00
            }, 

            "device-id", 
            Buffer (0x04)
            {
                 0xFF, 0xFF, 0x00, 0x00
            }
        })
    }
  ''';

    // 生成桥设备结构
    final bridgeBody =
        '''
    Scope ($pciPath)
    {
        Device (BRG0)
        {
            Name (_ADR, Zero)
            $dsmMethod
        }
    }
  ''';

    final normalBody =
        '''
    Scope($pciPath)
    {
       $dsmMethod
    }
  ''';

    return '''
    DefinitionBlock ("", "SSDT", 2, "RAPID", "IOName", 0x00000000)
    {
        External ($pciPath, DeviceObj)
    ${needBridge ? bridgeBody : normalBody}
    }
  ''';
  }

  /// 检查 ACPI 表中是否存在指定方法
  /// [pciPath] 设备PCI地址
  /// [methods] 要检查的方法列表
  bool _hasMethodInTables(String pciPath, List<String> methods) {
    final normalizedPath = pciPath.replaceAll('\\', '');
    final foundSet = <String>{};
    for (final tableName in sortedNicely(d.acpiTables.keys.toList())) {
      final table = d.acpiTables[tableName];

      for (final method in methods) {
        final paths = d.getMethodPaths(obj: method, table: table);
        final hasMethod = paths.any(
          (e) =>
              e[0].replaceAll('.$method', '').replaceAll('\\', '') ==
              normalizedPath,
        );

        if (hasMethod) {
          foundSet.add(method);
          Log("=> 在 $tableName 中找到 $pciPath.$method 方法");
        }
        if (foundSet.length == methods.length) {
          // 所有方法都已找到
          return true;
        }
      }
    }

    // 如果只找到部分，打印提示
    if (foundSet.isNotEmpty) {
      final missing = methods.where((m) => !foundSet.contains(m)).join(', ');
      Log.warning('部分方法未找到: $missing');
    }

    return false;
  }

  /// Battery Hotpatch（参考 RehabMan 的 EC 读电池方案）
  Future<void> ssdtBAT() async {
    try {
      await _ssdtBAT();
    } on StateError catch (error) {
      Log.error("SSDT-BAT 生成失败：${error.message}");
    }
  }

  Future<void> _ssdtBAT() async {
    if (!await ensureDSDT()) return;

    _batteryBodyExternals.clear();
    _batteryRegionWarnings.clear();
    _batteryNamespaceObjects = BatteryNamespaceResolver.collectObjects(
      d.acpiTables.values,
      detectNameType: d.detectNameType,
    );

    // 根据是否存在B1B2电池方法，简单判断是否已经补丁
    final batteryMethodB1B2 = d.getMethodPaths(obj: "B1B2");
    if (batteryMethodB1B2.isNotEmpty) {
      Log.warning("检测到 B1B2 电池宽字节(超过8字节)读取方法,当前DSDT可能已经打过补丁,请提取原始ACPI表再尝试!");
      return;
    }
    // 根据是否存在B1B4电池方法，简单判断是否已经补丁
    final batteryMethodB1B4 = d.getMethodPaths(obj: "B1B4");
    if (batteryMethodB1B4.isNotEmpty) {
      Log.warning("检测到 B1B4 电池宽字节(超过8字节)读取方法,当前DSDT可能已经打过补丁,请提取原始ACPI表再尝试!");
      return;
    }

    Log("正在分析电池设备（PNP0C0A）…");
    await Log.yieldToUi();
    // 1. 查找所有符合条件的电池设备
    final batteryDevices = _findBatteryDevices();
    if (batteryDevices.isEmpty) {
      Log.warning("=> 未找到可用于热补丁的电池设备（需包含 _STA/_BST/_BIX 或 _BIF）");
      return;
    }

    // 2.查找所有EC设备
    Log("正在分析EC设备（PNP0C09）…");
    await Log.yieldToUi();
    final ecDevices = _findECDevices();
    if (ecDevices.isEmpty) {
      Log.warning("=> 未找到EC设备,已终止操作！");
      return;
    }
    _batteryNamespaceObjects = BatteryNamespaceResolver.mergeDeviceObjects(
      existing: _batteryNamespaceObjects,
      devices: [...batteryDevices, ...ecDevices],
    );

    // 3.判断单电池/多电池，并构建依赖表T
    final batteryMethods = <String>{"_STA", "_BST", "_BIF", "_BIX", "_BTP"};
    final isMultiBattery = batteryDevices.length > 1;
    if (!isMultiBattery && batteryDevices.first["usesSystemMemory"] == true) {
      Log(
        "=> ${batteryDevices.first['path']} 使用 SystemMemory OperationRegion，将按动态/静态基址生成内存访问辅助方法。",
      );
    }
    if (isMultiBattery) {
      final parentScopes = batteryDevices
          .map((battery) => (battery['scope'] ?? '').toString().toUpperCase())
          .toSet();
      if (parentScopes.length != 1) {
        Log.warning('=> 多个电池不在同一父作用域，无法创建单一 BATC 逻辑设备。');
        return;
      }
      bool hasMethod(Map<String, dynamic> battery, String name) {
        final methods = battery['methods'] as List<dynamic>? ?? const [];
        return methods.any(
          (method) => (method['name'] ?? '').toString().toUpperCase() == name,
        );
      }

      final allBif = batteryDevices.every(
        (battery) => hasMethod(battery, '_BIF'),
      );
      final allBix = batteryDevices.every(
        (battery) => hasMethod(battery, '_BIX'),
      );
      if (!allBif && !allBix) {
        Log.warning('=> 多个电池未提供一致的 _BIX 或 _BIF 接口，无法安全合并包结构。');
        return;
      }
    }

    Log(isMultiBattery ? "正在分析多电池依赖..." : "正在分析单电池依赖...");
    await Log.yieldToUi();
    final (
      dependencyTable,
      relatedMethods,
      relatedFields,
      usedMutexNames,
    ) = _buildBatteryDependencyTable(
      batteryDevices: batteryDevices,
      ecDevices: ecDevices,
      entryMethods: batteryMethods,
      includeAllReachableMethods: isMultiBattery,
    );
    await _logBatteryDependencyTable(dependencyTable);

    if (dependencyTable.isEmpty) {
      Log.warning("=> 电池依赖表T为空,已终止操作!");
      return;
    }

    if (relatedFields.isNotEmpty) {
      Log("=> 电池依赖方法中检测到 ${relatedFields.length} 个宽字节(超过8字节)字段:");
      for (final field in relatedFields.values) {
        final name = field["name"] as String;
        final bitLen = field["bitLength"] as int;
        final byteLen = field["byteLength"] as int;
        final off =
            (field["originOffset"] as int? ?? 0) +
            (field["offset"] as int? ?? 0);
        final rawSpace = (field["regionSpace"] ?? "").toString();
        final space = rawSpace.isEmpty ? "EmbeddedControl" : rawSpace;
        Log(
          "   $name: ${bitLen}bit, ${byteLen}B, $space@${util.hexy(off, padTo: 2)}",
        );
      }
    } else {
      Log("=> 电池依赖方法中未检测到宽字节(超过8字节)字段!");
      if (!isMultiBattery) {
        Log("=> 单电池无需热补丁!已终止操作!");
        return;
      }
    }

    // 依赖方法检测 Symbol（用于 External 与 Mutex patch 等）
    Log("正在分析电池依赖方法...");
    final relatedMethodTexts = relatedMethods.values
        .expand(_relatedMethodOrigins)
        .map((e) => (e["text"] ?? "").toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final usedSymbols = _extractUsedSymbols(relatedMethodTexts);
    // 提取所有方法中使用的所有符号
    debugPrint("=> 所有方法中使用的符号: $usedSymbols");
    await Log.yieldToUi();

    // 4. 处理多电池情况
    if (batteryDevices.length > 1) {
      await _handleMultiBatteryCase(
        batteryDevices: batteryDevices,
        ecDevices: ecDevices,
        usedSymbols: usedSymbols,
        relatedMethods: relatedMethods,
        usedFields: relatedFields.values.toList(),
        usedMutexNames: usedMutexNames,
        ssdtName: "SSDT-BATC",
      );
    }
    // 5. 处理单电池情况
    else if (batteryDevices.length == 1) {
      await _handleSingleBatteryCase(
        batteryDevice: batteryDevices.first,
        ecDevices: ecDevices,
        relatedMethods: relatedMethods,
        usedFields: relatedFields.values.toList(),
        usedSymbols: usedSymbols,
        usedMutexNames: usedMutexNames,
        ssdtName: "SSDT-BAT",
      );
    } else {
      Log.warning("=> 未找到电池设备（需包含 _STA/_BST/_BIX 或 _BIF）,已终止操作!");
    }
  }

  /// 解析 ACPI 整数字面量
  /// [raw] 原始字符串
  /// [defaultValue] 默认值
  int _parseAcpiIntegerLiteral(String raw, {int defaultValue = 0}) {
    return _tryParseAcpiIntegerLiteral(raw) ?? defaultValue;
  }

  int? _tryParseAcpiIntegerLiteral(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final lower = s.toLowerCase();
    if (lower == "zero") return 0;
    if (lower == "one") return 1;

    if (lower.startsWith("0x")) {
      return int.tryParse(lower.substring(2), radix: 16);
    }

    return int.tryParse(s);
  }

  /// 从 Scope 行中收集所有对象
  /// [lines] Scope 行
  /// [scopePath] Scope 路径
  /// [names] Name 对象列表
  /// [methods] Method 对象列表
  /// [operationRegions] OperationRegion 对象列表
  /// [scopeFields] ScopeField 对象列表
  void _collectScopeObjectsFromLines({
    required List<String> lines,
    required String scopePath,
    required List<Map<String, dynamic>> names,
    required List<Map<String, dynamic>> methods,
    required List<Map<String, dynamic>> operationRegions,
    required List<Map<String, dynamic>> scopeFields,
    required List<String> devices,
    required List<Map<String, dynamic>> mutexs,
    bool collectNestedFieldLayouts = false,
  }) {
    int depth = 0;

    // 找到 scope 起始
    int startIndex = lines.indexWhere((l) => l.contains("{"));
    if (startIndex == -1) {
      startIndex = 0;
      depth = 1;
    } else {
      startIndex++;
      depth = 1;
    }

    int findMatchingBrace(int fromIndex) {
      int b = 0;
      for (int j = fromIndex; j < lines.length; j++) {
        for (final ch in lines[j].split('')) {
          if (ch == '{') b++;
          if (ch == '}') {
            if (b == 0) return j;
            b--;
            if (b == 0) return j;
          }
        }
      }
      return lines.length - 1;
    }

    int findBlockEnd(int from) {
      int braceStart = from;
      while (braceStart < lines.length && !lines[braceStart].contains("{")) {
        braceStart++;
      }
      if (braceStart >= lines.length) return from;
      return findMatchingBrace(braceStart);
    }

    int i = startIndex;

    while (i < lines.length) {
      final raw = lines[i];
      final line = raw.trim();

      // ---------------- Device ----------------
      final deviceMatch = RegExp(
        r'^\s*Device\s*\(\s*([A-Za-z0-9_]+)\s*\)',
        caseSensitive: false,
      ).firstMatch(raw);

      if (deviceMatch != null && depth == 1) {
        devices.add(raw.trim());
        i = findBlockEnd(i) + 1;
        continue;
      }

      if (depth == 1 || collectNestedFieldLayouts) {
        // ---------------- Name ----------------
        if (depth == 1 && line.startsWith("Name (")) {
          final buffer = StringBuffer();
          int paren = 0;
          bool started = false;
          int t = i;

          for (; t < lines.length; t++) {
            final current = lines[t];
            buffer.writeln(current);
            for (final ch in current.split('')) {
              if (ch == '(') {
                paren++;
                started = true;
              } else if (ch == ')') {
                paren--;
              }
            }
            if (started && paren == 0) break;
          }

          final text = buffer.toString().trim();
          names.add({
            "text": text,
            "type": d.detectNameType(text),
            "name": line.split("(")[1].split(",")[0].trim().toUpperCase(),
            "scope": scopePath,
          });

          i = t + 1;
          continue;
        }

        // ---------------- OperationRegion ----------------
        if (line.startsWith("OperationRegion")) {
          final buffer = StringBuffer();
          var parenDepth = 0;
          var started = false;
          var quoted = false;
          var end = i;
          for (; end < lines.length; end++) {
            final current = lines[end];
            buffer.writeln(current);
            for (var charIndex = 0; charIndex < current.length; charIndex++) {
              final ch = current[charIndex];
              if (ch == '"' &&
                  (charIndex == 0 || current[charIndex - 1] != r'\')) {
                quoted = !quoted;
              }
              if (quoted) continue;
              if (ch == '(') {
                parenDepth++;
                started = true;
              } else if (ch == ')') {
                parenDepth--;
              }
            }
            if (started && parenDepth <= 0) break;
          }

          final operationText = buffer.toString().trim();
          final open = operationText.indexOf('(');
          final close = operationText.lastIndexOf(')');
          final args = <String>[];
          if (open >= 0 && close > open) {
            final source = operationText.substring(open + 1, close);
            var argumentStart = 0;
            var nested = 0;
            quoted = false;
            for (var charIndex = 0; charIndex < source.length; charIndex++) {
              final ch = source[charIndex];
              if (ch == '"' &&
                  (charIndex == 0 || source[charIndex - 1] != r'\')) {
                quoted = !quoted;
              }
              if (quoted) continue;
              if ('([{'.contains(ch)) nested++;
              if (')]}'.contains(ch)) nested--;
              if (ch == ',' && nested == 0) {
                args.add(source.substring(argumentStart, charIndex).trim());
                argumentStart = charIndex + 1;
              }
            }
            args.add(source.substring(argumentStart).trim());
          }

          String regionName = "";
          String regionSpace = "";
          int offset = 0;
          int length = 0;
          String? offsetExpression;

          if (args.length >= 4) {
            regionName = args[0];
            regionSpace = args[1];
            final rawOffset = args[2];
            final parsedOffset = _tryParseAcpiIntegerLiteral(rawOffset);
            offset = parsedOffset ?? 0;
            length = _parseAcpiIntegerLiteral(args[3]);
            final supportedSpace = regionSpace.toLowerCase();
            if (parsedOffset == null &&
                (supportedSpace == "embeddedcontrol" ||
                    supportedSpace == "systemmemory")) {
              offsetExpression = rawOffset;
              final warning =
                  "$scopePath 的 $regionSpace OperationRegion $regionName 使用动态起始地址 $rawOffset；将保留该 TermArg，并按 Field 相对偏移生成访问地址。";
              if (_batteryRegionWarnings.add(warning)) Log.warning(warning);
            }
          }

          operationRegions.add({
            "text": operationText,
            "type": "OperationRegion",
            "name": regionName,
            "space": regionSpace,
            "offset": offset,
            "offsetExpression": offsetExpression,
            "length": length,
            "scope": scopePath,
          });

          i = end + 1;
          continue;
        }

        // ---------------- Field ----------------
        if (line.startsWith("Field (") || line.startsWith("IndexField (")) {
          final end = findBlockEnd(i);
          final buffer = StringBuffer();
          for (int t = i; t <= end; t++) {
            buffer.writeln(lines[t]);
          }
          final fieldText = buffer.toString().trim();

          final match = RegExp(
            r'^\s*(Field|IndexField)\s*\(([^)]*)\)',
          ).firstMatch(fieldText);

          String regionName = "";
          String accessType = "";
          String lockRule = "";
          String updateRule = "";

          if (match != null) {
            final args = match
                .group(2)!
                .split(',')
                .map((e) => e.trim())
                .toList();

            if (args.length >= 4) {
              regionName = args[0];
              accessType = args[args.length - 3];
              lockRule = args[args.length - 2];
              updateRule = args[args.length - 1];
            }
          }

          scopeFields.add({
            "text": fieldText,
            "type": "FieldUnitObj",
            "indexed": (match?.group(1) ?? "").toLowerCase() == "indexfield",
            "regionName": regionName,
            "accessType": accessType,
            "lockRule": lockRule,
            "updateRule": updateRule,
            "fields": _parseFieldBlock(scopePath, fieldText),
            "scope": scopePath,
          });

          i = end + 1;
          continue;
        }

        // ---------------- Method ----------------
        if (depth == 1 && line.startsWith("Method (")) {
          final end = findBlockEnd(i);
          final buffer = StringBuffer();
          for (int t = i; t <= end; t++) {
            buffer.writeln(lines[t]);
          }
          final methodText = buffer.toString().trim();

          final match = RegExp(
            r'^\s*Method\s*\(\s*([A-Za-z0-9_]+)\s*,\s*([0-9]+)\s*,\s*([A-Za-z]+)\s*\)',
            caseSensitive: false,
          ).firstMatch(methodText);

          // 提取方法中使用的字段，分为宽字节和普通字段
          final wideFields = <Map<String, dynamic>>[];
          final normalFields = <Map<String, dynamic>>[];
          final usedSymbols = _extractUsedSymbols([methodText]);
          final usedFieldNames = usedSymbols.map((e) => e['name']).toList();

          // 检查所有字段，看是否被方法使用
          for (final fieldBlock in scopeFields) {
            final fieldMap = fieldBlock["fields"] as List<dynamic>;
            for (final field in fieldMap) {
              final fieldName = field["name"] as String;
              if (usedFieldNames.contains(fieldName.toUpperCase())) {
                final bitLength = field["bitLength"] as int? ?? 0;
                final byteLength = field["byteLength"] as int? ?? 1;
                if (bitLength > 8 || byteLength > 1) {
                  wideFields.add(field);
                } else {
                  normalFields.add(field);
                }
              }
            }
          }

          methods.add({
            "text": methodText,
            "type": "MethodObj",
            "name": match?.group(1) ?? "",
            "argCount": int.tryParse(match?.group(2) ?? "0") ?? 0,
            "flags": match?.group(3) ?? "NotSerialized",
            "line": i,
            "wideFields": wideFields,
            "normalFields": normalFields,
            "scope": scopePath,
          });

          i = end + 1;
          continue;
        }

        // ---------------- Mutex ----------------
        if (depth == 1 && line.startsWith("Mutex (")) {
          final match = RegExp(
            r'^\s*Mutex\s*\(\s*([A-Za-z0-9_]+)\s*,\s*(0x[0-9A-Fa-f]+|[0-9]+)\s*\)',
            caseSensitive: false,
          ).firstMatch(raw);

          final levelText = (match?.group(2) ?? "0").trim();
          final level = levelText.toLowerCase().startsWith("0x")
              ? (int.tryParse(levelText.substring(2), radix: 16) ?? 0)
              : (int.tryParse(levelText) ?? 0);

          mutexs.add({
            "text": raw.trim(),
            "type": "MutexObj",
            "name": match?.group(1) ?? "",
            "level": level,
            "scope": scopePath,
          });

          i++;
          continue;
        }
      }

      // -------- depth 更新（更高效版本）--------
      for (final ch in raw.split('')) {
        if (ch == '{') depth++;
        if (ch == '}') depth--;
      }

      if (depth <= 0) break;
      i++;
    }
  }

  /// 获取设备的所有信息
  /// [scopeName] Scope 名称
  /// [scopePath] Scope 路径
  Map<String, dynamic> getScopeAllInfoWithScopeName({
    required String scopeName,
    required String scopePath,
    Map<String, dynamic>? table,
    bool collectNestedFieldLayouts = false,
  }) {
    table ??= d.getDsdt();

    final names = <Map<String, dynamic>>[];
    final methods = <Map<String, dynamic>>[];
    final opRegions = <Map<String, dynamic>>[];
    final fields = <Map<String, dynamic>>[];
    final devices = <String>[];
    final mutexs = <Map<String, dynamic>>[];

    final scopes = d.getScopesOfPath(
      scopePath: scopeName,
      table: table,
      stripComments: true,
    );

    if (scopes.isEmpty) {
      return {
        "valid": false,
        "path": scopePath,
        "name": scopeName,
        "names": names,
        "methods": methods,
        "operationRegions": opRegions,
        "scopeFields": fields,
        "devices": devices,
        "mutexs": mutexs,
      };
    }
    for (final scope in scopes) {
      _collectScopeObjectsFromLines(
        lines: scope,
        scopePath: scopePath,
        names: names,
        methods: methods,
        operationRegions: opRegions,
        scopeFields: fields,
        devices: devices,
        mutexs: mutexs,
        collectNestedFieldLayouts: collectNestedFieldLayouts,
      );
    }

    return {
      "valid": true,
      "path": scopePath,
      "name": scopeName,
      "names": names,
      "methods": methods,
      "operationRegions": opRegions,
      "scopeFields": fields,
      "devices": devices,
      "mutexs": mutexs,
      "table": table,
    };
  }

  /// 获取设备的所有信息
  /// [path] 设备路径
  /// [table] SSDT 表
  Map<String, dynamic> getDeviceAllInfo({
    required String path,
    Map<String, dynamic>? table,
    int? startingIndex,
    bool collectNestedFieldLayouts = false,
  }) {
    table ??= d.getDsdt();
    String name = path.split(".").last;
    final names = <Map<String, dynamic>>[];
    final methods = <Map<String, dynamic>>[];
    final opRegions = <Map<String, dynamic>>[];
    final fields = <Map<String, dynamic>>[];
    final devices = <String>[];
    final mutexs = <Map<String, dynamic>>[];

    final scope = startingIndex == null
        ? d.getScopeOfDevice(
            devicePath: path,
            table: table,
            stripComments: true,
          )
        : d.getScope(
            startingIndex: startingIndex,
            table: table,
            stripComments: true,
          );

    if (scope.isEmpty) {
      Log("=> 未找到设备 $path 的 Scope");
      return {
        "valid": false,
        "path": path,
        "name": name,
        "names": names,
        "methods": methods,
        "operationRegions": opRegions,
        "scopeFields": fields,
        "devices": devices,
        "mutexs": mutexs,
      };
    }

    _collectScopeObjectsFromLines(
      lines: scope,
      scopePath: path,
      names: names,
      methods: methods,
      operationRegions: opRegions,
      scopeFields: fields,
      devices: devices,
      mutexs: mutexs,
      collectNestedFieldLayouts: collectNestedFieldLayouts,
    );

    final usesSystemMemory = RegExp(
      r'OperationRegion\s*\([^,]+,\s*SystemMemory\s*,',
      caseSensitive: false,
    ).hasMatch(scope.join("\n"));

    // 校验 _STA 是否仅返回 Zero
    final valid = !methods.any((m) {
      final name = (m["name"] ?? "").toString().toUpperCase();
      if (name != "_STA") return false;

      final text = (m["text"] ?? "").toString();
      return isMethodOnlyReturnZero(text);
    });

    return {
      "valid": valid,
      "path": path,
      "name": name,
      "names": names,
      "methods": methods,
      "operationRegions": opRegions,
      "scopeFields": fields,
      "devices": devices,
      "mutexs": mutexs,
      "usesSystemMemory": usesSystemMemory,
    };
  }

  /// 从方法文本中提取所有 Return 语句的值
  /// [methodText] 方法文本
  /// 返回所有 Return 语句的值列表
  List<String> extractReturns(String methodText) {
    return RegExp(r'Return\s*\(\s*([^)]+)\s*\)', caseSensitive: false)
        .allMatches(methodText)
        .map((e) => e.group(1)!.trim().toUpperCase())
        .toList();
  }

  /// 判断值是否为 Zero
  /// [value] 值
  /// 返回是否为 Zero
  bool isZeroValue(String value) {
    return RegExp(r'^(ZERO|0X0+|0)$', caseSensitive: false).hasMatch(value);
  }

  /// 判断任意方法是否仅 Return(Zero)
  bool isMethodOnlyReturnZero(String methodText) {
    final returns = extractReturns(methodText);

    if (returns.isEmpty) return false;

    return returns.every(isZeroValue);
  }

  /// 解析 Field 块，提取字段信息
  List<Map<String, dynamic>> _parseFieldBlock(String path, String fieldBlock) {
    final fields = <Map<String, dynamic>>[];

    // 找到 Field 块的大括号内容
    final start = fieldBlock.indexOf("{");
    final end = fieldBlock.lastIndexOf("}");
    if (start < 0 || end <= start) return fields;

    final body = fieldBlock.substring(start + 1, end).trim();
    // 按行分割，保留逗号
    final lines = body
        .split(RegExp(r'[\n\r]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    int bitOffset = 0;
    for (final line in lines) {
      // 处理 Offset 指令
      if (line.toLowerCase().startsWith("offset")) {
        final offsetMatch = RegExp(
          r'Offset\s*\(\s*([0-9xA-Fa-f]+)\s*\)',
        ).firstMatch(line);
        if (offsetMatch != null) {
          final offsetStr = offsetMatch.group(1);
          if (offsetStr != null) {
            int offset = 0;
            if (offsetStr.startsWith("0x")) {
              offset = int.tryParse(offsetStr.substring(2), radix: 16) ?? 0;
            } else {
              offset = int.tryParse(offsetStr) ?? 0;
            }
            bitOffset = offset * 8;
          }
        }
        continue;
      }

      // 跳过访问控制指令
      if (line.toLowerCase().startsWith("accessas") ||
          line.toLowerCase().startsWith("connection") ||
          line.toLowerCase().startsWith("lock") ||
          line.toLowerCase().startsWith("update")) {
        continue;
      }

      // 按逗号分割字段定义
      final fieldDefs = line.split(',').map((e) => e.trim()).toList();

      // 每两个元素组成一个字段定义（字段名 + 位长）
      for (int i = 0; i < fieldDefs.length; i += 2) {
        if (i + 1 < fieldDefs.length) {
          final fieldName = fieldDefs[i];
          final lengthStr = fieldDefs[i + 1];

          // 跳过空长度
          if (lengthStr.isEmpty) continue;

          int bitLength = 8; // 默认位长
          if (lengthStr.startsWith("0x")) {
            bitLength = int.tryParse(lengthStr.substring(2), radix: 16) ?? 8;
          } else {
            bitLength = int.tryParse(lengthStr) ?? 8;
          }

          final byteOffset = bitOffset ~/ 8;
          final bitInByte = bitOffset % 8;
          final byteSize = ((bitInByte + bitLength) + 7) ~/ 8;

          fields.add({
            "name": fieldName,
            "bitLength": bitLength,
            "byteLength": byteSize,
            "offset": byteOffset,
            "bitOffset": bitOffset,
            "scope": path,
          });

          // Log(
          //   "=> 解析字段: $fieldName, bitLength: $bitLength, offset: 0x${byteOffset.toRadixString(16)}, bitOffset: 0x${bitOffset.toRadixString(16)}",
          // );

          bitOffset += bitLength;
        }
      }
    }

    return fields;
  }

  /// 查找所有符合条件的电池设备
  /// 查找所有符合条件的电池设备（包含 _STA/_BST/_BIX 或 _BIF 方法）
  /// 返回符合条件的电池设备列表
  List<Map<String, dynamic>> _findBatteryDevices() {
    final devices = <Map<String, dynamic>>[];
    for (final tableName in sortedNicely(d.acpiTables.keys.toList())) {
      final table = d.acpiTables[tableName];
      if (table == null) continue;

      final batteries = d.getDevicePathsWithHid(hid: "PNP0C0A", table: table);
      if (batteries.isEmpty) continue;
      Log("=> 在 $tableName 中检测到 ${batteries.length} 个电池设备:");
      for (final bat in batteries) {
        Log("=> 电池设备: ${bat[0]}");
      }
      Log("正在筛选有效电池设备...");
      for (final bat in batteries) {
        final path = bat[0].toString();
        final info = getDeviceAllInfo(
          path: path,
          table: table,
          startingIndex: bat[1] as int?,
        );
        final parentPath = path
            .split(".")
            .sublist(0, path.split(".").length - 1)
            .join(".");

        final name = path.split(".").last;
        final methods = info["methods"] as List<Map<String, dynamic>>? ?? [];
        bool hasSTA = false;
        bool hasBST = false;
        bool hasBif = false;
        bool hasBix = false;
        // 检查电池设备是否包含必要的方法
        for (final m in methods) {
          final name = m["name"] as String? ?? "";
          if (name == "_STA") hasSTA = true;
          if (name == "_BST") hasBST = true;
          if (name == "_BIF") hasBif = true;
          if (name == "_BIX") hasBix = true;
        }
        final hasBixOrBif = hasBif || hasBix;

        if (hasSTA && hasBST && hasBixOrBif) {
          Log("=> 电池设备 $path 包含必要的方法（_STA/_BST/_BIX 或 _BIF）,有效电池!");
          devices.add({
            "valid": true,
            "name": name,
            "path": path,
            "names": info["names"] ?? [],
            "methods": methods,
            "mutexs": info["mutexs"] ?? [],
            "usesSystemMemory": info["usesSystemMemory"] == true,
            "scope": parentPath,
            "table": table,
          });
        } else {
          Log.warning(
            "=> 电池设备 $path 不包含必要的方法（_STA/_BST/_BIX 或 _BIF）,无效电池,已跳过!",
          );
        }
      }
    }
    return devices;
  }

  /// 查找所有符合条件的EC设备
  /// 返回符合条件的EC设备列表
  List<Map<String, dynamic>> _findECDevices() {
    final tableNames = sortedNicely(d.acpiTables.keys.toList());

    // 按 EC 设备绝对路径聚合所有表中的 Scope 信息。
    // 即便某个 SSDT/SSDT-x 中没有 PNP0C09 设备定义，也可能存在
    // Scope(\_SB....ECx) 的方法/字段，因此不能只在“找到设备的表”里解析 Scope
    final ecByPath = <String, Map<String, dynamic>>{};

    void mergeListUnique({
      required List<dynamic> into,
      required List<dynamic> incoming,
      required String Function(dynamic item) keyOf,
    }) {
      final seen = <String>{};
      for (final it in into) {
        seen.add(keyOf(it));
      }
      for (final it in incoming) {
        final k = keyOf(it);
        if (seen.add(k)) into.add(it);
      }
    }

    // 1) 第一次扫描：找出所有有效 EC 设备（PNP0C09）
    for (final tableName in tableNames) {
      final table = d.acpiTables[tableName];
      if (table == null) continue;

      final ecDevices = d.getDevicePathsWithHid(hid: "PNP0C09", table: table);
      if (ecDevices.isEmpty) continue;
      Log(
        "=> 在 $tableName 中检测到 ${ecDevices.length} 个EC设备:",
        level: ecDevices.length > 1 ? LogLevel.warning : LogLevel.info,
      );

      for (final ec in ecDevices) {
        Log("=> EC设备: ${ec[0]}");
      }

      for (final ec in ecDevices) {
        final ecPath = ec[0].toString();
        final parentPath = ecPath
            .split(".")
            .sublist(0, ecPath.split(".").length - 1)
            .join(".");

        final ecInfo = getDeviceAllInfo(
          path: ecPath,
          table: table,
          startingIndex: ec[1] as int?,
          collectNestedFieldLayouts: true,
        );
        if (!(ecInfo['valid'] ?? false)) {
          Log.warning("=> EC设备 $ecPath 无效,已跳过!");
          continue;
        }

        final entry = ecByPath.putIfAbsent(ecPath, () {
          return {
            "valid": true,
            "name": ecInfo["name"] as String? ?? "",
            "path": ecPath,
            "names": <dynamic>[],
            "operationRegions": <dynamic>[],
            "scopeFields": <dynamic>[],
            "methods": <dynamic>[],
            "mutexs": <dynamic>[],
            "scope": parentPath,
            // 记录首次发现该 EC 设备的表，便于调试
            "table": table,
          };
        });

        // 设备体内信息
        mergeListUnique(
          into: entry["names"],
          incoming: ecInfo["names"] as List<dynamic>? ?? const [],
          keyOf: (it) {
            final m = (it as Map);
            return "${(m["scope"] ?? "").toString().toUpperCase()}.${(m["name"] ?? "").toString().toUpperCase()}";
          },
        );
        mergeListUnique(
          into: entry["operationRegions"],
          incoming: ecInfo["operationRegions"] as List<dynamic>? ?? const [],
          keyOf: (it) {
            final m = (it as Map);
            return "${(m["scope"] ?? "").toString().toUpperCase()}.${(m["name"] ?? "").toString().toUpperCase()}";
          },
        );
        mergeListUnique(
          into: entry["scopeFields"],
          incoming: ecInfo["scopeFields"] as List<dynamic>? ?? const [],
          keyOf: (it) {
            final m = (it as Map);
            return "${(m["scope"] ?? "").toString().toUpperCase()}.${(m["regionName"] ?? "").toString().toUpperCase()}:${(m["text"] ?? "").toString()}";
          },
        );
        mergeListUnique(
          into: entry["methods"],
          incoming: ecInfo["methods"] as List<dynamic>? ?? const [],
          keyOf: (it) {
            final m = (it as Map);
            return "${(m["scope"] ?? "").toString().toUpperCase()}.${(m["name"] ?? "").toString().toUpperCase()}";
          },
        );
        mergeListUnique(
          into: entry["mutexs"],
          incoming: ecInfo["mutexs"] as List<dynamic>? ?? const [],
          keyOf: (it) {
            final m = (it as Map);
            return "${(m["scope"] ?? "").toString().toUpperCase()}.${(m["name"] ?? "").toString().toUpperCase()}";
          },
        );
      }
    }

    if (ecByPath.isEmpty) return <Map<String, dynamic>>[];

    // 2) 第二次扫描：对每个有效 EC 设备，在所有表中继续收集 Scope(....ECx) 信息
    for (final tableName in tableNames) {
      final table = d.acpiTables[tableName];
      if (table == null) continue;

      for (final entry in ecByPath.values) {
        final ecName = (entry["name"] ?? "").toString();
        final ecPath = (entry["path"] ?? "").toString();
        if (ecName.isEmpty || ecPath.isEmpty) continue;

        final otherECInfo = getScopeAllInfoWithScopeName(
          scopeName: ecName,
          scopePath: ecPath,
          table: table,
          collectNestedFieldLayouts: true,
        );
        if (otherECInfo.isEmpty || !(otherECInfo["valid"] ?? false)) continue;

        mergeListUnique(
          into: entry["names"],
          incoming: otherECInfo["names"] as List<dynamic>? ?? const [],
          keyOf: (it) {
            final m = (it as Map);
            return "${(m["scope"] ?? "").toString().toUpperCase()}.${(m["name"] ?? "").toString().toUpperCase()}";
          },
        );
        mergeListUnique(
          into: entry["operationRegions"],
          incoming:
              otherECInfo["operationRegions"] as List<dynamic>? ?? const [],
          keyOf: (it) {
            final m = (it as Map);
            return "${(m["scope"] ?? "").toString().toUpperCase()}.${(m["name"] ?? "").toString().toUpperCase()}";
          },
        );
        mergeListUnique(
          into: entry["scopeFields"],
          incoming: otherECInfo["scopeFields"] as List<dynamic>? ?? const [],
          keyOf: (it) {
            final m = (it as Map);
            return "${(m["scope"] ?? "").toString().toUpperCase()}.${(m["regionName"] ?? "").toString().toUpperCase()}:${(m["text"] ?? "").toString()}";
          },
        );
        mergeListUnique(
          into: entry["methods"],
          incoming: otherECInfo["methods"] as List<dynamic>? ?? const [],
          keyOf: (it) {
            final m = (it as Map);
            return "${(m["scope"] ?? "").toString().toUpperCase()}.${(m["name"] ?? "").toString().toUpperCase()}";
          },
        );
        mergeListUnique(
          into: entry["mutexs"],
          incoming: otherECInfo["mutexs"] as List<dynamic>? ?? const [],
          keyOf: (it) {
            final m = (it as Map);
            return "${(m["scope"] ?? "").toString().toUpperCase()}.${(m["name"] ?? "").toString().toUpperCase()}";
          },
        );
      }
    }

    final out = ecByPath.values.toList();
    out.sort(
      (a, b) =>
          (a["path"] ?? "").toString().compareTo((b["path"] ?? "").toString()),
    );
    return out;
  }

  /// 生成ACPI配置并写入SSDT
  Future<void> _generateAcpiConfigAndWriteSsdt({
    required String ssdtName,
    required String ssdt,
    required List<Map<String, String>> patches,
    required String comment,
  }) async {
    final acpi = {"Comment": comment, "Enabled": true, "Path": "$ssdtName.aml"};

    if (await writeSSDT(ssdtName, ssdt)) {
      makePlist(acpi: acpi, patches: patches, replace: true);
    } else {
      Log.error('未写入 $ssdtName 的 ACPI 配置：SSDT 编译失败。');
    }
  }

  /// 生成电池相关数据
  (
    List<Map<String, String>>,
    Map<String, String>,
    Map<String, Map<String, dynamic>>,
    List<String>,
    Map<String, String>,
  )
  _generateBatteryData({
    required List<Map<String, dynamic>> batteryDevices,
    required List<Map<String, dynamic>> ecDevices,
    required Map<String, Map<String, dynamic>> relatedMethods,
    required List<Map<String, dynamic>> usedFields,
    required List<Map<String, String>> usedSymbols,
    required Set<String> usedMutexNames,
    required String ssdtName,
  }) {
    final List<Map<String, String>> patches = [];
    final Map<String, String> renameMap = {};
    final List<String> externals = [];
    final Map<String, String> wrappers = {};

    // 检查维护表T中使用到的 Mutex 同步等级，非0则生成置0补丁
    final usedMutexSet = usedMutexNames.map((e) => e.toUpperCase()).toSet();
    for (final device in [...batteryDevices, ...ecDevices]) {
      final deviceMutexs = device['mutexs'] as List<dynamic>? ?? const [];
      if (deviceMutexs.isEmpty) continue;

      for (final m in deviceMutexs) {
        final mutex = m;
        final mutexName = (mutex['name'] ?? '').toString().toUpperCase();
        if (mutexName.isEmpty || !usedMutexSet.contains(mutexName)) continue;

        final level = mutex['level'] as int? ?? 0;
        if (level == 0) continue;

        final devicePath = (device['path'] ?? device['scope'] ?? '')
            .toString()
            .trim();
        Log("=> $devicePath 中的 ${mutex['text']} 同步等级为 $level,已生成置0补丁!");
        patches.add({
          "Comment":
              "Change Mutex ($mutexName, ${util.hexy(level, padTo: 2)} to 0)",
          "Find":
              _nameToHex(mutexName) + level.toRadixString(16).padLeft(2, '0'),
          "Replace": "${_nameToHex(mutexName)}00",
        });
      }
    }

    for (final batteryDevice in batteryDevices) {
      // 生成重命名补丁
      final (patcheList, reMap) = _generateRenamePatches(
        table: batteryDevice["table"] as Map<String, dynamic>? ?? {},
        relatedMethods: relatedMethods,
        ssdtName: ssdtName,
      );

      if (patcheList.isNotEmpty) {
        patches.addAll(patcheList);
      }
      if (reMap.isNotEmpty) {
        renameMap.addAll(reMap);
      }
    }

    // 构建外部引用
    final renameTargetsMap = <String, Map<String, dynamic>>{};
    for (final entry in renameMap.entries) {
      final renameTarget = entry.value;
      // 查找原始方法字典
      final originalMethod = relatedMethods[entry.key];
      if (originalMethod != null) {
        renameTargetsMap[renameTarget] = originalMethod;
      }
    }

    // 生成方法包装器
    final wrapperList = _generateMethodWrappers(
      ecDevices: ecDevices,
      relatedMethods: relatedMethods,
      renameMap: renameMap,
      renameTargetsMap: renameTargetsMap,
      usedFields: usedFields,
    );
    if (wrapperList.isNotEmpty) {
      wrappers.addAll(wrapperList);
    }

    final externalList = _buildBatteryExternals(
      batteryDevices: batteryDevices,
      ecDevices: ecDevices,
      usedFields: usedFields,
      renameTargets: renameTargetsMap,
      usedSymbols: usedSymbols,
    );

    if (externalList.isNotEmpty) {
      externals.addAll(externalList);
    }

    return (patches, renameMap, renameTargetsMap, externals, wrappers);
  }

  /// 处理多电池情况，生成电池依赖表并处理重命名
  Future<void> _handleMultiBatteryCase({
    required List<Map<String, dynamic>> batteryDevices,
    required List<Map<String, dynamic>> ecDevices,
    required List<Map<String, String>> usedSymbols,
    required Map<String, Map<String, dynamic>> relatedMethods,
    required List<Map<String, dynamic>> usedFields,
    required Set<String> usedMutexNames,
    required String ssdtName,
  }) async {
    // 临时变量存储所有电池设备的数据
    final Map<String, Map<String, String>> patchesMap = {};
    final Set<String> externalsSet = {};
    final Map<String, String> renameMap = {};
    final Map<String, String> methodMap = {};
    final Map<String, String> wrappersMap = {};

    // 收集所有电池/EC方法文本（用于后续模板/调试）
    for (final batteryDevice in batteryDevices) {
      final methods = batteryDevice["methods"] as List<dynamic>? ?? const [];
      for (final m in methods) {
        final mm = m;
        final name = (mm["name"] ?? "").toString().toUpperCase();
        final text = (mm["text"] ?? "").toString();
        if (name.isNotEmpty && text.isNotEmpty) {
          methodMap[name] = text;
        }
      }
    }
    for (final ecDevice in ecDevices) {
      final methods = ecDevice["methods"] as List<dynamic>? ?? const [];
      for (final m in methods) {
        final mm = m;
        final name = (mm["name"] ?? "").toString().toUpperCase();
        final text = (mm["text"] ?? "").toString();
        if (name.isNotEmpty && text.isNotEmpty) {
          methodMap[name] = text;
        }
      }
    }

    // 生成电池相关数据
    final (
      devicePatches,
      deviceRenameMap,
      renameTargetsMap,
      deviceExternals,
      deviceWrappers,
    ) = _generateBatteryData(
      batteryDevices: batteryDevices,
      ecDevices: ecDevices,
      relatedMethods: relatedMethods,
      usedFields: usedFields,
      usedSymbols: usedSymbols,
      usedMutexNames: usedMutexNames,
      ssdtName: ssdtName,
    );

    // 汇总补丁，使用 Find 值作为键去重
    if (devicePatches.isNotEmpty) {
      for (final patch in devicePatches) {
        final patchKey = patch["Find"];
        if (patchKey != null) {
          patchesMap[patchKey] = patch;
        }
      }
    }

    // 汇总重命名映射
    if (deviceRenameMap.isNotEmpty) {
      renameMap.addAll(deviceRenameMap);
    }

    // 汇总外部引用
    if (deviceExternals.isNotEmpty) {
      externalsSet.addAll(deviceExternals);
    }

    // 汇总包装器
    if (deviceWrappers.isNotEmpty) {
      wrappersMap.addAll(deviceWrappers);
    }

    if (renameMap.isNotEmpty) {
      Log("=> 电池依赖方法: ${renameMap.keys.join(', ')}");
    } else {
      Log("=> 电池依赖方法为空!");
      Log("准备合并当前 ${batteryDevices.length} 个电池设备...");
    }
    // 打印补丁
    for (final entry in renameMap.entries) {
      Log("=> 生成重命名补丁: ${entry.key} -> ${entry.value}");
    }

    // 转换为列表
    final patches = patchesMap.values.toList();
    final externals = externalsSet.toList();

    // 生成外部引用行
    final externalLines = externals.map((x) => "    $x").join("\n");
    debugPrint(externalLines);

    // 构建SSDT
    String ssdt = _buildMultiBatterySsdt(
      batteryDevices: batteryDevices,
      ecDevices: ecDevices,
      relatedMethods: relatedMethods,
      renameMap: renameMap,
      renameTargetsMap: renameTargetsMap,
      methodBlocks: methodMap,
      usedFields: usedFields,
      externalLines: externalLines,
      ssdtName: ssdtName,
    );

    final batteryNames = batteryDevices
        .map((e) => e["name"] as String)
        .toList();
    // 生成ACPI配置并写入SSDT
    await _generateAcpiConfigAndWriteSsdt(
      ssdtName: ssdtName,
      ssdt: ssdt,
      patches: patches,
      comment:
          "Multi-battery logical merge for Darwin (${batteryNames.join('+')})",
    );
  }

  /// 处理单电池情况
  Future<void> _handleSingleBatteryCase({
    required Map<String, dynamic> batteryDevice,
    required List<Map<String, dynamic>> ecDevices,
    required Map<String, Map<String, dynamic>> relatedMethods,
    required List<Map<String, dynamic>> usedFields,
    required List<Map<String, String>> usedSymbols,
    required Set<String> usedMutexNames,
    required String ssdtName,
  }) async {
    // 生成电池相关数据
    final (
      patches,
      renameMap,
      renameTargetsMap,
      externals,
      wrappers,
    ) = _generateBatteryData(
      batteryDevices: [batteryDevice],
      ecDevices: ecDevices,
      relatedMethods: relatedMethods,
      usedFields: usedFields,
      usedSymbols: usedSymbols,
      usedMutexNames: usedMutexNames,
      ssdtName: ssdtName,
    );
    if (renameMap.isNotEmpty) {
      Log("=> 电池依赖方法: ${renameMap.keys.join(', ')}");
    } else {
      Log("=> 电池依赖方法为空!无需热补丁,已终止操作!");
      return;
    }
    // 打印补丁
    for (final entry in renameMap.entries) {
      Log("=> 生成重命名补丁: ${entry.key} -> ${entry.value}");
    }

    final externalLines = externals.map((x) => "    $x").join("\n");
    debugPrint(externalLines);
    // 构建SSDT
    final String ssdt = _buildSingleBatterySsdt(
      ecDevices: ecDevices,
      relatedMethods: relatedMethods,
      externalLines: externalLines,
      wrappers: wrappers,
      usedFields: usedFields,
    );

    // 生成ACPI配置并写入SSDT
    await _generateAcpiConfigAndWriteSsdt(
      ssdtName: ssdtName,
      ssdt: ssdt,
      patches: patches,
      comment: "Battery EC hotpatch (${batteryDevice['path']})",
    );
  }

  /// 获取同名方法在不同 ACPI 作用域中的所有来源。
  List<Map<String, dynamic>> _relatedMethodOrigins(
    Map<String, dynamic> method,
  ) {
    final rawOrigins = method["origins"] as List<dynamic>?;
    if (rawOrigins == null || rawOrigins.isEmpty) return [method];
    return rawOrigins
        .whereType<Map>()
        .map((origin) => Map<String, dynamic>.from(origin))
        .toList();
  }

  /// 生成 Method Rename 补丁
  (List<Map<String, String>>, Map<String, String>) _generateRenamePatches({
    required Map<String, dynamic> table,
    required Map<String, Map<String, dynamic>> relatedMethods,
    required String ssdtName,
  }) {
    final patches = <Map<String, String>>[];
    final renameMap = <String, String>{};

    final usedNewNames = <String>{};
    final orderedMethodNames = relatedMethods.keys.toList()
      ..sort((a, b) {
        final au = a.toUpperCase();
        final bu = b.toUpperCase();
        final aIsStd = au.startsWith('_');
        final bIsStd = bu.startsWith('_');
        if (aIsStd != bIsStd) return aIsStd ? -1 : 1;
        return au.compareTo(bu);
      });

    for (final methodName in orderedMethodNames) {
      final info = relatedMethods[methodName]!;
      final origins = _relatedMethodOrigins(info);

      // A renamed method is installed in the original method's scope.  Avoid
      // colliding with firmware objects already declared there (for example,
      // some Lenovo tables contain Name (XBIF, Package (...)) next to _BIF).
      final unavailableNames = <String>{...usedNewNames};
      for (final origin in origins) {
        final methodScopeKey = BatteryExternalNormalizer.pathKey(
          (origin["scope"] ?? '').toString(),
        );
        for (final object in _batteryNamespaceObjects) {
          final objectKey = BatteryExternalNormalizer.pathKey(object.path);
          final segments = objectKey.split('.');
          if (segments.isEmpty) continue;
          final objectScopeKey = segments.length == 1
              ? ''
              : segments.sublist(0, segments.length - 1).join('.');
          if (objectScopeKey == methodScopeKey) {
            unavailableNames.add(segments.last);
          }
        }
      }

      /// 新 Method
      final baseName = _renamedMethodName(methodName);
      final newMethodName = _renamedMethodName(
        methodName,
        usedNames: unavailableNames,
      );
      if (newMethodName != baseName) {
        Log.warning(
          "=> 检测到重命名冲突: $methodName -> $baseName 已占用, 自动调整为 $newMethodName",
        );
      }
      usedNewNames.add(newMethodName);

      final emittedSignatures = <String>{};
      for (final origin in origins) {
        final argCount = origin["argCount"] as int? ?? 0;
        final serialized = origin["flags"] == 'Serialized';
        final flags = argCount + (serialized ? 8 : 0);
        final flagsHex = flags.toRadixString(16).padLeft(2, '0').toUpperCase();
        final oldHex = _nameToHex(methodName) + flagsHex;
        if (!emittedSignatures.add(oldHex)) continue;
        final newHex = _nameToHex(newMethodName) + flagsHex;
        patches.add({
          "Comment":
              "Method ($methodName,$argCount,${serialized ? 'S' : 'N'}) to $newMethodName rename - requires $ssdtName.aml",
          "Find": oldHex,
          "Replace": newHex,
        });
      }

      renameMap[methodName] = newMethodName;
    }

    return (patches, renameMap);
  }

  /// 生成方法包装器
  Map<String, String> _generateMethodWrappers({
    required List<Map<String, dynamic>> ecDevices,
    required Map<String, Map<String, dynamic>> relatedMethods,
    required Map<String, String> renameMap,
    required Map<String, Map<String, dynamic>> renameTargetsMap,
    required List<Map<String, dynamic>> usedFields,
  }) {
    final wrappers = <String, String>{};

    for (final methodName in relatedMethods.keys) {
      final renameTarget = renameMap[methodName];
      if (renameTarget == null) continue;
      final origins = _relatedMethodOrigins(relatedMethods[methodName]!);
      for (var index = 0; index < origins.length; index++) {
        final origin = origins[index];
        final key = index == 0
            ? methodName
            : _methodFullPath((origin["scope"] ?? '').toString(), methodName);
        wrappers[key] = _buildBatteryMethodWrapper(
          relatedMethod: origin,
          renameTarget: renameTarget,
          renameTargetsMap: renameTargetsMap,
          usedFields: usedFields,
        );
      }
    }

    return wrappers;
  }

  String _batteryAbsolutePath(String value) {
    final path = value.trim();
    return path.startsWith('\\') ? path : '\\$path';
  }

  String _buildGenericMultiBatteryDevice(
    List<Map<String, dynamic>> batteries,
    String infoMethod,
  ) {
    final bix = infoMethod == '_BIX';
    final power = bix ? 1 : 0;
    final design = bix ? 2 : 1;
    final full = bix ? 3 : 2;
    final voltage = bix ? 5 : 4;
    final warning = bix ? 6 : 5;
    final low = bix ? 7 : 6;
    final fallbackPackageSize = bix ? '0x15' : '0x0D';
    final hideLines = <String>[];
    final staLines = <String>[];
    final infoBlocks = <String>[];
    final statusBlocks = <String>[];

    String activeBlock(String path, String body) =>
        '''If (LNotEqual (And ($path._STA (), 0x10), Zero))
{
${_indentBlock(body, 4)}
}''';

    for (final battery in batteries) {
      final path = _batteryAbsolutePath((battery['path'] ?? '').toString());
      hideLines.add('''If (CondRefOf ($path._HID))
{
    Store (Zero, $path._HID)
}''');
      staLines.add('Or (Local0, $path._STA (), Local0)');
      infoBlocks.add(
        activeBlock(path, '''Store ($path.$infoMethod (), Local1)
If (LEqual (Local6, Zero))
{
    Store (Local1, Local0)
    Store (DerefOf (Index (Local1, $power)), Local4)
    Store (DerefOf (Index (Local1, $voltage)), Local5)
    Store (One, Index (Local0, $power))
    Store (CVWA (DerefOf (Index (Local1, $design)), Local5, Local4), Index (Local0, $design))
    Store (CVWA (DerefOf (Index (Local1, $full)), Local5, Local4), Index (Local0, $full))
    Store (CVWA (DerefOf (Index (Local1, $warning)), Local5, Local4), Index (Local0, $warning))
    Store (CVWA (DerefOf (Index (Local1, $low)), Local5, Local4), Index (Local0, $low))
}
Else
{
    Store (DerefOf (Index (Local1, $power)), Local4)
    Store (DerefOf (Index (Local1, $voltage)), Local5)
    Store (Add (DerefOf (Index (Local0, $design)), CVWA (DerefOf (Index (Local1, $design)), Local5, Local4)), Index (Local0, $design))
    Store (Add (DerefOf (Index (Local0, $full)), CVWA (DerefOf (Index (Local1, $full)), Local5, Local4)), Index (Local0, $full))
    Store (Add (DerefOf (Index (Local0, $warning)), CVWA (DerefOf (Index (Local1, $warning)), Local5, Local4)), Index (Local0, $warning))
    Store (Add (DerefOf (Index (Local0, $low)), CVWA (DerefOf (Index (Local1, $low)), Local5, Local4)), Index (Local0, $low))
    Divide (Add (Multiply (DerefOf (Index (Local0, $voltage)), Local6), Local5), Add (Local6, One), Local7, Index (Local0, $voltage))
}
Increment (Local6)'''),
      );
      statusBlocks.add(
        activeBlock(path, '''Store ($path._BST (), Local1)
Store ($path.$infoMethod (), Local2)
Store (DerefOf (Index (Local2, $power)), Local4)
Store (DerefOf (Index (Local2, $voltage)), Local5)
If (LEqual (Local6, Zero))
{
    Store (Local1, Local0)
    Store (CVWA (DerefOf (Index (Local1, One)), Local5, Local4), Index (Local0, One))
    Store (CVWA (DerefOf (Index (Local1, 0x02)), Local5, Local4), Index (Local0, 0x02))
}
Else
{
    Store (Or (DerefOf (Index (Local0, Zero)), DerefOf (Index (Local1, Zero))), Index (Local0, Zero))
    Store (Add (DerefOf (Index (Local0, One)), CVWA (DerefOf (Index (Local1, One)), Local5, Local4)), Index (Local0, One))
    Store (Add (DerefOf (Index (Local0, 0x02)), CVWA (DerefOf (Index (Local1, 0x02)), Local5, Local4)), Index (Local0, 0x02))
    Divide (Add (Multiply (DerefOf (Index (Local0, 0x03)), Local6), DerefOf (Index (Local1, 0x03))), Add (Local6, One), Local7, Index (Local0, 0x03))
}
Increment (Local6)'''),
      );
    }

    return '''Device (BATC)
{
    Name (_HID, EisaId ("PNP0C0A"))
    Name (_UID, 0x02)
    Name (_PCL, Package (One) { \\_SB })

    Method (_INI, 0, NotSerialized)
    {
        If (_OSI ("Darwin"))
        {
${_indentBlock(hideLines.join('\n'), 12)}
        }
    }

    Method (_STA, 0, NotSerialized)
    {
        If (LNot (_OSI ("Darwin"))) { Return (Zero) }
        Local0 = Zero
${_indentBlock(staLines.join('\n'), 8)}
        Return (Local0)
    }

    Method (CVWA, 3, NotSerialized)
    {
        If (Arg2) { Return (Arg0) }
        If (LEqual (Arg1, Zero)) { Return (Arg0) }
        Divide (Multiply (Arg0, 0x03E8), Arg1, Local0, Local1)
        Return (Local1)
    }

    Method ($infoMethod, 0, Serialized)
    {
        Local0 = Package ($fallbackPackageSize) {}
        Local6 = Zero
${_indentBlock(infoBlocks.join('\n'), 8)}
        Return (Local0)
    }

    Method (_BST, 0, Serialized)
    {
        Local0 = Package (0x04) { Zero, Zero, Zero, Zero }
        Local6 = Zero
${_indentBlock(statusBlocks.join('\n'), 8)}
        Return (Local0)
    }
}''';
  }

  /// 构建多电池SSDT
  String _buildMultiBatterySsdt({
    required List<Map<String, dynamic>> batteryDevices,
    required List<Map<String, dynamic>> ecDevices,
    required Map<String, Map<String, dynamic>> relatedMethods,
    required Map<String, String> renameMap,
    required Map<String, Map<String, dynamic>> renameTargetsMap,
    required Map<String, String> methodBlocks,
    required List<Map<String, dynamic>> usedFields,
    required String externalLines,
    required String ssdtName,
  }) {
    final ecScope = ecDevices.first["path"] as String? ?? "";
    final batScope = batteryDevices.first["scope"] as String? ?? "";
    final batteryNames = batteryDevices
        .map((e) => e["name"] as String)
        .toList();
    final staOr = StringBuffer();
    final iniHide = StringBuffer();

    for (int i = 0; i < batteryNames.length; i++) {
      final b = batteryNames[i];
      staOr.writeln("                    Or (Local0, ^^$b._STA (), Local0)");
      iniHide.writeln("""
	                    If (CondRefOf (^^$b._HID))
	                    {
	                        Store (Zero, ^^$b._HID)
	                    }""");
    }

    // 合并相同 Scope，避免生成重复作用域
    final scopeParts = <String, List<String>>{};
    void addPart(String scope, String block, {bool atStart = false}) {
      final s = scope.trim();
      if (s.isEmpty) return;
      final b = block.trimRight();
      if (b.trim().isEmpty) return;
      final list = scopeParts.putIfAbsent(s, () => <String>[]);
      if (atStart) {
        list.insert(0, b);
      } else {
        list.add(b);
      }
    }

    bool needsRead = false;
    bool needsWrite = false;
    bool needsB2IN = false;
    final readReg = RegExp(r'\b(?:RECB|RMCB)\s*\(', caseSensitive: false);
    final writeReg = RegExp(r'\b(?:WECB|WMCB)\s*\(', caseSensitive: false);
    final b2inReg = RegExp(r'\bB2IN\s*\(', caseSensitive: false);

    final orderedMethods = renameMap.keys.toList()
      ..sort((left, right) {
        final a = relatedMethods[left];
        final b = relatedMethods[right];
        final lineOrder = (a?["line"] as int? ?? 0).compareTo(
          b?["line"] as int? ?? 0,
        );
        return lineOrder != 0 ? lineOrder : left.compareTo(right);
      });

    for (final method in orderedMethods) {
      final renamed = renameMap[method]!;
      final origins = _relatedMethodOrigins(relatedMethods[method]!);
      origins.sort((left, right) {
        final scopeOrder = (left["scope"] ?? '').toString().compareTo(
          (right["scope"] ?? '').toString(),
        );
        if (scopeOrder != 0) return scopeOrder;
        return (left["line"] as int? ?? 0).compareTo(
          right["line"] as int? ?? 0,
        );
      });

      for (final original in origins) {
        var devicePath = (original["path"] ?? ecScope).toString();
        if (method.toUpperCase().startsWith('_Q')) {
          for (final battery in batteryDevices) {
            final batteryPath = (battery["path"] ?? "").toString();
            if (BatteryExternalNormalizer.pathKey(devicePath) ==
                BatteryExternalNormalizer.pathKey(batteryPath)) {
              devicePath = (battery["scope"] ?? ecScope).toString();
              break;
            }
          }
        }

        final wrapper = _buildBatteryMethodWrapper(
          relatedMethod: original,
          renameTarget: renamed,
          renameTargetsMap: renameTargetsMap,
          usedFields: usedFields,
          bodyTransformer: (body) =>
              BatteryMultiTransformer.rewriteBatteryReferences(
                body: body,
                parentPath: ecScope,
                batteryNames: batteryNames,
              ),
          elseCallTarget: renamed,
          elseDirectCall: true,
          wrapperScope: devicePath,
        );

        if (!needsRead && readReg.hasMatch(wrapper)) needsRead = true;
        if (!needsWrite && writeReg.hasMatch(wrapper)) needsWrite = true;
        if (!needsB2IN && b2inReg.hasMatch(wrapper)) needsB2IN = true;
        addPart(devicePath, wrapper);
      }
    }

    // EC helper methods: 仅在需要读/写宽字节时生成，且按实际引用的 EC scope 放置
    final helperSpaces = <String, Set<String>>{};
    for (final f in usedFields) {
      final scope = (f["scope"] ?? "").toString().trim();
      if (scope.isEmpty) continue;
      final rawSpace = (f["regionSpace"] ?? "").toString();
      final space = rawSpace.toLowerCase() == "systemmemory"
          ? "SystemMemory"
          : "EmbeddedControl";
      helperSpaces.putIfAbsent(scope, () => <String>{}).add(space);
    }
    if (helperSpaces.isEmpty) {
      for (final ec in ecDevices) {
        final scope = (ec["path"] ?? "").toString().trim();
        if (scope.isNotEmpty) {
          helperSpaces[scope] = {"EmbeddedControl"};
        }
      }
    }
    for (final entry in helperSpaces.entries) {
      final spaces = entry.value.toList()..sort();
      for (final space in spaces) {
        if (needsWrite) {
          addPart(
            entry.key,
            _writeBatteryBufferMethod(writeWideField: true, regionSpace: space),
            atStart: true,
          );
        }
        if (needsRead) {
          addPart(
            entry.key,
            _readBatteryBufferMethod(hasWideField: true, regionSpace: space),
            atStart: true,
          );
        }
      }
    }

    // BATC device block (placed into batScope)
    final dartTwoBatteryBlock =
        """
	        Device (BATC)
	        {
	            Name (_HID, EisaId ("PNP0C0A"))
	            Name (_UID, 0x02)
	            Method (_INI, 0, NotSerialized)
	            {
	                If (_OSI ("Darwin"))
	                {
	                 ${_indentBlock(iniHide.toString().trimRight(), 20)}
	                }
	            }

	            Method (_STA, 0, NotSerialized)
	            {
	                If (_OSI ("Darwin"))
	                {
	                    Store (Zero, Local0)
	                    ${_indentBlock(staOr.toString().trimRight(), 20)}
	                    Return (Local0)
	                }
	                Return (Zero)
	            }

	            Name (B0CO, Zero)
	            Name (B1CO, Zero)
	            Name (B0DV, Zero)
	            Name (B1DV, Zero)

	            Method (_BIF, 0, NotSerialized)
	            {
	                // Local0 BAT0._BIF
	                // Local1 BAT1._BIF
	                // Local2 BAT0._STA
	                // Local3 BAT1._STA
	                // Local4/Local5 scratch

	                // gather and validate data from BAT0
	                Local0 = ^^BAT0._BIF ()
	                Local2 = ^^BAT0._STA ()
	                If (0x1f == Local2)
	                {
	                    // check for invalid design capacity
	                    Local4 = DerefOf (Local0 [1])
	                    If (!Local4 || Ones == Local4) { Local2 = 0; }
	                    // check for invalid last full charge capacity
	                    Local4 = DerefOf (Local0 [2])
	                    If (!Local4 || Ones == Local4) { Local2 = 0; }
	                    // check for invalid design voltage
	                    Local4 = DerefOf (Local0 [4])
	                    If (!Local4 || Ones == Local4) { Local2 = 0; }
	                }
	                // gather and validate data from BAT1
	                Local1 = ^^BAT1._BIF ()
	                Local3 = ^^BAT1._STA ()
	                If (0x1f == Local3)
	                {
	                    // check for invalid design capacity
	                    Local4 = DerefOf (Local1 [1])
	                    If (!Local4 || Ones == Local4) { Local3 = 0; }
	                    // check for invalid last full charge capacity
	                    Local4 = DerefOf (Local1 [2])
	                    If (!Local4 || Ones == Local4) { Local3 = 0; }
	                    // check for invalid design voltage
	                    Local4 = DerefOf (Local1 [4])
	                    If (!Local4 || Ones == Local4) { Local3 = 0; }
	                }
	                // find primary and secondary battery
	                If (0x1f != Local2 && 0x1f == Local3)
	                {
	                    // make primary use BAT1 data
	                    Local0 = Local1 // BAT1._BIF result
	                    Local2 = Local3 // BAT1._STA result
	                    Local3 = 0  // no secondary battery
	                }
	                // combine batteries into Local0 result if possible
	                If (0x1f == Local2 && 0x1f == Local3)
	                {
	                    // _BIF 0 Power Unit - leave BAT0 value
	                    // _BIF 1 Design Capacity - add BAT0 and BAT1 values
	                    Local4 = DerefOf (Local0 [1])
	                    Local5 = DerefOf (Local1 [1])
	                    If (0xffffffff != Local4 && 0xffffffff != Local5)
	                    {
	                        Local0 [1] = Local4 + Local5
	                    }
	                    // _BIF 2 Last Full Charge Capacity - add BAT0 and BAT1 values
	                    Local4 = DerefOf (Local0 [2])
	                    Local5 = DerefOf (Local1 [2])
	                    If (0xffffffff != Local4 && 0xffffffff != Local5)
	                    {
	                        Local0 [2] = Local4 + Local5
	                    }
	                    // _BIF 3 Battery Technology - leave BAT0 value
	                    // _BIF 4 Design Voltage - average between BAT0 and BAT1 values
	                    Local4 = DerefOf (Local0 [4])
	                    Local5 = DerefOf (Local1 [4])
	                    If (0xffffffff != Local4 && 0xffffffff != Local5)
	                    {
	                        Local0 [4] = (Local4 + Local5) / 2
	                    }
	                    // _BIF 5 Design Capacity of Warning - add BAT0 and BAT1 values
	                    Local0 [5] = DerefOf (Local0 [5]) + DerefOf (Local1 [5])
	                    // _BIF 6 Design Capacity of Low - add BAT0 and BAT1 values
	                    Local0 [6] = DerefOf (Local0 [6]) + DerefOf (Local1 [6])
	                    // _BIF 7 Battery Capacity Granularity 1 - add BAT0 and BAT1 values
	                    Local4 = DerefOf (Local0 [7])
	                    Local5 = DerefOf (Local1 [7])
	                    If (0xffffffff != Local4 && 0xffffffff != Local5)
	                    {
	                        Local0 [7] = Local4 + Local5
	                    }
	                    // _BIF 8 Battery Capacity Granularity 2 - add BAT0 and BAT1 values
	                    Local4 = DerefOf (Local0 [8])
	                    Local5 = DerefOf (Local1 [8])
	                    If (0xffffffff != Local4 && 0xffffffff != Local5)
	                    {
	                        Local0 [8] = Local4 + Local5
	                    }
	                    // _BIF 9 Model Number - concatenate BAT0 and BAT1 values
	                    Local0 [0x09] = Concatenate (Concatenate (DerefOf (Local0 [0x09]), " / "), DerefOf (Local1 [0x09]))
	                    // _BIF a Serial Number - concatenate BAT0 and BAT1 values
	                    Local0 [0x0a] = Concatenate (Concatenate (DerefOf (Local0 [0x0a]), " / "), DerefOf (Local1 [0x0a]))
	                    // _BIF b Battery Type - concatenate BAT0 and BAT1 values
	                    Local0 [0x0b] = Concatenate (Concatenate (DerefOf (Local0 [0x0b]), " / "), DerefOf (Local1 [0x0b]))
	                    // _BIF c OEM Information - concatenate BAT0 and BAT1 values
	                    Local0 [0x0c] = Concatenate (Concatenate (DerefOf (Local0 [0x0c]), " / "), DerefOf (Local1 [0x0c]))
	                }

	                Return (Local0)
	            }

	            Method (_BST, 0, NotSerialized)
	            {
	               // Local0 BAT0._BST
	                // Local1 BAT1._BST
	                // Local2 BAT0._STA
	                // Local3 BAT1._STA
	                // Local4/Local5 scratch

	                // gather battery data from BAT0
	                Local0 = ^^BAT0._BST ()
	                Local2 = ^^BAT0._STA ()
	                If (0x1f == Local2)
	                {
	                    // check for invalid remaining capacity
	                    Local4 = DerefOf (Local0 [2])
	                    If (!Local4 || Ones == Local4) { Local2 = 0; }
	                }
	                // gather battery data from BAT1
	                Local1 = ^^BAT1._BST ()
	                Local3 = ^^BAT1._STA ()
	                If (0x1f == Local3)
	                {
	                    // check for invalid remaining capacity
	                    Local4 = DerefOf (Local1 [2])
	                    If (!Local4 || Ones == Local4) { Local3 = 0; }
	                }
	                // find primary and secondary battery
	                If (0x1f != Local2 && 0x1f == Local3)
	                {
	                    // make primary use BAT1 data
	                    Local0 = Local1 // BAT1._BST result
	                    Local2 = Local3 // BAT1._STA result
	                    Local3 = 0  // no secondary battery
	                }
	                // combine batteries into Local0 result if possible
	                If (0x1f == Local2 && 0x1f == Local3)
	                {
	                    // _BST 0 - Battery State - if one battery is charging, then charging, else discharging
	                    Local4 = DerefOf (Local0 [0])
	                    Local5 = DerefOf (Local1 [0])
	                    If (Local4 != Local5)
	                    {
	                        If (Local4 == 2 || Local5 == 2)
	                        {
	                            // 2 = charging
	                            Local0 [0] = 2
	                        }
	                        ElseIf (Local4 == 1 || Local5 == 1)
	                        {
	                            // 1 = discharging
	                            Local0 [0] = 1
	                        }
	                        ElseIf (Local4 == 3 || Local5 == 3)
	                        {
	                            Local0 [0] = 3
	                        }
	                        ElseIf (Local4 == 4 || Local5 == 4)
	                        {
	                            // critical
	                            Local0 [0] = 4
	                        }
	                        ElseIf (Local4 == 5 || Local5 == 5)
	                        {
	                            // critical and discharging
	                            Local0 [0] = 5
	                        }
	                        // if none of the above, just leave as BAT0 is
	                    }

	                    // _BST 1 - Battery Present Rate - add BAT0 and BAT1 values
	                    Local0 [1] = DerefOf (Local0 [1]) + DerefOf (Local1 [1])
	                    // _BST 2 - Battery Remaining Capacity - add BAT0 and BAT1 values
	                    Local0 [2] = DerefOf (Local0 [2]) + DerefOf (Local1 [2])
	                    // _BST 3 - Battery Present Voltage - average between BAT0 and BAT1 values
	                    Local0 [3] = (DerefOf (Local0 [3]) + DerefOf (Local1 [3])) / 2
	                }
	                Return (Local0)
	            }
	        }
	      """;
    bool batteryHasMethod(Map<String, dynamic> battery, String name) {
      final methods = battery['methods'] as List<dynamic>? ?? const [];
      return methods.any(
        (method) => (method['name'] ?? '').toString().toUpperCase() == name,
      );
    }

    final allBif = batteryDevices.every(
      (battery) => batteryHasMethod(battery, '_BIF'),
    );
    final multiBatteryBlock = batteryDevices.length == 2 && allBif
        ? dartTwoBatteryBlock
              .replaceAll('BAT0', batteryNames[0])
              .replaceAll('BAT1', batteryNames[1])
        : _buildGenericMultiBatteryDevice(
            batteryDevices,
            allBif ? '_BIF' : '_BIX',
          );
    addPart(batScope, multiBatteryBlock, atStart: true);

    String buildScopeBlock(String scope, List<String> parts) {
      final merged = parts
          .map((p) => _dedentBlock(p).trimRight())
          .where((p) => p.trim().isNotEmpty)
          .toList();
      if (merged.isEmpty) return "";
      return """
	    Scope ($scope)
	    {
${_indentBlock(merged.join("\n\n"), 8)}
	    }""";
    }

    final orderedScopes = scopeParts.keys.toList()..sort();
    if (batScope.trim().isNotEmpty && orderedScopes.remove(batScope)) {
      orderedScopes.insert(0, batScope);
    }
    final scopeBlocks = orderedScopes
        .map((s) => buildScopeBlock(s, scopeParts[s]!))
        .where((s) => s.trim().isNotEmpty)
        .join("\n\n");

    final rootBlocks = <String>[];
    if (externalLines.trim().isNotEmpty) {
      rootBlocks.add(externalLines.trimRight());
    }
    if (needsB2IN) {
      rootBlocks.add(
        _indentBlock(
          _dedentBlock(_bufferToIntegerMethod(hasWideField: true)).trimRight(),
          4,
        ),
      );
    }
    if (scopeBlocks.trim().isNotEmpty) {
      rootBlocks.add(scopeBlocks.trimRight());
    }

    return """
	DefinitionBlock ("", "SSDT", 2, "RAPID", "BATC", 0x00000000)
	{
${rootBlocks.join("\n\n")}
	}
	""";
  }

  /// 构建单电池SSDT
  String _buildSingleBatterySsdt({
    required List<Map<String, dynamic>> ecDevices,
    required Map<String, Map<String, dynamic>> relatedMethods,
    required String externalLines,
    required Map<String, String> wrappers,
    required List<Map<String, dynamic>> usedFields,
  }) {
    final wrapperText = wrappers.values.join("\n\n");
    final needsRead = RegExp(
      r'\b(?:RECB|RMCB)\s*\(',
      caseSensitive: false,
    ).hasMatch(wrapperText);
    final needsWrite = RegExp(
      r'\b(?:WECB|WMCB)\s*\(',
      caseSensitive: false,
    ).hasMatch(wrapperText);
    final needsB2IN = RegExp(
      r'\bB2IN\s*\(',
      caseSensitive: false,
    ).hasMatch(wrapperText);

    // 合并相同 Scope，避免生成重复作用域
    final scopeParts = <String, List<String>>{};
    void addPart(String scope, String block) {
      final s = scope.trim();
      if (s.isEmpty) return;
      final b = block.trimRight();
      if (b.trim().isEmpty) return;
      scopeParts.putIfAbsent(s, () => []).add(b);
    }

    // EC helper methods: 仅在需要读/写宽字节时生成，且按实际引用的 EC scope 放置
    final helperSpaces = <String, Set<String>>{};
    for (final f in usedFields) {
      final scope = (f["scope"] ?? "").toString().trim();
      if (scope.isEmpty) continue;
      final rawSpace = (f["regionSpace"] ?? "").toString();
      final space = rawSpace.toLowerCase() == "systemmemory"
          ? "SystemMemory"
          : "EmbeddedControl";
      helperSpaces.putIfAbsent(scope, () => <String>{}).add(space);
    }
    if (helperSpaces.isEmpty) {
      for (final ec in ecDevices) {
        final scope = (ec["path"] ?? "").toString().trim();
        if (scope.isNotEmpty) {
          helperSpaces[scope] = {"EmbeddedControl"};
        }
      }
    }
    for (final entry in helperSpaces.entries) {
      final spaces = entry.value.toList()..sort();
      for (final space in spaces) {
        if (needsRead) {
          addPart(
            entry.key,
            _readBatteryBufferMethod(hasWideField: true, regionSpace: space),
          );
        }
        if (needsWrite) {
          addPart(
            entry.key,
            _writeBatteryBufferMethod(writeWideField: true, regionSpace: space),
          );
        }
      }
    }

    // 方法包装器按原 Scope 和源表顺序输出
    final orderedMethods = relatedMethods.keys.toList()
      ..sort((left, right) {
        final a = relatedMethods[left]!;
        final b = relatedMethods[right]!;
        final scopeOrder = (a["scope"] ?? "").toString().compareTo(
          (b["scope"] ?? "").toString(),
        );
        if (scopeOrder != 0) return scopeOrder;
        final lineOrder = (a["line"] as int? ?? 0).compareTo(
          b["line"] as int? ?? 0,
        );
        return lineOrder != 0 ? lineOrder : left.compareTo(right);
      });
    for (final methodName in orderedMethods) {
      final scope = (relatedMethods[methodName]?["scope"] ?? "").toString();
      final wrapper = wrappers[methodName] ?? "";
      addPart(scope, wrapper);
    }

    String buildScopeBlock(String scope, List<String> parts) {
      final merged = parts
          .map((p) => _dedentBlock(p).trimRight())
          .where((p) => p.trim().isNotEmpty)
          .toList();
      if (merged.isEmpty) return "";
      return """
    Scope ($scope)
    {
${_indentBlock(merged.join("\n\n"), 8)}
    }""";
    }

    final orderedScopes = scopeParts.keys.toList()..sort();
    final scopeBlocks = orderedScopes
        .map((s) => buildScopeBlock(s, scopeParts[s]!))
        .where((s) => s.trim().isNotEmpty)
        .join("\n\n");

    final rootBlocks = <String>[];
    if (externalLines.trim().isNotEmpty) {
      rootBlocks.add(externalLines.trimRight());
    }
    if (needsB2IN) {
      rootBlocks.add(
        _indentBlock(
          _dedentBlock(_bufferToIntegerMethod(hasWideField: true)).trimRight(),
          4,
        ),
      );
    }
    if (scopeBlocks.trim().isNotEmpty) {
      rootBlocks.add(scopeBlocks.trimRight());
    }

    return """
DefinitionBlock ("", "SSDT", 2, "RAPID", "BAT", 0x00000000)
{
${rootBlocks.join("\n\n")}
}
""";
  }

  /// 将字符串转换为十六进制表示
  String _nameToHex(String name) => name.codeUnits
      .map((c) => c.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join();

  /// 重命名方法名，默认使用 `X` 前缀；若出现同名冲突，则自动尝试 `Y/Z/W...` 以避免重复。
  ///
  /// - 只生成 4 字符 NameSeg
  /// - `usedNames` 用于避免同一轮生成过程中出现重名
  String _renamedMethodName(String methodName, {Set<String>? usedNames}) {
    final raw = methodName.trim().toUpperCase();
    final n = raw.length >= 4 ? raw.substring(0, 4) : raw.padRight(4, '_');
    final suffix = n.substring(1); // 3 chars

    const leads = <String>[
      'X',
      'Y',
      'Z',
      'W',
      'V',
      'U',
      'T',
      'S',
      'R',
      'Q',
      'P',
      'O',
      'N',
      'M',
      'L',
      'K',
      'J',
      'I',
      'H',
      'G',
      'F',
      'E',
      'D',
      'C',
      'B',
      'A',
    ];

    if (usedNames == null) {
      return "X$suffix";
    }

    for (final lead in leads) {
      final candidate = "$lead$suffix";
      // 避免 no-op rename（例如原本就是 X???）
      if (candidate == n) continue;
      if (!usedNames.contains(candidate)) return candidate;
    }

    // 理论上不会走到这里（除非同 suffix 的重命名数量过多）。
    return "X$suffix";
  }

  /// 缩进代码块，每个行前添加指定数量的空格
  String _indentBlock(String input, int spaces) {
    final pad = " " * spaces;
    return input.split("\n").map((line) => "$pad$line").join("\n");
  }

  /// 移除代码块的首尾空行和公共缩进
  String _dedentBlock(String input) {
    var lines = input.replaceAll("\r\n", "\n").split("\n");
    while (lines.isNotEmpty && lines.first.trim().isEmpty) {
      lines = lines.sublist(1);
    }
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines = lines.sublist(0, lines.length - 1);
    }
    if (lines.isEmpty) return "";

    var minIndent = 1 << 30;
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final indent = line.length - line.trimLeft().length;
      if (indent < minIndent) minIndent = indent;
    }
    if (minIndent == (1 << 30)) minIndent = 0;

    final out = <String>[];
    for (final line in lines) {
      if (line.trim().isEmpty) {
        out.add("");
        continue;
      }
      out.add(
        line.length >= minIndent ? line.substring(minIndent) : line.trimLeft(),
      );
    }
    return out.join("\n");
  }

  /// 构建电池方法包装器
  String _buildBatteryMethodWrapper({
    required Map<String, dynamic> relatedMethod,
    required String renameTarget,
    required Map<String, Map<String, dynamic>> renameTargetsMap,
    required List<Map<String, dynamic>> usedFields,
    String Function(String body)? bodyTransformer,
    String? elseCallTarget,
    bool elseDirectCall = false,
    String? wrapperScope,
  }) {
    final methodName = relatedMethod["name"] as String? ?? "";
    final originalBlock = relatedMethod["text"] as String? ?? "";
    final argCount = relatedMethod["argCount"];
    final methodFlag = relatedMethod["flags"];

    // 关键修复1：保留原始缩进，不盲目trim()
    final bodyStart = originalBlock.indexOf("{");
    final bodyEnd = originalBlock.lastIndexOf("}");
    String body = "";
    if (bodyStart >= 0 && bodyEnd > bodyStart) {
      // 截取时保留所有字符（包括空格/缩进），只去掉首尾的{和}
      body = originalBlock.substring(bodyStart + 1, bodyEnd);
      // 仅去掉首尾空白，保留中间缩进
      body = body.trimLeft().trimRight();
    } else {
      body =
          "Return (${_buildMethodCall(renameTarget, renameTargetsMap[renameTarget]!)})";
    }

    final transformed = BatteryBodyTransformer.transform(
      body: body,
      methodName: methodName,
      semantics: BatteryMethodSemantics(
        bif: relatedMethod["batteryBif"] == true,
        bix: relatedMethod["batteryBix"] == true,
        bst: relatedMethod["batteryBst"] == true,
      ),
      fields: usedFields,
    );
    if (!transformed.valid) {
      throw StateError('$methodName 电池字段转换失败：${transformed.error}');
    }
    body = transformed.body;
    for (final message in transformed.logs) {
      Log(message);
    }

    // 在字段替换完成后，再执行bodyTransformer
    if (bodyTransformer != null) {
      body = bodyTransformer(body);
    }

    final methodScope = (relatedMethod["scope"] ?? "").toString();
    final methodPath = methodScope.isEmpty
        ? methodName
        : "$methodScope.$methodName";
    final namespaceResolution = BatteryNamespaceResolver.resolveBody(
      body: body,
      methodPath: methodPath,
      objects: _batteryNamespaceObjects,
      generatedObjects: {
        "B2IN",
        BatteryExternalNormalizer.pathKey("$methodScope.RECB"),
        BatteryExternalNormalizer.pathKey("$methodScope.RE1B"),
        BatteryExternalNormalizer.pathKey("$methodScope.WECB"),
        BatteryExternalNormalizer.pathKey("$methodScope.WE1B"),
        BatteryExternalNormalizer.pathKey("$methodScope.RMCB"),
        BatteryExternalNormalizer.pathKey("$methodScope.RM1B"),
        BatteryExternalNormalizer.pathKey("$methodScope.WMCB"),
        BatteryExternalNormalizer.pathKey("$methodScope.WM1B"),
        BatteryExternalNormalizer.pathKey("$methodScope.BATC"),
      },
    );
    body = namespaceResolution.body;
    _batteryBodyExternals.addAll(namespaceResolution.externals);

    final elseTarget = elseCallTarget ?? renameTarget;
    final elseMethod = elseTarget == renameTarget
        ? relatedMethod
        : renameTargetsMap[elseTarget]!;
    final elseCallExpr = _buildMethodCall(
      renameTarget,
      elseMethod,
      fromScope: wrapperScope ?? methodScope,
    );

    // 检查原始方法是否有返回值
    final hasReturn = originalBlock.contains(
      RegExp(r'\bReturn\b', caseSensitive: false),
    );

    // 构建Else分支
    String elseBranch;
    if (hasReturn) {
      elseBranch = "                Return ($elseCallExpr)";
    } else {
      elseBranch = "               $elseCallExpr";
    }

    return """Method ($methodName, $argCount, $methodFlag)
{
    If (_OSI ("Darwin"))
    {
${_indentBlock(body, 8)}
    }
    Else
    {
$elseBranch
    }
}""";
  }

  /// 构建方法调用表达式
  String _buildMethodCall(
    String renameTarget,
    Map<String, dynamic> method, {
    String? fromScope,
  }) {
    final argCount = method["argCount"] as int? ?? 0;
    final args = List.generate(argCount, (i) => "Arg$i").join(", ");
    final scope = method["scope"] as String? ?? "";
    if (fromScope != null &&
        BatteryExternalNormalizer.pathKey(fromScope) ==
            BatteryExternalNormalizer.pathKey(scope)) {
      return "$renameTarget ($args)";
    }
    return "$scope.$renameTarget ($args)";
  }

  /// 检查方法体中是否使用了超过8字节的EC字段。
  /// 如果方法体中使用了超过8字节的字段，则返回true；否则返回false。
  (bool, Set<String>) _methodAccessesWideFields({
    required String? methodText,
    required List<Map<String, dynamic>> fieldList,
  }) {
    if (methodText == null || methodText.isEmpty) return (false, {});

    // 提取方法体中使用的所有变量名
    final variables = _extractUsedVariables(methodText);
    final wideFields = <String>{};
    // 检查是否有变量超过8字节
    for (final variable in variables) {
      final fieldInfo = fieldList.firstWhere(
        (field) =>
            (field["name"] ?? "").toString().toUpperCase() ==
            variable.toUpperCase(),
        orElse: () => const {},
      );

      if (fieldInfo.isNotEmpty) {
        final bitLength = fieldInfo["bitLength"] as int? ?? 0;
        if (bitLength > 8) {
          wideFields.add(variable);
        }
      }
    }

    return (wideFields.isNotEmpty, wideFields);
  }

  /// 提取方法体中使用的所有变量名
  Set<String> _extractUsedVariables(String methodBody) {
    final variables = <String>{};

    // 匹配变量名，排除方法名和关键字
    final regex = RegExp(r'\b([A-Za-z_][A-Za-z0-9_]*)\b');
    final matches = regex.allMatches(methodBody);

    const ignoreKeywords = {
      "METHOD",
      "IF",
      "ELSE",
      "ELSEIF",
      "RETURN",
      "STORE",
      "AND",
      "OR",
      "NOT",
      "LAND",
      "LOR",
      "LNOT",
      "LEQUAL",
      "LNOTEQUAL",
      "LGREATER",
      "LGREATEREQUAL",
      "LLESS",
      "LLESSEQUAL",
      "ADD",
      "SUBTRACT",
      "MULTIPLY",
      "DIVIDE",
      "MOD",
      "SHL",
      "SHR",
      "SAR",
      "XOR",
      "CONCAT",
      "MATCH",
      "FINDSET",
      "FINDSETREVERSE",
      "DEREF",
      "INDEX",
      "LENGTH",
      "SIZE",
      "TOSTRING",
      "TOINTEGER",
      "TOBUFFER",
      "TOUUID",
      "COPBUFF",
      "ALLOCATE",
      "FREE",
      "ACQUIRE",
      "RELEASE",
      "SLEEP",
      "STALL",
      "NOTIFY",
      "SIGNAL",
      "SYNCOPT",
      "DEBUG",
      "ASSERT",
      "RESET",
      "PWRSRC",
      "ACPI_METHOD",
      "ARG0",
      "ARG1",
      "ARG2",
      "ARG3",
      "ARG4",
      "ARG5",
      "ARG6",
      "ARG7",
      "LOCAL0",
      "LOCAL1",
      "LOCAL2",
      "LOCAL3",
      "LOCAL4",
      "LOCAL5",
      "LOCAL6",
      "LOCAL7",
      "TRUE",
      "FALSE",
      "ZERO",
      "ONE",
      "ONES",
      "ON",
    };

    for (final match in matches) {
      final variable = match.group(1)?.toUpperCase() ?? "";
      if (variable.isNotEmpty && !ignoreKeywords.contains(variable)) {
        variables.add(variable);
      }
    }

    return variables;
  }

  /// 提取方法体中调用的所有方法引用
  Set<String> _extractInvokedMethodReferences(String methodBlock) {
    const ignore = <String>{
      "METHOD",
      "IF",
      "ELSE",
      "ELSEIF",
      "RETURN",
      "STORE",
      "AND",
      "OR",
      "XOR",
      "DECREMENT",
      "NOT",
      "LAND",
      "LOR",
      "CASE",
      "SWITCH",
      "TOINTEGER",
      "TOBCD",
      "INCREMENT",
      "REFOF",
      "CREATEBYTEFIELD",
      "LNOT",
      "LEQUAL",
      "LNOTEQUAL",
      "LGREATER",
      "LGREATEREQUAL",
      "LLESS",
      "LLESSEQUAL",
      "SHIFTLEFT",
      "SHIFTRIGHT",
      "MULTIPLY",
      "DIVIDE",
      "SUBTRACT",
      "ADD",
      "SLEEP",
      "WHILE",
      "ACQUIRE",
      "RELEASE",
      "CONDREFOF",
      "DEREFOF",
      "INDEX",
      "PACKAGE",
      "BUFFER",
      "NAME",
      "SIZEOF",
      "NOTIFY",
      "TOSTRING",
      "TODECIMALSTRING",
      "MID",
      "CONCATENATE",
      "COPYOBJECT",
      "DEBUG",
      "_OSI",
    };

    final out = <String>{};
    final callReg = RegExp(
      r'(?<![A-Za-z0-9_])((?:[\\^]+)?[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)\s*\(',
      caseSensitive: false,
    );
    for (final m in callReg.allMatches(methodBlock)) {
      final reference = (m.group(1) ?? "").toUpperCase();
      final name = reference.split('.').last;
      if (name.isEmpty || ignore.contains(name)) continue;
      if (RegExp(r'^[0-9]+$').hasMatch(name)) continue;
      if (name.length != 4) continue;
      out.add(reference);
    }
    return out;
  }

  List<Map<String, String>> _extractUsedSymbols(List<String> methodTexts) {
    final results = <String, Map<String, String>>{};

    /// 匹配完整 ACPI NamePath
    final pathPattern = RegExp(r'(\\[A-Za-z0-9_.]+|\^{1,}[A-Za-z0-9_.]+)');

    /// 匹配普通 NameSeg
    final nameSegPattern = RegExp(
      r'(^|[^A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]{2,3})(?=[^A-Za-z0-9_]|$)',
    );

    for (var methodText in methodTexts) {
      // 去单行注释
      methodText = methodText.replaceAll(RegExp(r'//.*'), '');

      // 去多行注释
      methodText = methodText.replaceAll(
        RegExp(r'/\*.*?\*/', dotAll: true),
        '',
      );

      // 去字符串
      methodText = methodText.replaceAll(RegExp(r'"[^"]*"'), '');

      // 移除 Method 头
      methodText = methodText.replaceAll(
        RegExp(r'^\s*Method\s*\([^\)]*\)', multiLine: true),
        '',
      );

      /// ① 解析完整路径
      for (final match in pathPattern.allMatches(methodText)) {
        final raw = match.group(0)!;
        final name = raw.split('.').last.toUpperCase();

        if (_isKeyword(name)) continue;

        final rest = methodText.substring(match.end).trimLeft();
        final isMethodCall = rest.startsWith('(');

        results[name] = {
          "name": name,
          "path": raw,
          "type": isMethodCall ? "method" : "variable",
        };
      }

      /// ② 解析普通 NameSeg
      for (final match in nameSegPattern.allMatches(methodText)) {
        final symbol = match.group(2)!;
        final name = symbol.toUpperCase();

        if (_isKeyword(name)) continue;

        if (results.containsKey(name)) continue;

        final rest = methodText.substring(match.end).trimLeft();
        final isMethodCall = rest.startsWith('(');

        results[name] = {
          "name": name,
          "path": name,
          "type": isMethodCall ? "method" : "variable",
        };
      }
    }

    return results.values.toList();
  }

  /// 检查方法是否包含 Notify (BATx 通知
  Set<String> _extractBatteryNotifyTargets(
    String methodText,
    Set<String> batteryNames,
  ) {
    final out = <String>{};
    for (final batteryName in batteryNames) {
      final reg = RegExp(
        r'Notify\s*\(\s*(?:[\\^A-Z0-9_\.]+\.)?' +
            RegExp.escape(batteryName) +
            r'\s*,',
        caseSensitive: false,
      );
      if (reg.hasMatch(methodText)) {
        out.add(batteryName.toUpperCase());
      }
    }
    return out;
  }

  /// 构建方法的完整路径，格式为 Scope.Name
  String _methodFullPath(String scope, String name) =>
      "${scope.trim()}.${name.trim().toUpperCase()}";

  /// 按 ACPI NameString 规则解析方法引用
  Map<String, dynamic>? _resolveMethodReference({
    required String reference,
    required String callerPath,
    required Map<String, Map<String, dynamic>> byFullPath,
    required Map<String, Map<String, dynamic>> byPathKey,
    required Map<String, List<Map<String, dynamic>>> byName,
  }) {
    for (final candidate in BatteryNamespaceResolver.lookupCandidates(
      reference,
      callerPath,
    )) {
      final normalized = BatteryExternalNormalizer.normalizePath(candidate);
      final hit = byFullPath[normalized];
      if (hit != null) return hit;
      final candidateKey = BatteryExternalNormalizer.pathKey(candidate);
      final normalizedHit = byPathKey[candidateKey];
      if (normalizedHit != null) return normalizedHit;
    }

    final upper = reference.split('.').last.toUpperCase();
    // 无法按路径解析时，仅允许回退到全局唯一的同名方法。
    final candidates = byName[upper];
    if (candidates == null || candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;
    return null;
  }

  /// 收集所有已加载 ACPI 表中的方法，包括 EC/BAT 嵌套 Device 与独立 SSDT。
  List<Map<String, dynamic>> _allBatteryNamespaceMethods() {
    final methods = <Map<String, dynamic>>[];
    for (final tableEntry in d.acpiTables.entries) {
      final table = tableEntry.value;
      if (table is! Map<String, dynamic>) continue;
      final paths = table["paths"] as List<dynamic>? ?? const [];
      for (final rawPath in paths) {
        if (rawPath is! List || rawPath.length < 3) continue;
        if (rawPath[2].toString().toUpperCase() != "METHOD") continue;
        final fullPath = BatteryExternalNormalizer.normalizePath(
          rawPath[0].toString(),
        );
        final separator = fullPath.lastIndexOf('.');
        if (separator <= 0) continue;
        final line = rawPath[1] is int
            ? rawPath[1] as int
            : int.tryParse(rawPath[1].toString()) ?? -1;
        if (line < 0) continue;
        final scopeLines = d.getScope(
          startingIndex: line,
          stripComments: true,
          table: table,
        );
        if (scopeLines.isEmpty) continue;
        final text = scopeLines.join("\n").trim();
        final header = RegExp(
          r'^\s*Method\s*\(\s*([^,]+)\s*,\s*(\d+)\s*,\s*([^,\)]+)',
          caseSensitive: false,
        ).firstMatch(text);
        final name = fullPath.substring(separator + 1).toUpperCase();
        methods.add({
          "text": text,
          "type": "MethodObj",
          "name": name,
          "argCount": int.tryParse(header?.group(2) ?? "0") ?? 0,
          "flags": (header?.group(3) ?? "NotSerialized").trim(),
          "line": line,
          "scope": fullPath.substring(0, separator),
          "path": fullPath.substring(0, separator),
          "tableName": tableEntry.key,
        });
      }
    }
    return methods;
  }

  (
    List<Map<String, dynamic>>,
    Map<String, Map<String, dynamic>>,
    Map<String, Map<String, dynamic>>,
    Set<String>,
  )
  _buildBatteryDependencyTable({
    required List<Map<String, dynamic>> batteryDevices,
    required List<Map<String, dynamic>> ecDevices,
    required Set<String> entryMethods,
    required bool includeAllReachableMethods,
  }) {
    final batteryNames = batteryDevices
        .map((e) => (e["name"] ?? "").toString().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    // 收集所有EC字段，用于宽字节检测（bitLength > 8 或 byteLength > 1）
    final allEcFields = <Map<String, dynamic>>[];
    final ecFieldByName = <String, Map<String, dynamic>>{};
    for (final ecDevice in ecDevices) {
      final opRegions =
          ecDevice["operationRegions"] as List<dynamic>? ?? const [];
      final opRegionByName = <String, Map<String, dynamic>>{};
      for (final op in opRegions) {
        final name = (op["name"] ?? "").toString().toUpperCase();
        if (name.isEmpty) continue;
        opRegionByName.putIfAbsent(name, () => op);
      }

      final scopeFields = ecDevice["scopeFields"] as List<dynamic>? ?? const [];
      for (final block in scopeFields) {
        final regionName = (block["regionName"] ?? "").toString().trim();
        final regionKey = regionName.toUpperCase();
        final op = opRegionByName[regionKey];
        final indexed = block["indexed"] == true;
        if (indexed) {
          final warning =
              "${ecDevice["path"]} 包含间接 IndexField；字段位置已解析为控制器相对寄存器偏移。";
          if (_batteryRegionWarnings.add(warning)) Log.warning(warning);
        }
        final rawRegionSpace = (op?["space"] ?? "").toString();
        final supportedRegion =
            rawRegionSpace.toLowerCase() == "embeddedcontrol" ||
            rawRegionSpace.toLowerCase() == "systemmemory";
        if (!indexed && (op == null || !supportedRegion)) continue;

        final originOffset = indexed ? 0 : (op!["offset"] as int? ?? 0);
        final regionSpace = indexed ? "EmbeddedControl" : rawRegionSpace;
        final originExpression = indexed
            ? null
            : (op!["offsetExpression"] as String?);

        final fieldList = block["fields"] as List<dynamic>? ?? const [];
        for (final rawField in fieldList) {
          final field = Map<String, dynamic>.from((rawField as Map));
          // 为后续 RECB/WECB 计算绝对偏移做准备
          field["regionName"] = regionName;
          field["regionSpace"] = regionSpace;
          field["originOffset"] = originOffset;
          field["originExpression"] = originExpression;
          allEcFields.add(field);
          final n = (field["name"] ?? "").toString().toUpperCase();
          if (n.isNotEmpty) {
            ecFieldByName.putIfAbsent(n, () => field);
          }
        }
      }
    }

    // 收集所有 Mutex 定义，便于在依赖表中记录
    final mutexByName = <String, Map<String, dynamic>>{};
    for (final dev in [...batteryDevices, ...ecDevices]) {
      final mutexs = dev["mutexs"] as List<dynamic>? ?? const [];
      for (final rawMutex in mutexs) {
        final n = rawMutex["name"] ?? "";
        if (n.isEmpty) continue;
        mutexByName.putIfAbsent(n, () => rawMutex);
      }
    }

    // 方法索引：fullPath -> methodMap，name -> [methodMap...]
    final byFullPath = <String, Map<String, dynamic>>{};
    final byPathKey = <String, Map<String, dynamic>>{};
    final byName = <String, List<Map<String, dynamic>>>{};

    void indexMethod(Map<String, dynamic> method) {
      final rawName = (method["name"] ?? "").toString();
      final scope = (method["scope"] ?? "").toString();
      if (rawName.isEmpty || scope.isEmpty) return;

      final name = rawName.toUpperCase();
      final normalized = Map<String, dynamic>.from(method)
        ..["name"] = name
        // Multi-battery SSDT 生成处历史上使用过 path 字段，这里做兼容，不改生成逻辑。
        ..["path"] = method["path"] ?? scope;

      final fullPath = _methodFullPath(scope, name);
      byFullPath.putIfAbsent(fullPath, () => normalized);
      byPathKey.putIfAbsent(
        BatteryExternalNormalizer.pathKey(fullPath),
        () => normalized,
      );
      final sameName = byName.putIfAbsent(name, () => []);
      if (!sameName.any(
        (item) =>
            BatteryExternalNormalizer.pathKey(
              _methodFullPath(
                (item["scope"] ?? "").toString(),
                (item["name"] ?? "").toString(),
              ),
            ) ==
            BatteryExternalNormalizer.pathKey(fullPath),
      )) {
        sameName.add(normalized);
      }
    }

    for (final method in _allBatteryNamespaceMethods()) {
      indexMethod(method);
    }
    for (final bat in batteryDevices) {
      final methods = bat["methods"] as List<dynamic>? ?? const [];
      for (final m in methods) {
        indexMethod(m);
      }
    }
    for (final ec in ecDevices) {
      final methods = ec["methods"] as List<dynamic>? ?? const [];
      for (final m in methods) {
        indexMethod(m);
      }
    }
    // 从标准 _BIF/_BIX/_BST 根方法沿调用链传播语义。
    // 不能按 XBIF、GBIF 等辅助方法名猜测，否则会把字符串槽位当成整数。
    final semanticsByPath = <String, BatteryMethodSemantics>{};
    final callsByPath = <String, Set<String>>{};
    for (final entry in byFullPath.entries) {
      final method = entry.value;
      final name = (method["name"] ?? "").toString().toUpperCase();
      final seed = BatteryMethodSemantics(
        bif: name == "_BIF",
        bix: name == "_BIX",
        bst: name == "_BST",
      );
      if (!seed.isEmpty) semanticsByPath[entry.key] = seed;
      final callees = <String>{};
      for (final childReference in _extractInvokedMethodReferences(
        (method["text"] ?? "").toString(),
      )) {
        final child = _resolveMethodReference(
          reference: childReference,
          callerPath: entry.key,
          byFullPath: byFullPath,
          byPathKey: byPathKey,
          byName: byName,
        );
        if (child == null) continue;
        final childScope = (child["scope"] ?? "").toString();
        final childSeg = (child["name"] ?? "").toString().toUpperCase();
        if (childScope.isNotEmpty && childSeg.isNotEmpty) {
          callees.add(_methodFullPath(childScope, childSeg));
        }
      }
      callsByPath[entry.key] = callees;
    }
    var semanticsChanged = true;
    while (semanticsChanged) {
      semanticsChanged = false;
      for (final entry in callsByPath.entries) {
        final source = semanticsByPath[entry.key];
        if (source == null || source.isEmpty) continue;
        for (final callee in entry.value) {
          final old = semanticsByPath[callee] ?? const BatteryMethodSemantics();
          final merged = old.merge(source);
          if (merged.bif != old.bif ||
              merged.bix != old.bix ||
              merged.bst != old.bst) {
            semanticsByPath[callee] = merged;
            semanticsChanged = true;
          }
        }
      }
    }

    // Roots: 电池标准方法 + EC 作用域 Notify(BATx, ...) 方法
    final rootFullPaths = <String>{};
    for (final bat in batteryDevices) {
      final scope = (bat["path"] ?? bat["scope"] ?? "").toString();
      if (scope.isEmpty) continue;
      final methods = bat["methods"] as List<dynamic>? ?? const [];
      for (final m in methods) {
        final name = m["name"] ?? "";
        if (name.isEmpty) continue;
        if (!entryMethods.contains(name)) continue;
        rootFullPaths.add(_methodFullPath(scope, name));
      }
    }
    for (final entry in byFullPath.entries) {
      final method = entry.value;
      final text = (method["text"] ?? "").toString();
      if (_extractBatteryNotifyTargets(text, batteryNames).isNotEmpty) {
        rootFullPaths.add(entry.key);
      }
    }

    final nodeCache = <String, Map<String, dynamic>?>{};
    Map<String, dynamic>? buildNode(String fullPath, Set<String> stack) {
      if (nodeCache.containsKey(fullPath)) return nodeCache[fullPath];
      if (stack.contains(fullPath)) return null;
      stack.add(fullPath);

      final method = byFullPath[fullPath];
      if (method == null) {
        stack.remove(fullPath);
        nodeCache[fullPath] = null;
        return null;
      }

      final name = (method["name"] ?? "").toString().toUpperCase();
      final text = (method["text"] ?? "").toString();
      final scope = (method["scope"] ?? "").toString();
      final argCount = method["argCount"] as int? ?? 0;
      final flags = (method["flags"] ?? "NotSerialized").toString();

      // Notify(BATx, ...)
      final notifyTargets = _extractBatteryNotifyTargets(text, batteryNames);

      // 宽字节(>8bit)字段
      final (hasWideFields, wideFieldNames) = _methodAccessesWideFields(
        methodText: text,
        fieldList: allEcFields,
      );
      final fields = <Map<String, dynamic>>[];
      for (final f in wideFieldNames) {
        final field = ecFieldByName[f.toUpperCase()];
        if (field != null) {
          final bitLen = field["bitLength"] as int? ?? 0;
          final byteLen = field["byteLength"] as int? ?? 0;
          if (bitLen > 8 || byteLen > 1) {
            fields.add(field);
          }
        }
      }

      // Mutex 使用情况
      final mutexs = <Map<String, dynamic>>[];
      final usedTokens = _extractUsedVariables(text);
      for (final token in usedTokens) {
        final hit = mutexByName[token.toUpperCase()];
        if (hit != null) {
          mutexs.add(hit);
        }
      }

      // 子方法依赖
      final invoked = _extractInvokedMethodReferences(text).toList()..sort();
      final children = <Map<String, dynamic>>[];
      for (final childReference in invoked) {
        final child = _resolveMethodReference(
          reference: childReference,
          callerPath: fullPath,
          byFullPath: byFullPath,
          byPathKey: byPathKey,
          byName: byName,
        );
        if (child == null) continue;
        final childScope = (child["scope"] ?? "").toString();
        final childSeg = (child["name"] ?? "").toString().toUpperCase();
        if (childScope.isEmpty || childSeg.isEmpty) continue;
        final childFull = _methodFullPath(childScope, childSeg);
        final childNode = buildNode(childFull, stack);
        if (childNode != null) {
          children.add(childNode);
        }
      }

      // 单电池：仅保留“自身或子链路”访问宽字节的方法；多电池：所有可达方法均保留
      final include =
          includeAllReachableMethods || hasWideFields || children.isNotEmpty;
      if (!include) {
        stack.remove(fullPath);
        nodeCache[fullPath] = null;
        return null;
      }

      final node = <String, dynamic>{
        "name": name,
        "text": text,
        "type": "MethodObj",
        "argCount": argCount,
        "flags": flags,
        "line": method["line"] ?? 0,
        "scope": scope,
        // 兼容历史字段：部分多电池 wrapper 生成逻辑读取 path
        "path": method["path"] ?? scope,
        "batteryBif": semanticsByPath[fullPath]?.bif ?? false,
        "batteryBix": semanticsByPath[fullPath]?.bix ?? false,
        "batteryBst": semanticsByPath[fullPath]?.bst ?? false,
        "fields": fields,
        "mutexs": mutexs,
        "notifyTargets": (notifyTargets.toList()..sort()),
        "methods": children,
      };

      stack.remove(fullPath);
      nodeCache[fullPath] = node;
      return node;
    }

    final depTable = <Map<String, dynamic>>[];
    final orderedRoots = rootFullPaths.toList()..sort();
    for (final root in orderedRoots) {
      final node = buildNode(root, <String>{});
      if (node != null) depTable.add(node);
    }

    // 由依赖表T导出：需要重命名/包装的方法集合 + 宽字节字段集合 + Mutex 使用集合
    final renameMethods = <String, Map<String, dynamic>>{};
    final wideFields = <String, Map<String, dynamic>>{};
    final usedMutexNames = <String>{};

    final visited = <String>{};
    final duplicateRename = <String, Set<String>>{};

    void walk(Map<String, dynamic> node) {
      final scope = (node["scope"] ?? "").toString();
      final name = (node["name"] ?? "").toString().toUpperCase();
      final key = _methodFullPath(scope, name);
      if (visited.contains(key)) return;
      visited.add(key);

      // 统计 Mutex
      final mutexs = node["mutexs"] as List<dynamic>? ?? const [];
      for (final raw in mutexs) {
        final mutex = raw;
        final mName = (mutex["name"] ?? "").toString().toUpperCase();
        if (mName.isNotEmpty) usedMutexNames.add(mName);
      }

      // 统计宽字段
      final fields = node["fields"] as List<dynamic>? ?? const [];
      for (final raw in fields) {
        final field = raw;
        final fName = (field["name"] ?? "").toString().toUpperCase();
        if (fName.isNotEmpty) {
          wideFields.putIfAbsent(fName, () => field);
        }
      }

      final notifyTargets = node["notifyTargets"] as List<dynamic>? ?? const [];
      final shouldRename =
          fields.isNotEmpty ||
          (includeAllReachableMethods && notifyTargets.isNotEmpty);
      if (shouldRename) {
        final existing = renameMethods[name];
        if (existing == null) {
          renameMethods[name] = Map<String, dynamic>.from(node)
            ..["origins"] = <Map<String, dynamic>>[node];
        } else {
          final origins = existing["origins"] as List<dynamic>? ?? <dynamic>[];
          final originKeys = origins
              .whereType<Map>()
              .map(
                (origin) => BatteryExternalNormalizer.pathKey(
                  _methodFullPath(
                    (origin["scope"] ?? '').toString(),
                    (origin["name"] ?? '').toString(),
                  ),
                ),
              )
              .toSet();
          if (originKeys.add(BatteryExternalNormalizer.pathKey(key))) {
            origins.add(node);
            existing["origins"] = origins;
          }
          final exScope = (existing["scope"] ?? "").toString();
          if (exScope != scope) {
            duplicateRename.putIfAbsent(name, () => {exScope}).add(scope);
          }
        }
      }

      final children = node["methods"] as List<dynamic>? ?? const [];
      for (final c in children) {
        walk(c);
      }
    }

    for (final root in depTable) {
      walk(root);
    }

    if (duplicateRename.isNotEmpty) {
      for (final entry in duplicateRename.entries) {
        final scopes = entry.value.toList()..sort();
        Log(
          "=> 检测到同名方法 ${entry.key} 位于多个作用域: ${scopes.join(', ')}；将共享同一 Rename 补丁，并分别生成包装器。",
        );
      }
    }

    final flatTable = _flattenBatteryDependencyTable(depTable);
    return (flatTable, renameMethods, wideFields, usedMutexNames);
  }

  /// 递归展开电池依赖表，将所有方法按名称排序
  List<Map<String, dynamic>> _flattenBatteryDependencyTable(
    List<Map<String, dynamic>> roots,
  ) {
    final tableByName = <String, Map<String, dynamic>>{};
    final edges = <String, Set<String>>{};
    final scopesByName = <String, Set<String>>{};

    void mergeFieldList(
      Map<String, dynamic> entry,
      String key,
      List<dynamic> incoming,
      String nameKey,
    ) {
      final existing = entry[key] as List<dynamic>? ?? <dynamic>[];
      final byName = <String, Map<String, dynamic>>{};
      for (final raw in existing) {
        final m = raw;
        final n = (m[nameKey] ?? "").toString().toUpperCase();
        if (n.isEmpty) continue;
        byName.putIfAbsent(n, () => m);
      }
      for (final raw in incoming) {
        final m = raw;
        final n = (m[nameKey] ?? "").toString().toUpperCase();
        if (n.isEmpty) continue;
        byName.putIfAbsent(n, () => m);
      }
      final merged = byName.values.toList()
        ..sort(
          (a, b) => (a[nameKey] ?? "").toString().compareTo(
            (b[nameKey] ?? "").toString(),
          ),
        );
      entry[key] = merged;
    }

    void mergeStringList(
      Map<String, dynamic> entry,
      String key,
      List<dynamic> s,
    ) {
      final existing = entry[key] as List<dynamic>? ?? <dynamic>[];
      final set = <String>{};
      for (final v in existing) {
        final x = v.toString().toUpperCase();
        if (x.isNotEmpty) set.add(x);
      }
      for (final v in s) {
        final x = v.toString().toUpperCase();
        if (x.isNotEmpty) set.add(x);
      }
      final list = set.toList()..sort();
      entry[key] = list;
    }

    void visit(Map<String, dynamic> node) {
      final name = (node["name"] ?? "").toString().toUpperCase();
      if (name.isEmpty) return;

      final scope = (node["scope"] ?? "").toString();
      if (scope.isNotEmpty) {
        scopesByName.putIfAbsent(name, () => <String>{}).add(scope);
      }

      final entry = tableByName.putIfAbsent(name, () {
        return <String, dynamic>{
          "name": name,
          "text": node["text"] ?? "",
          "type": node["type"] ?? "MethodObj",
          "argCount": node["argCount"] ?? 0,
          "flags": node["flags"] ?? "NotSerialized",
          "line": node["line"] ?? 0,
          // Keep the first-seen scope as representative, but also record all scopes.
          "scope": scope,
          "path": node["path"] ?? scope,
          "batteryBif": node["batteryBif"] == true,
          "batteryBix": node["batteryBix"] == true,
          "batteryBst": node["batteryBst"] == true,
          "scopes": <String>[],
          "fields": <Map<String, dynamic>>[],
          "mutexs": <Map<String, dynamic>>[],
          "notifyTargets": <String>[],
          // Store dependencies as method references to avoid deep/cyclic nesting.
          "methods": <Map<String, dynamic>>[],
        };
      });

      entry["batteryBif"] =
          entry["batteryBif"] == true || node["batteryBif"] == true;
      entry["batteryBix"] =
          entry["batteryBix"] == true || node["batteryBix"] == true;
      entry["batteryBst"] =
          entry["batteryBst"] == true || node["batteryBst"] == true;

      // Merge metadata across duplicate NameSeg occurrences.
      mergeFieldList(
        entry,
        "fields",
        node["fields"] as List<dynamic>? ?? const [],
        "name",
      );
      mergeFieldList(
        entry,
        "mutexs",
        node["mutexs"] as List<dynamic>? ?? const [],
        "name",
      );
      mergeStringList(
        entry,
        "notifyTargets",
        node["notifyTargets"] as List<dynamic>? ?? const [],
      );

      final children = node["methods"] as List<dynamic>? ?? const [];
      for (final child in children) {
        final childName = (child["name"] ?? "").toString().toUpperCase();
        if (childName.isEmpty) continue;
        edges.putIfAbsent(name, () => <String>{}).add(childName);
        visit(child);
      }
    }

    for (final root in roots) {
      visit(root);
    }

    // Finalize scopes and dependency names.
    for (final entry in tableByName.values) {
      final name = (entry["name"] ?? "").toString().toUpperCase();
      final scopes = (scopesByName[name] ?? <String>{}).toList()..sort();
      entry["scopes"] = scopes;
      if ((entry["scope"] ?? "").toString().isEmpty && scopes.isNotEmpty) {
        entry["scope"] = scopes.first;
        entry["path"] = scopes.first;
      }
      final deps = (edges[name] ?? <String>{}).toList()..sort();
      entry["methods"] = deps.map((n) => {"name": n}).toList();
    }

    final list = tableByName.values.toList()
      ..sort(
        (a, b) => (a["name"] ?? "").toString().compareTo(
          (b["name"] ?? "").toString(),
        ),
      );
    return list;
  }

  /// 日志输出电池依赖表
  Future<void> _logBatteryDependencyTable(
    List<Map<String, dynamic>> table,
  ) async {
    if (table.isEmpty) {
      Log("=> 电池依赖表T为空");
      return;
    }

    final ordered = List<Map<String, dynamic>>.from(table)
      ..sort(
        (a, b) => (a["name"] ?? "").toString().compareTo(
          (b["name"] ?? "").toString(),
        ),
      );
    final wideCount = ordered.where((n) {
      final fields = n["fields"] as List<dynamic>? ?? const [];
      return fields.isNotEmpty;
    }).length;
    final notifyCount = ordered.where((n) {
      final notifyTargets = n["notifyTargets"] as List<dynamic>? ?? const [];
      return notifyTargets.isNotEmpty;
    }).length;

    Log(
      "=> 依赖表T统计: methods=${ordered.length}, wideMethods=$wideCount, notifyMethods=$notifyCount",
    );

    int printed = 0;
    const maxLines = 250;

    Log("=> 依赖表T列表:");
    for (final node in ordered) {
      if (printed >= maxLines) break;

      final name = (node["name"] ?? "").toString().toUpperCase();
      final scopes = (node["scopes"] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
      final fields = node["fields"] as List<dynamic>? ?? const [];
      final notifyTargets = node["notifyTargets"] as List<dynamic>? ?? const [];
      final mutexs = node["mutexs"] as List<dynamic>? ?? const [];
      final deps = node["methods"] as List<dynamic>? ?? const [];

      final tags = <String>[];
      if (fields.isNotEmpty) {
        final fieldNames =
            fields
                .map((e) => e["name"] ?? "")
                .where((e) => e.isNotEmpty)
                .toList()
              ..sort();
        tags.add("Wide=${fieldNames.join('+')}");
      }
      if (notifyTargets.isNotEmpty) {
        tags.add("Notify=${notifyTargets.map((e) => e.toString()).join('+')}");
      }
      if (mutexs.isNotEmpty) {
        final names =
            mutexs
                .map((e) => e["name"] ?? "")
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        if (names.isNotEmpty) tags.add("Mutex=${names.join('+')}");
      }
      if (deps.isNotEmpty) {
        final depNames =
            deps
                .map((e) {
                  if (e is Map) {
                    return (e["name"] ?? "").toString().toUpperCase();
                  }
                  return e.toString().toUpperCase();
                })
                .where((e) => e.isNotEmpty)
                .toList()
              ..sort();
        tags.add("Deps=${depNames.join('+')}");
      }
      final scopeText = scopes.isEmpty ? "" : " @${scopes.join('|')}";
      final suffix = tags.isEmpty ? "" : " (${tags.join(', ')})";
      Log("  $name$scopeText$suffix");
      printed++;
      if (printed % 20 == 0) await Log.yieldToUi();
    }

    if (printed >= maxLines) {
      Log.warning("=> 依赖表T输出过长,已截断 (maxLines=$maxLines)");
    }
    await Log.yieldToUi();
  }

  // 检查是否是关键字
  bool _isKeyword(String word) {
    final w = word.toUpperCase();

    const keywords = {
      "IF",
      "ELSE",
      "ELSEIF",
      "WHILE",
      "RETURN",
      "STORE",
      "AND",
      "PCI0",
      "LPCB",
      "CASE",
      "OR",
      "XOR",
      "NOT",
      "LAND",
      "LOR",
      "LNOT",
      "LEQUAL",
      "LGREATER",
      "LLESS",
      "LGREATEREQUAL",
      "LLESSEQUAL",
      "LNOTEQUAL",
      "ADD",
      "SUBTRACT",
      "MULTIPLY",
      "DIVIDE",
      "MOD",
      "SHIFTLEFT",
      "SHIFTRIGHT",
      "CONCAT",
      "MATCH",
      "INDEX",
      "DEREFOF",
      "SIZEOF",
      "TOSTRING",
      "TOINTEGER",
      "TOBUFFER",
      "TOUUID",
      "COPYOBJECT",
      "ACQUIRE",
      "RELEASE",
      "SLEEP",
      "STALL",
      "NOTIFY",
      "DEBUG",
      "ASSERT",
      "RESET",
      "NAME",
      "METHOD",
      "DEVICE",
      "SCOPE",
      "BUFFER",
      "PACKAGE",
      "POWERRESOURCE",
      "PROCESSOR",
      "THERMALZONE",
      "TRUE",
      "FALSE",
      "ZERO",
      "ONE",
      "ONES",
    };

    if (keywords.contains(w)) return true;

    // Arg0-Arg7
    if (RegExp(r'^ARG[0-7]$').hasMatch(w)) return true;

    // Local0-Local7
    if (RegExp(r'^LOCAL[0-7]$').hasMatch(w)) return true;

    return false;
  }

  /// 标准化符号路径
  String normalizePath({
    required String ecPath,
    required String ecName,
    required String symbolPath,
  }) {
    // 1. 绝对路径直接返回
    if (symbolPath.startsWith(r'\')) {
      return symbolPath;
    }

    // 2. 相对路径处理
    if (symbolPath.startsWith('^')) {
      // 去掉所有 ^ 和可能的 "."
      final cleaned = symbolPath.replaceFirst(RegExp(r'^\^+\.?'), '');

      // 如果是以 EC 开头，避免重复拼接
      if (cleaned.startsWith('$ecName.')) {
        return '$ecPath.${cleaned.substring(ecName.length + 1)}';
      }

      if (cleaned == ecName) {
        return ecPath;
      }

      // 其他情况：直接拼到 EC 下
      return '$ecPath.$cleaned';
    }

    // 3. 普通相对路径（无 ^）
    return symbolPath;
  }

  /// 为电池设备和 EC 设备添加 External 声明
  List<String> _buildBatteryExternals({
    required List<Map<String, dynamic>> batteryDevices,
    required List<Map<String, dynamic>> ecDevices,
    required List<Map<String, dynamic>> usedFields,
    required Map<String, Map<String, dynamic>> renameTargets,
    required List<Map<String, String>> usedSymbols,
  }) {
    final externals = <String>{};
    final List<Map<String, String>> unresovedSymbols = List.from(usedSymbols);

    for (final batteryDevice in batteryDevices) {
      // 为电池设备本身添加 External 声明
      externals.add("External (${batteryDevice["path"]}, DeviceObj)");
      if (batteryDevices.length > 1) {
        externals.add("External (${batteryDevice["path"]}._HID, IntObj)");
      }
      // 为重命名目标添加 External 声明
      for (final target in renameTargets.keys) {
        for (final origin in _relatedMethodOrigins(renameTargets[target]!)) {
          externals.add("External (${origin["scope"]}.$target, MethodObj)");
        }
        unresovedSymbols.removeWhere((e) => e["name"] == target);
      }

      // 为电池设备的方法添加 External 声明
      for (final method in batteryDevice["methods"]) {
        final methodName = (method["name"] ?? "").toString().toUpperCase();
        if (!const {"_STA", "_BST", "_BIF", "_BIX"}.contains(methodName)) {
          continue;
        }
        externals.add(
          "External (${batteryDevice["path"]}.$methodName, MethodObj)",
        );
        unresovedSymbols.removeWhere((e) => e["name"] == methodName);
      }

      // 为电池设备的 Name 对象添加 External 声明
      for (final nameObj in batteryDevice["names"]) {
        if (unresovedSymbols.any((e) => e["name"] == nameObj['name'])) {
          externals.add(
            "External (${batteryDevice["path"]}.${nameObj['name']}, ${nameObj["type"]})",
          );
          unresovedSymbols.removeWhere((e) => e["name"] == nameObj['name']);
        }
      }
    }
    // 为 EC 设备的字段添加 External 声明
    for (final ecInfo in ecDevices) {
      final ecPath = ecInfo["path"];
      final ecName = ecInfo["name"] ?? "";
      // 为 EC 设备本身添加 External 声明
      externals.add("External ($ecPath, DeviceObj)");

      // 为 EC 设备的 Name 对象添加 External 声明
      for (final nameObj in ecInfo["names"]) {
        if (unresovedSymbols.any((e) => e["name"] == nameObj['name'])) {
          final namePath = nameObj["scope"] ?? "";
          if (namePath.isEmpty) continue;
          if (namePath.split(".").last == ecName) {
            externals.add(
              "External ($ecPath.${nameObj['name']}, ${nameObj["type"]})",
            );
          } else {
            externals.add("External (${nameObj['name']}, ${nameObj["type"]})");
          }
          unresovedSymbols.removeWhere((e) => e["name"] == nameObj['name']);
        }
      }

      for (final symbol in usedSymbols) {
        final symbolType = symbol["type"] ?? "";
        final symbolName = symbol["name"] ?? "";
        if (symbolType != "method") continue;
        final symbolPath = symbol["path"] ?? "";
        if (symbolPath.isEmpty) continue;
        final methodPaths = d.getMethodPaths(obj: symbolName);
        final fullPath = methodPaths.length == 1
            ? methodPaths.first.first.toString()
            : normalizePath(
                ecPath: ecPath,
                ecName: ecName,
                symbolPath: symbolPath,
              );
        externals.add("External ($fullPath, MethodObj)");
        unresovedSymbols.removeWhere((e) => e["name"] == symbolName);
      }
      // 为 EC 设备的 Method 添加 External 声明
      for (final method in ecInfo["methods"]) {
        final methodName = method["name"] as String;
        if (unresovedSymbols.any((e) => e["name"] == methodName)) {
          if (usedSymbols.any((e) => e['name'] == methodName)) {
            final methodPath =
                usedSymbols.firstWhere((e) => e['name'] == methodName)['path']
                    as String;
            if (methodPath.contains(ecName)) {
              externals.add("External ($ecPath.$methodName, MethodObj)");
            } else {
              externals.add("External ($methodName, MethodObj)");
            }
          }
          unresovedSymbols.removeWhere((e) => e["name"] == methodName);
        }
      }

      // 为 EC 设备的 FieldUnit 添加 External 声明
      for (final ecFields in ecInfo["scopeFields"]) {
        final fields = ecFields["fields"];
        for (final field in fields) {
          final bitLen = field["bitLength"] as int? ?? 0;
          final fieldPath = field["scope"] ?? "";
          if (fieldPath.isEmpty) continue;
          final fieldUnitObj = unresovedSymbols.firstWhere(
            (e) => e["name"] == field["name"],
            orElse: () => {},
          );
          if (fieldUnitObj.isNotEmpty && bitLen <= 8) {
            final fullPath = normalizePath(
              ecPath: ecPath,
              ecName: ecName,
              symbolPath: fieldUnitObj["path"] as String,
            );
            externals.add("External ($fullPath, FieldUnitObj)");
            unresovedSymbols.removeWhere((e) => e["name"] == field["name"]);
          }
        }
      }
      // 为 EC 设备的 Mutex 添加 External 声明
      for (final mutex in ecInfo["mutexs"]) {
        if (unresovedSymbols.any((e) => e["name"] == mutex["name"])) {
          externals.add("External ($ecPath.${mutex["name"]}, MutexObj)");
          unresovedSymbols.removeWhere((e) => e["name"] == mutex["name"]);
        }
      }
    }

    for (final field in usedFields) {
      unresovedSymbols.removeWhere((e) => e["name"] == field["name"]);
    }

    for (final symbol in List.from(unresovedSymbols)) {
      final methodPaths = d.getMethodPaths(obj: symbol["name"]);
      if (methodPaths.isNotEmpty) {
        final resolvedPath = methodPaths.length == 1
            ? methodPaths.first.first.toString()
            : symbol["path"]!;
        externals.add("External ($resolvedPath, MethodObj)");
        unresovedSymbols.removeWhere((e) => e["name"] == symbol["name"]);
      }
    }

    // 先以固件真实命名空间解析唯一 NameSeg，再生成绝对路径。
    // 例如 EC.CLPM、EC.HKEY.MHKQ、BAT1.XQ4C 不能退化为根作用域对象。
    final objectsByLeaf = <String, List<({String path, String type})>>{};
    void addObject(String rawPath, String rawType) {
      final path = BatteryExternalNormalizer.normalizePath(rawPath);
      final key = BatteryExternalNormalizer.pathKey(path);
      if (key.isEmpty) return;
      final leaf = key.split('.').last;
      final object = (
        path: path,
        type: BatteryExternalNormalizer.canonicalObjectType(rawType),
      );
      final objects = objectsByLeaf.putIfAbsent(leaf, () => []);
      if (!objects.any(
        (item) => BatteryExternalNormalizer.pathKey(item.path) == key,
      )) {
        objects.add(object);
      }
    }

    void addDeviceObjects(Map<String, dynamic> device) {
      final devicePath = (device["path"] ?? device["scope"] ?? "").toString();
      if (devicePath.isEmpty) return;
      addObject(devicePath, "DeviceObj");
      for (final raw in device["methods"] as List<dynamic>? ?? const []) {
        final method = raw as Map;
        final name = (method["name"] ?? "").toString();
        final scope = (method["scope"] ?? devicePath).toString();
        if (name.isNotEmpty) addObject("$scope.$name", "MethodObj");
      }
      for (final raw in device["names"] as List<dynamic>? ?? const []) {
        final name = raw as Map;
        final segment = (name["name"] ?? "").toString();
        final scope = (name["scope"] ?? devicePath).toString();
        if (segment.isNotEmpty) {
          addObject(
            "$scope.$segment",
            (name["type"] ?? "UnknownObj").toString(),
          );
        }
      }
      for (final raw in device["mutexs"] as List<dynamic>? ?? const []) {
        final mutex = raw as Map;
        final name = (mutex["name"] ?? "").toString();
        final scope = (mutex["scope"] ?? devicePath).toString();
        if (name.isNotEmpty) addObject("$scope.$name", "MutexObj");
      }
      for (final rawBlock
          in device["scopeFields"] as List<dynamic>? ?? const []) {
        final block = rawBlock as Map;
        for (final rawField in block["fields"] as List<dynamic>? ?? const []) {
          final field = rawField as Map;
          final name = (field["name"] ?? "").toString();
          final scope = (field["scope"] ?? devicePath).toString();
          if (name.isNotEmpty) addObject("$scope.$name", "FieldUnitObj");
        }
      }
    }

    for (final device in [...batteryDevices, ...ecDevices]) {
      addDeviceObjects(device);
    }
    final namespaceByPath = <String, BatteryNamespaceObject>{
      for (final object in _batteryNamespaceObjects)
        BatteryExternalNormalizer.pathKey(object.path): object,
    };
    final methodPaths = namespaceByPath.entries
        .where((entry) => entry.value.type == "MethodObj")
        .map((entry) => entry.key)
        .toSet();
    final localLeaves = <String>{};
    final realRootLeaves = <String>{};
    for (final object in _batteryNamespaceObjects) {
      final key = BatteryExternalNormalizer.pathKey(object.path);
      final separator = key.lastIndexOf('.');
      if (separator < 0) {
        if (object.confidence > 1) realRootLeaves.add(key);
        continue;
      }
      final parent = key.substring(0, separator);
      if (methodPaths.contains(parent)) {
        localLeaves.add(key.substring(separator + 1));
        continue;
      }
      addObject(object.path, object.type);
    }

    final externalPath = RegExp(
      r'^\s*External\s*\(\s*([^,\)]+)',
      caseSensitive: false,
    );
    final resolvedBodyKeys = <String>{};
    for (final line in _batteryBodyExternals) {
      final match = externalPath.firstMatch(line);
      if (match != null) {
        resolvedBodyKeys.add(
          BatteryExternalNormalizer.pathKey(match.group(1)!),
        );
      }
    }
    externals.removeWhere((line) {
      final match = externalPath.firstMatch(line);
      if (match == null) return false;
      final key = BatteryExternalNormalizer.pathKey(match.group(1)!);
      if (key.contains('.') || resolvedBodyKeys.contains(key)) return false;
      return resolvedBodyKeys.any((bodyKey) => bodyKey.endsWith('.$key'));
    });
    _batteryBodyExternals.forEach(externals.add);
    externals.removeWhere((line) {
      final match = externalPath.firstMatch(line);
      if (match == null) return false;
      final key = BatteryExternalNormalizer.pathKey(match.group(1)!);
      return !key.contains('.') &&
          localLeaves.contains(key) &&
          !realRootLeaves.contains(key);
    });

    final concreteObjectsByLeaf = <String, List<BatteryNamespaceObject>>{};
    for (final object in _batteryNamespaceObjects) {
      if (object.confidence <= 1) continue;
      final key = BatteryExternalNormalizer.pathKey(object.path);
      final separator = key.lastIndexOf('.');
      if (separator >= 0 && methodPaths.contains(key.substring(0, separator))) {
        continue;
      }
      final leaf = key.split('.').last;
      final objects = concreteObjectsByLeaf.putIfAbsent(leaf, () => []);
      if (!objects.any(
        (item) => BatteryExternalNormalizer.pathKey(item.path) == key,
      )) {
        objects.add(object);
      }
    }

    final aliases = <String, String>{};
    final preferredTypes = <String, String>{};
    for (final entry in objectsByLeaf.entries) {
      final concrete = concreteObjectsByLeaf[entry.key] ?? const [];
      String? resolvedPath;
      String? resolvedType;
      if (entry.value.length == 1) {
        resolvedPath = entry.value.single.path;
        resolvedType = entry.value.single.type;
      } else if (concrete.length == 1) {
        resolvedPath = concrete.single.path;
        resolvedType = concrete.single.type;
      }
      if (resolvedPath == null || resolvedType == null) continue;
      aliases[entry.key] = resolvedPath;
      preferredTypes[resolvedPath] = resolvedType;
    }

    final normalized = BatteryExternalNormalizer.canonicalize(
      externals,
      preferredTypes: preferredTypes,
      pathAliases: aliases,
    );
    final list = normalized.toList()..sort();
    return list;
  }

  /// 任意长度字节写入寄存器区域
  String _writeBatteryBufferMethod({
    bool writeWideField = false,
    required String regionSpace,
  }) {
    if (!writeWideField) {
      return "";
    }
    final memory = regionSpace.toLowerCase() == "systemmemory";
    final byteMethod = memory ? "WM1B" : "WE1B";
    final bufferMethod = memory ? "WMCB" : "WECB";
    final space = memory ? "SystemMemory" : "EmbeddedControl";
    return """
      Method ($byteMethod, 2, NotSerialized)
      {
          OperationRegion (WREG, $space, Arg0, One)
          Field (WREG, ByteAcc, NoLock, Preserve)
          {
              BYTE,   8
          }

          BYTE = Arg1
      }

      Method ($bufferMethod, 3, Serialized)
      {
          Arg1 = ((Arg1 + 0x07) >> 0x03)
          Name (BBUF, Buffer (Arg1){})
          BBUF = Arg2
          Arg1 += Arg0
          Local0 = Zero
          While ((Arg0 < Arg1))
          {
              $byteMethod (Arg0, DerefOf (BBUF [Local0]))
              Arg0++
              Local0++
          }
      }
    """;
  }

  // 读取寄存器区域任意长度字节到 Buffer
  String _readBatteryBufferMethod({
    bool hasWideField = false,
    required String regionSpace,
  }) {
    if (!hasWideField) {
      return "";
    }
    final memory = regionSpace.toLowerCase() == "systemmemory";
    final byteMethod = memory ? "RM1B" : "RE1B";
    final bufferMethod = memory ? "RMCB" : "RECB";
    final space = memory ? "SystemMemory" : "EmbeddedControl";
    return """
        Method ($byteMethod, 1, NotSerialized)
        {
            OperationRegion (RREG, $space, Arg0, One)
            Field (RREG, ByteAcc, NoLock, Preserve)
            {
                BYTE, 8
            }
            Return (BYTE)
        }

        Method ($bufferMethod, 2, Serialized)
        {
            Local0 = Arg0
            Local1 = (Arg1 >> 3)

            Name (BBUF, Buffer (Local1){})

            Local2 = Zero
            While (Local2 < Local1)
            {
                BBUF[Local2] = $byteMethod(Local0)
                Local0++
                Local2++
            }

            Return (BBUF)
        }
""";
  }

  // 拼接任意长度 Buffer 为整数
  String _bufferToIntegerMethod({bool hasWideField = false}) {
    if (!hasWideField) {
      return "";
    }
    return """
        Method (B2IN, 2, NotSerialized)
        {
            Local0 = Zero
            Local1 = Zero
            While (Local1 < Arg1)
            {
                Local0 |= (DerefOf (Arg0 [Local1]) << (Local1 * 0x08))
                Local1++
            }

            Return (Local0)
        }
""";
  }

  /// SMBUS

  Future<void> ssdtSBUSMCHC({bool prebuilt = false}) async =>
      prebuilt ? await _ssdtSBUSMCHCPrebuilt() : await _ssdtSBUSMCHC();

  Future<void> _ssdtSBUSMCHCPrebuilt() async {
    if (!checkIasl()) return;
    final String ssdtName = "SSDT-SBUS-MCHC";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = Prebuilt.ssdtSBUSMCHC;
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Defines an MCHC and BUS0 device for SMBus compatibility",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi, replace: true);
  }

  /// smbusPath 设备PCI地址
  Future<void> _ssdtSBUSMCHC() async {
    if (!await ensureDSDT()) return;
    Log("正在收集可能的总线设备…");
    String? busPath, busParent, tableName;
    final dev1F4 = getDevAtAdr(targetAdr: 0x001F0004);
    final dev1F3 = getDevAtAdr(
      targetAdr: 0x001F0003,
      excludeNames: ["AZAL", "HDEF", "HDAS"],
    );
    final dev1B = getDevAtAdr(targetAdr: 0x001B0000);
    final dev14 = getDevAtAdr(targetAdr: 0x00140000);

    ({String busPath, String busParent, String tableName})? busCheck;
    int? adr;

    if (dev1F4 != null && dev1F3 != null) {
      /// 新的Intel方案
      busCheck = dev1F4;
      adr = 0x001F0004;
    } else if (dev1F3 != null && dev1B != null) {
      /// 旧的Intel方案
      busCheck = dev1F3;
      adr = 0x001F0003;
    } else if (dev1F4 != null) {
      /// 可能是新的Intel方案
      busCheck = dev1F4;
      adr = 0x001F0004;
    } else if (dev1F3 != null) {
      /// 可能是旧的Intel方案
      busCheck = dev1F3;
      adr = 0x001F0003;
    } else if (dev14 != null) {
      /// 可能是AMD方案，非 Intel方案
      busCheck = dev14;
      adr = 0x00140000;
    }

    if (busCheck == null) {
      Log.warning("=> 未能找到有效的总线设备,已终止操作!");
      return;
    }
    // 解构变量
    busPath = busCheck.busPath;
    busParent = busCheck.busParent;
    tableName = busCheck.tableName;
    Log(
      "=> 在 $tableName 中根据地址: 0x${adr?.toRadixString(16).toUpperCase().padLeft(8, '0')} 找到 $busPath ",
    );
    final String ssdtName = "SSDT-SBUS-MCHC";
    Log("正在创建预编译 $ssdtName.dsl...");
    String ssdt = """/*
 * SMBus compatibility table.
 * Original from: https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/AcpiSamples/Source/SSDT-SBUS-MCHC.dsl
 */
DefinitionBlock ("", "SSDT", 2, "RAPID", "SBUSMCHC", 0x00000000)
{
    External ([[bus_parent]], DeviceObj)
    External ([[bus_parent]].MCHC, DeviceObj)
    External ([[bus_path]], DeviceObj)

    // Only create MCHC if it doesn't already exist
    If (LNot (CondRefOf ([[bus_parent]].MCHC)))
    {
        Scope ([[bus_parent]])
        {
            Device (MCHC)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    If (_OSI ("Darwin"))
                    {
                        Return (0x0F)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }
            }
        }
    }

    Device ([[bus_path]].BUS0)
    {
        Name (_CID, "smbus")  // _CID: Compatible ID
        Name (_ADR, Zero)  // _ADR: Address

        /*
        * Uncomment replacing 0x57 with your own value which might be found
        * in SMBus section of Intel datasheet for your motherboard.
        *
        * The "diagsvault" is the diagnostic vault where messages are stored.
        * It's located at address 87 (0x57) on the SMBus controller.
        * While "diagsvault" may refer to diags, a hardware diagnosis program via EFI for Macs
        * that communicates with the SMBus controller, the effect is really unknown for hacks.
        * Uncomment this with caution.
        */

        /**
        Device (DVL0)
        {
            Name (_ADR, 0x57)  // _ADR: Address
            Name (_CID, "diagsvault")  // _CID: Compatible ID
            Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
                If (!Arg2)
                {
                    Return (Buffer (One)
                    {
                        0x57                                             // W
                    })
                }

                Return (Package (0x02)
                {
                    "address",
                    0x57
                })
            }
        }
        **/

        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If (_OSI ("Darwin"))
            {
                Return (0x0F)
            }
            Else
            {
                Return (Zero)
            }
        }
    }
}""";

    ssdt = ssdt.replaceAll(r"[[bus_parent]]", busParent);
    ssdt = ssdt.replaceAll(r"[[bus_path]]", busPath);
    final acpi = {
      "Comment": "Defines an MCHC and BUS0 device for SMBus compatibility",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi);
    await writeSSDT(ssdtName, ssdt);
  }

  Future<void> ssdtGPUSPOOF({
    String? gpuPath,
    String? deviceId,
    String? fakeModel,
  }) async => await _ssdtGPUSPOOF(
    gpuPath: gpuPath,
    deviceId: deviceId,
    fakeModel: fakeModel,
  );

  /// 显卡仿冒
  /// [gpuPath] 显卡ACPI路径
  /// [deviceId] 显卡仿冒ID
  /// [fakeModel] 显卡仿冒名称
  Future<void> _ssdtGPUSPOOF({
    String? gpuPath,
    String? deviceId,
    String? fakeModel,
  }) async {
    if (!checkIasl()) return;
    if (gpuPath == null || !util.checkACPIPath(acpiPath: gpuPath)) {
      Log.warning("未提供有效的显卡ACPI路径! 已终止操作!");
      return;
    }
    if (deviceId == null || deviceId.isEmpty || deviceId.length != 4) {
      Log.warning("未提供有效的仿冒显卡ID! 已终止操作!");
      return;
    }
    if (fakeModel == null || fakeModel.isEmpty) {
      Log.warning("未提供有效的仿冒显卡名称！不会注入仿冒名称!");
    }
    bool adrOverflow = false;
    bool needBridge = false;
    bool sureDsdtOrACPI = d.acpiTables.isNotEmpty;
    if (sureDsdtOrACPI) {
      Log("正在检查显卡设备 $gpuPath...");
      // 检查显卡设备是否存在
      final (pciPath, overflow) = acpiDevicePath(sanitizeAcpiPath(gpuPath));
      if (pciPath != null && pciPath.isNotEmpty) {
        adrOverflow = overflow;
        // 检查 pciPath 是否存在 Method: _PRT
        bool foundMethod = _hasMethodInTables(gpuPath, ['_PRT']);
        if (!foundMethod) {
          Log('=> 在 DSDT 或 SSDT 中未找到 $gpuPath 对应的 _PRT 方法!');
          needBridge = false;
        } else {
          Log.warning("当前显卡路径 $gpuPath 可能隐藏真实设备!");
          Log.warning("=> 设备 $gpuPath 存在 _PRT 方法,可能已隐藏真实设备,将注入一个 GFX0 设备!");
          needBridge = true;
        }
      } else {
        Log.warning("=> 在 DSDT 或 SSDT 中未找到设备 $gpuPath! 已终止操作!");
        return;
      }
    } else {
      final commonGPUNames = [
        "PEGP",
        "GFX0",
        "GFX1",
        "GFX2",
        "VGA",
        "VID",
        "H000",
      ];
      final gpuName = gpuPath.split(".").last;
      needBridge = !commonGPUNames.contains(gpuName);
    }

    if (adrOverflow) {
      needBridge = true;
      Log.warning("=> 显卡设备 $gpuPath 的 _ADR 地址存在溢出情况!");
      gpuPath = gpuPath.substring(0, gpuPath.lastIndexOf("."));
      Log.warning("=> 回溯至父设备路径: $gpuPath 并注入一个 GFX0 设备!");
    }

    String ssdtName = "SSDT-$deviceId-GPU-SPOOF";
    Log("正在创建 $ssdtName.dsl...");
    Log("=> 显卡设备路径:  $gpuPath");
    Log("=> 仿冒显卡ID:  $deviceId");
    Log("=> 仿冒显卡名称:  $fakeModel");

    final dsmMethod = """
    Method (_DSM, 4, NotSerialized)
    {
        If ((!Arg2 || !_OSI ("Darwin")))
        {
            Return (Buffer (One)
            {
              0x03                                         
            })
        }
        Return (Package (0x02)
        {
                "device-id", 
                Buffer (0x02)
                {
                  [[DEVICE_ID]]
                }, 
                [[MODEL_PACKAGE]]
        })
    }
  """;

    final dsmBlock = needBridge
        ? """
        Device (GFX0)
        {
            Name (_ADR, Zero)
            $dsmMethod
        }
      """
        : dsmMethod;

    String ssdt =
        """
    DefinitionBlock ("", "SSDT", 2, "RAPID", "GPUSPOOF", 0x00001000)
    {

        External ([[GPU_PATH]], DeviceObj)

        Scope ([[GPU_PATH]])
        {
            $dsmBlock
        }
    }
 """;

    ssdt = ssdt.replaceAll(r"[[GPU_PATH]]", gpuPath);
    ssdt = ssdt.replaceAll(
      r"[[DEVICE_ID]]",
      util.convertDeviceIdToSpoof(deviceId),
    );

    String modelPackage = "";
    if (fakeModel != null && fakeModel.isNotEmpty) {
      modelPackage = """
        "model", 
            Buffer ()
            {
                "[[MODEL]]"
            }
      """;
      modelPackage = modelPackage.replaceAll(r"[[MODEL]]", fakeModel);
    }
    ssdt = ssdt.replaceAll(r"[[MODEL_PACKAGE]]", modelPackage);

    final acpi = {
      "Comment": "GPU Spoof",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    makePlist(acpi: acpi);
    await writeSSDT(ssdtName, ssdt);
  }

  /// 清理ACPI路径
  /// [path] ACPI路径
  List<String>? sanitizeAcpiPath(String path) {
    path = path
        .replaceAll("ACPI(", "")
        .replaceAll(")", "")
        .replaceAll("#", ".")
        .replaceAll("\\", "");

    List<String> newPath = [];
    const String valid = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
    for (var element in path.split(".")) {
      element = element.replaceAll(RegExp(r"_+$"), "").toUpperCase();
      if (element.length > 4 ||
          !element.split("").every((ch) => valid.contains(ch))) {
        return null;
      }

      newPath.add(element);
    }

    return newPath;
  }

  /// 匹配ACPI路径到PCIPath
  /// [path] ACPI路径
  /// [return] 匹配到的PCIPath和是否存在地址溢出
  (String?, bool) acpiDevicePath(List<String>? path) {
    String? matchedPCIPath;
    bool adrOverflow = false;
    if (path == null || path.isEmpty) {
      return (matchedPCIPath, adrOverflow);
    }
    final (deviceDict, _) = getDevicePaths();
    String? p;
    for (var key in deviceDict.keys) {
      if (compareAcpiPaths(key, path)) {
        p = key;
        break;
      }
    }

    if (p == null) {
      Log("=> 未找到!");
      return (matchedPCIPath, adrOverflow);
    }
    matchedPCIPath = deviceDict[p]!['path'];
    Log("=> 已匹配到PCI路径: $matchedPCIPath");
    if (deviceDict[p]?["adr_overflow"] == true) {
      final overFlow = getAllMatches(deviceDict, deviceDict[p]?["path"]);
      List<dynamic> devs = [];
      for (var d in overFlow) {
        final devInfo = d.$2;
        if (devInfo["dev_overflow"] != null) {
          devs.addAll(devInfo["dev_overflow"]);
        }
      }
      if (devs.isNotEmpty) {
        Log.warning("设备路径中存在地址 _ADR 溢出的情况!");
        Log.warning("以下设备可能会影响属性注入:");
        final uniqueSorted = devs.toSet().toList()..sort();
        for (var d in uniqueSorted) {
          Log.warning("=> $d");
          if (compareAcpiPaths(d, path)) {
            adrOverflow = true;
          }
        }
      }
    }
    return (matchedPCIPath, adrOverflow);
  }

  bool compareAcpiPaths(String path, List<String> pathList) {
    final pathCheck = sanitizeAcpiPath(path);
    if (pathCheck == null) {
      return false;
    }
    if (pathList.length != pathCheck.length) {
      return false;
    }
    for (var i = 0; i < pathList.length; i++) {
      if (pathList[i] != pathCheck[i]) {
        return false;
      }
    }
    return true;
  }

  Future<void> makePlist({
    Map<String, dynamic>? acpi,
    List<Map<String, dynamic>>? patches,
    List<Map<String, dynamic>>? drops,
    bool replace = false,
    List<PlistType> targets = const [PlistType.openCore],
  }) async {
    for (var target in targets) {
      _makeSinglePlist(
        target,
        acpi: acpi,
        patches: patches,
        drops: drops,
        replace: replace,
      );
    }
    if (_lastACPIMatchMode != config.acpiMatchMode) {
      _lastACPIMatchMode = config.acpiMatchMode;
    }
  }

  void beginPlistBatch() {
    if (_plistBatchDepth == 0) {
      _batchedPlists.clear();
    }
    _plistBatchDepth++;
  }

  bool batchedPlistContainsSsdt(String pathName) {
    for (final plist in _batchedPlists.values) {
      final add = plist['ACPI']?['Add'];
      if (add is List &&
          add.any(
            (entry) => entry is Map && entry['Path']?.toString() == pathName,
          )) {
        return true;
      }

      final sortedOrder = plist['ACPI']?['SortedOrder'];
      if (sortedOrder is List &&
          sortedOrder.any((entry) => entry?.toString() == pathName)) {
        return true;
      }
    }
    return false;
  }

  void removeBatchedSsdtArtifacts(
    String pathName, {
    bool removeSleepHookPatches = false,
  }) {
    for (final plist in _batchedPlists.values) {
      final add = plist['ACPI']?['Add'];
      if (add is List) {
        add.removeWhere(
          (entry) => entry is Map && entry['Path']?.toString() == pathName,
        );
      }

      final sortedOrder = plist['ACPI']?['SortedOrder'];
      if (sortedOrder is List) {
        sortedOrder.removeWhere((entry) => entry?.toString() == pathName);
      }

      for (final patches in [
        plist['ACPI']?['Patch'],
        plist['ACPI']?['DSDT']?['Patches'],
      ]) {
        if (patches is! List) continue;
        patches.removeWhere((entry) {
          if (entry is! Map) return false;
          final comment = entry['Comment']?.toString() ?? '';
          return comment.contains('requires $pathName') ||
              (removeSleepHookPatches &&
                  (comment.contains('_PTS to ZPTS') ||
                      comment.contains('_WAK to ZWAK')));
        });
      }
    }
  }

  Future<void> endPlistBatch({bool save = true}) async {
    if (_plistBatchDepth == 0) return;

    _plistBatchDepth--;
    if (_plistBatchDepth > 0) return;

    try {
      if (save) {
        _saveBatchedPlists();
      }
    } finally {
      _batchedPlists.clear();
    }
  }

  void _saveBatchedPlists() {
    final parser = PlistParser();
    for (final entry in _batchedPlists.entries) {
      final plist = entry.value;
      if (plist.isEmpty) continue;

      final success = parser.savePlist(entry.key, plist);
      Log(success ? '已成功保存 plist: ${entry.key}' : '保存 plist 失败: ${entry.key}');
      Log('');
    }
  }

  void _makeSinglePlist(
    PlistType type, {
    Map<String, dynamic>? acpi,
    List<Map<String, dynamic>>? patches,
    List<Map<String, dynamic>>? drops,
    bool replace = false,
  }) {
    final plistPath = path.join(
      config.outputDirectory!,
      outputFolder,
      _plistName(type),
    );
    final parser = PlistParser();
    final isBatching = _plistBatchDepth > 0;
    final usesBatchedPlist =
        isBatching && _batchedPlists.containsKey(plistPath);
    final result = usesBatchedPlist
        ? PlistParseResult(
            status: PlistParseStatus.success,
            data: _batchedPlists[plistPath],
          )
        : parser.loadPlist(plistPath);

    if (result.status == PlistParseStatus.parseError) {
      Log(result.message);
      return;
    }
    if (!usesBatchedPlist) {
      Log(
        result.status == PlistParseStatus.success
            ? '读取 plist: $plistPath'
            : '创建 plist: $plistPath',
      );
    }

    var plist = result.data ?? {};
    if (isBatching) {
      _batchedPlists[plistPath] = plist;
    }
    if (type == PlistType.openCore) {
      _prepareOpenCore(
        plist,
        acpi,
        patches,
        drops,
        {
          "NormalizeHeaders":
              config.acpiMatchMode ==
              ACPIMatchMode.tableIDsAndLengthAndNormalizeHeaders,
        },
        replace,
        type,
      );
    } else {
      _prepareClover(
        plist,
        acpi,
        patches,
        drops,
        {
          "FixHeaders":
              config.acpiMatchMode ==
              ACPIMatchMode.tableIDsAndLengthAndNormalizeHeaders,
        },
        replace,
        type,
      );
    }

    if (!isBatching && plist.isNotEmpty) {
      final success = parser.savePlist(plistPath, plist);
      Log(success ? '已成功保存 plist: $plistPath' : '保存 plist 失败: $plistPath');
      Log('');
    }
  }

  void _prepareOpenCore(
    Map<String, dynamic> plist,
    Map<String, dynamic>? acpi,
    List<Map<String, dynamic>>? patches,
    List<Map<String, dynamic>>? drops,
    Map<String, dynamic>? quirks,
    bool replace,
    PlistType type,
  ) {
    final ensurePath = util.ensurePath;

    ensurePath(plist, ["ACPI", "Add"]);
    ensurePath(plist, ["ACPI", "Patch"]);
    ensurePath(plist, ["ACPI", "Delete"]);
    ensurePath(plist, ["ACPI", "Quirks"], Map);

    _processSectionWrapper<Map<String, dynamic>>(
      plist: plist,
      type: type,
      keyPath: ["Add"],
      items: acpi,
      buildEntry: (s) => s,
      equalsEntry: (e, s) => e["Path"] == s["Path"],
      replace: replace,
      logCallback: (i) => i["Path"] ?? '',
    );
    _processSectionWrapper(
      plist: plist,
      type: type,
      keyPath: ["Patch"],
      items: patches,
      buildEntry: getOpenCorePatch,
      equalsEntry: (e, p) =>
          util.deepEquals(e["Find"], p["Find"]) &&
          util.deepEquals(e["Replace"], p["Replace"]),
      replace: replace,
      logCallback: (i) => i["Comment"],
    );
    _processSectionWrapper(
      plist: plist,
      type: type,
      keyPath: ["Delete"],
      items: drops,
      buildEntry: getOpenCoreDrop,
      equalsEntry: (e, d) =>
          util.deepEquals(e["TableSignature"], d["TableSignature"]) &&
          util.deepEquals(e["OemTableId"], d['OemTableId']),
      replace: replace,
      logCallback: (i) => i["Comment"],
    );
    _processSectionWrapper(
      plist: plist,
      type: type,
      keyPath: ["Quirks"],
      items: quirks ?? {},
      buildEntry: getOpenCoreQuirks,
      equalsEntry: (e, q) => e == q,
      replace: replace,
      logCallback: (i) => i.toString(),
    );
    _sortOpenCoreAcpiAddByDependencies(plist);
  }

  void _prepareClover(
    Map<String, dynamic> plist,
    Map<String, dynamic>? acpi,
    List<Map<String, dynamic>>? patches,
    List<Map<String, dynamic>>? drops,
    Map<String, dynamic>? quirks,
    bool replace,
    PlistType type,
  ) {
    final ensurePath = util.ensurePath;

    ensurePath(plist, ["ACPI", "SortedOrder"]);
    ensurePath(plist, ["ACPI", "DSDT", "Patches"]);
    ensurePath(plist, ["ACPI", "DropTables"]);

    _processSectionWrapper<String>(
      plist: plist,
      type: type,
      keyPath: ["SortedOrder"],
      items: acpi?["Path"],
      buildEntry: (s) => s,
      equalsEntry: (e, s) => e == s,
      replace: replace,
      logCallback: (i) => i,
    );
    _processSectionWrapper(
      plist: plist,
      type: type,
      keyPath: ["DSDT", "Patches"],
      items: patches,
      buildEntry: getCloverPatch,
      equalsEntry: (e, p) =>
          util.deepEquals(e["Find"], p["Find"]) &&
          util.deepEquals(e["Replace"], p["Replace"]),
      replace: replace,
      logCallback: (i) => i["Comment"],
    );
    _processSectionWrapper(
      plist: plist,
      type: type,
      keyPath: ["DropTables"],
      items: drops,
      buildEntry: getCloverDrop,
      equalsEntry: (e, d) =>
          e["Signature"] == d["Signature"] && e["TableId"] == d["TableId"],
      replace: replace,
      logCallback: (i) => "${i['Signature']} - ${i['Table']['id']}",
    );
    _processSectionWrapper(
      plist: plist,
      type: type,
      keyPath: [""],
      items: quirks ?? {},
      buildEntry: getCloverQuirks,
      equalsEntry: (e, q) => e == q,
      replace: replace,
      logCallback: (i) => i.toString(),
    );
    _sortCloverAcpiSortedOrderByDependencies(plist);
  }

  List<T?> _normalizeItems<T>(dynamic input) {
    if (input == null) return [];

    if (input is List) {
      return input.cast<T?>();
    } else {
      return [input as T?];
    }
  }

  void _sortOpenCoreAcpiAddByDependencies(Map<String, dynamic> plist) {
    final add = plist['ACPI']?['Add'];
    if (add is! List || add.length < 2) return;

    final paths = add
        .whereType<Map>()
        .map((entry) => entry['Path']?.toString())
        .whereType<String>()
        .toList();
    final order = _dependencySortedPaths(paths);
    if (order.isEmpty) return;

    final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
    final indexed = add.asMap().entries.toList();
    indexed.sort((a, b) {
      final aPath = a.value is Map ? a.value['Path']?.toString() : null;
      final bPath = b.value is Map ? b.value['Path']?.toString() : null;
      final aRank = rank[aPath];
      final bRank = rank[bPath];
      if (aRank == null && bRank == null) return a.key.compareTo(b.key);
      if (aRank == null) return 1;
      if (bRank == null) return -1;
      final result = aRank.compareTo(bRank);
      return result != 0 ? result : a.key.compareTo(b.key);
    });

    for (var i = 0; i < indexed.length; i++) {
      add[i] = indexed[i].value;
    }
  }

  void _sortCloverAcpiSortedOrderByDependencies(Map<String, dynamic> plist) {
    final sortedOrder = plist['ACPI']?['SortedOrder'];
    if (sortedOrder is! List || sortedOrder.length < 2) return;

    final paths = sortedOrder
        .map((entry) => entry?.toString())
        .whereType<String>()
        .toList();
    final order = _dependencySortedPaths(paths);
    if (order.isEmpty) return;

    final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
    final indexed = sortedOrder.asMap().entries.toList();
    indexed.sort((a, b) {
      final aRank = rank[a.value?.toString()];
      final bRank = rank[b.value?.toString()];
      if (aRank == null && bRank == null) return a.key.compareTo(b.key);
      if (aRank == null) return 1;
      if (bRank == null) return -1;
      final result = aRank.compareTo(bRank);
      return result != 0 ? result : a.key.compareTo(b.key);
    });

    for (var i = 0; i < indexed.length; i++) {
      sortedOrder[i] = indexed[i].value;
    }
  }

  List<String> _dependencySortedPaths(List<String> paths) {
    final uniquePaths = <String>[];
    final seen = <String>{};
    for (final path in paths) {
      if (seen.add(path)) uniquePaths.add(path);
    }

    final available = uniquePaths.toSet();
    final sorted = <String>[];
    final visiting = <String>{};
    final visited = <String>{};

    void visit(String path) {
      if (visited.contains(path)) return;
      if (visiting.contains(path)) return;
      visiting.add(path);
      for (final dependency in ssdtDependencies[path] ?? const <String>[]) {
        if (available.contains(dependency)) visit(dependency);
      }
      visiting.remove(path);
      visited.add(path);
      sorted.add(path);
    }

    for (final path in uniquePaths) {
      visit(path);
    }
    return sorted;
  }

  void _processSectionWrapper<T>({
    required Map<String, dynamic> plist,
    required PlistType type,
    required List<String> keyPath,
    required dynamic items,
    required T Function(T item) buildEntry,
    required bool Function(T existing, T item) equalsEntry,
    required bool replace,
    required String Function(T item) logCallback,
  }) {
    final normalized = _normalizeItems<T>(items);

    _processSection<T>(
      plist: plist,
      keyPath: keyPath,
      rawItems: normalized,
      buildEntry: buildEntry,
      equalsEntry: equalsEntry,
      replace: replace,
      type: type,
      logCallback: logCallback,
    );
  }

  Object _getOrInitAtPath(Map<String, dynamic> root, List<dynamic> path) {
    Map<String, dynamic> current = root;
    for (int i = 0; i < path.length - 1; i++) {
      current =
          current.putIfAbsent(path[i], () => <String, dynamic>{})
              as Map<String, dynamic>;
    }

    // 如果已存在，直接返回
    var existing = current[path.last];
    if (existing is Map<String, dynamic>) {
      return existing;
    }
    if (existing is List<dynamic>) {
      return existing;
    }

    // 如果 key 名字以 "Map" 结尾就当 Map，否则当 List
    if (path.last.toLowerCase().contains("map")) {
      return current.putIfAbsent(path.last, () => <String, dynamic>{})
          as Map<String, dynamic>;
    } else {
      return current.putIfAbsent(path.last, () => <dynamic>[]) as List<dynamic>;
    }
  }

  bool _isValidItem(Object? item) {
    return switch (item) {
      String s => s.isNotEmpty,
      Map m => m.isNotEmpty,
      List l => l.isNotEmpty,
      null => false,
      _ => true,
    };
  }

  String _plistName(PlistType type) =>
      type == PlistType.clover ? "patches_Clover.plist" : "patches_OC.plist";

  /// 处理 plist 中的指定路径
  /// [plist] plist 数据
  /// [keyPath] plist 中的路径
  /// [rawItems] 要添加的补丁项
  /// [buildEntry] 把 T 转为要写入 plist 的条目
  /// [equalsEntry] 用来判重（判断已有条目是否等于新条目）
  /// [replace] 是否替换
  /// [type] plist 类型
  /// [logCallback] 日志回调
  Map<String, dynamic> _processSection<T>({
    required Map<String, dynamic> plist,
    required List<String> keyPath,
    required List<T?>? rawItems,
    required T Function(T item) buildEntry,
    required bool Function(T existing, T item) equalsEntry,
    required bool replace,
    PlistType type = PlistType.openCore,
    String Function(T item)? logCallback,
  }) {
    // 如果 keyPath 是 [""]，就表示在 plist 自身插入，而不是 ["ACPI", ...keyPath]
    final effectivePath = (keyPath.length == 1 && keyPath.first.isEmpty)
        ? ["ACPI"]
        : ["ACPI", ...keyPath];

    final section = effectivePath.isEmpty
        ? plist
        : _getOrInitAtPath(plist, effectivePath);

    final validItems = (rawItems ?? [])
        .whereType<T>()
        .where(_isValidItem)
        .toList();

    if (section is List<dynamic>) {
      for (final item in validItems) {
        final entry = buildEntry(item);
        final comment = logCallback?.call(item);

        String patchType = '';
        if (item is Map<String, dynamic> &&
            (item.containsKey('Find') || item.containsKey('Signature'))) {
          patchType = '补丁';
        }

        // 查找匹配项
        final index = section.indexWhere((e) => equalsEntry(e, entry));

        if (index != -1) {
          // 已存在
          if (replace) {
            // 在原位置替换更新
            section[index] = entry;
            Log('=> 更新$patchType "$comment" 到 ${_plistName(type)}');
          } else {
            Log('=> $patchType "$comment" 已存在于 ${_plistName(type)}，跳过...');
          }
        } else {
          // 不存在则追加
          Log('=> 添加$patchType "$comment" 到 ${_plistName(type)}');
          section.add(entry);
        }
      }
    } else if (section is Map<String, dynamic>) {
      for (final item in validItems) {
        final entry = buildEntry(item);
        if (entry is Map<String, dynamic>) {
          for (final kv in entry.entries) {
            final key = kv.key;
            final newValue = kv.value;
            final oldValue = section[key];
            if (oldValue != null) {
              // 已存在该 key → 更新值
              if (replace || oldValue != newValue) {
                section[key] = newValue;
                if (_lastACPIMatchMode != config.acpiMatchMode) {
                  Log('=> 更新键 "$key" 的值为 "$newValue" 于 ${_plistName(type)}');
                }
              } else {
                if (_lastACPIMatchMode != config.acpiMatchMode) {
                  Log('=> 键 "$key" 的值已是最新，跳过 ${_plistName(type)}');
                }
              }
            } else {
              // 不存在该 key → 添加
              section[key] = newValue;
              if (_lastACPIMatchMode != config.acpiMatchMode) {
                Log('=> 添加键 "$key" 值 "$newValue" 到 ${_plistName(type)}');
              }
            }
          }
        }
      }
    } else {
      throw StateError(
        '路径 ${["ACPI", ...keyPath].join(".")} 既不是 List 也不是 Map，而是 ${section.runtimeType}',
      );
    }

    return plist;
  }

  /// 获取数据的字节数组
  /// [data] 支持 String, List, Uint8List
  /// [padTo] 填充到指定长度（不足部分填 0）
  List<int> getData(dynamic data, {int padTo = 0}) {
    if (data == null) return [];

    late List<int> byteData;

    if (data is String) {
      byteData = data.codeUnits;
    } else if (data is Uint8List) {
      byteData = data.toList();
    } else if (data is List) {
      // 检查 List 元素是否都是int
      if (data.every((e) => e is int)) {
        byteData = List<int>.from(data);
      } else {
        byteData = []; // 否则返回空
      }
    } else {
      throw ArgumentError('Data must be String, List<int> or Uint8List');
    }

    // 空数据保持为空，避免把未配置的匹配条件写成全零字节。
    if (byteData.isEmpty) return byteData;

    // 填充到 padTo 长度
    if (padTo > byteData.length) {
      byteData = [...byteData, ...List.filled(padTo - byteData.length, 0)];
    }

    return byteData;
  }

  /// 获取表 ID
  /// [table] 表字典
  /// [idName] ID 名称
  /// [mode] 匹配模式
  List<int> _getTableId(
    Map<dynamic, dynamic>? table,
    String idName, {
    ACPIMatchMode? mode,
  }) {
    mode ??= config.acpiMatchMode; // 默认使用 acpiMatchMode

    if (table == null) return [];

    dynamic rawValue;

    switch (mode) {
      case ACPIMatchMode.tableIDsAndLength:
        rawValue = table[idName];
        break;
      case ACPIMatchMode.tableIDsAndLengthAndNormalizeHeaders:
        rawValue = table["${idName}_ascii"] ?? table[idName];
        break;
      default: // leastStrict / lengthOnly
        return [];
    }

    if (rawValue is String) {
      return rawValue.codeUnits;
    } else if (rawValue is List<int>) {
      return rawValue;
    } else {
      return [];
    }
  }

  /// 获取表长度
  /// [table] 表字典
  /// [mode] 匹配模式
  int _getTableLength(Map<dynamic, dynamic>? table, {ACPIMatchMode? mode}) {
    mode ??= config.acpiMatchMode;
    if (table == null || mode == ACPIMatchMode.leastStrict) {
      // 没有找到表，或者长度0
      return 0;
    }
    // 如果模式不是0，返回表长度
    return table["length"] ?? 0;
  }

  /// Clover patch 补丁
  /// [patch] patch 字典
  Map<String, dynamic> getCloverPatch(Map<String, dynamic> patch) {
    return {
      "Comment": patch["Comment"],
      "Disabled": patch.containsKey("Disabled") ? patch["Disabled"] : false,
      "Find": getData(util.getHexBytes(patch["Find"])),
      "Replace": getData(util.getHexBytes(patch["Replace"])),
    };
  }

  Map<String, dynamic> getCloverDrop(Map<String, dynamic> drop) {
    final table = drop['Table'] ?? d.getDsdt();
    int leng = _getTableLength(table);
    Map<String, dynamic> t = {
      "Signature": table["signature"],
      "TableId": table["id"],
    };
    int length = drop['Length'] ?? leng;
    if (length > 0) {
      t["Length"] = length;
    }
    return t;
  }

  /// Clover quirks
  /// [quirks] quirks 字典
  Map<String, dynamic> getCloverQuirks(Map<String, dynamic> quirks) {
    return {"FixHeaders": quirks["FixHeaders"] ?? false};
  }

  /// OpenCore patch 补丁
  /// [patch] patch 字典
  Map<String, dynamic> getOpenCorePatch(Map<String, dynamic> patch) {
    var table = patch["Table"] ?? d.getDsdt();
    if (table == null || table.isEmpty) {
      table = {};
    }
    return {
      "Base": patch["Base"] ?? "",
      "BaseSkip": patch["BaseSkip"] ?? 0,
      "Comment": patch["Comment"],
      "Count": patch["Count"] ?? 0,
      "Enabled": patch.containsKey("Enabled") ? patch["Enabled"] : true,
      "Find": getData(util.getHexBytes(patch["Find"])),
      "Limit": patch["Limit"] ?? 0,
      "Mask": getData(patch['Mask']),
      "OemTableId": getData(
        patch['TableId'] ?? _getTableId(table, 'id'),
        padTo: 8,
      ),
      "Replace": getData(util.getHexBytes(patch["Replace"])),
      "ReplaceMask": getData(patch['ReplaceMask']),
      "Skip": patch["Skip"] ?? 0,
      "TableLength": patch["Length"] ?? _getTableLength(table),
      "TableSignature": getData(
        patch['Signature'] ?? _getTableId(table, 'signature'),
        padTo: 4,
      ),
    };
  }

  /// OpenCore drop 补丁
  /// [drop] drop 字典
  Map<String, dynamic> getOpenCoreDrop(Map<String, dynamic> drop) {
    var table = drop["Table"] ?? d.getDsdt();
    if (table == null || table.isEmpty) {
      table = {};
    }
    return {
      "All": drop["All"] ?? false,
      "Comment": drop["Comment"] ?? "",
      "Enabled": drop["Enabled"] ?? true,
      "OemTableId": getData(
        drop["TableId"] ?? _getTableId(table, 'id'),
        padTo: 8,
      ),
      "TableLength": drop["Length"] ?? _getTableLength(table),
      "TableSignature": getData(
        drop["Signature"] ?? _getTableId(table, 'signature'),
        padTo: 4,
      ),
    };
  }

  /// OpenCore quirks
  /// [quirks] quirks 字典
  Map<String, dynamic> getOpenCoreQuirks(Map<String, dynamic> quirks) {
    return {"NormalizeHeaders": quirks["NormalizeHeaders"] ?? false};
  }
}
