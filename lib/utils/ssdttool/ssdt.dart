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

class SSDT {
  final Run run = Run();
  final DSDT d;
  final Util util = Util();
  final targetIrqs = [0, 2, 8, 11];
  final illegalNames = ["XHC1", "EHC1", "EHC2", "PXSX"];

  final String legacyWarning =
      '注意:旧版iasl-legacy仅支持macOS 10.6及更早版本，目前主流系统使用可能存在兼容性问题,谨慎使用!!!\n';

  AcpiConfig config;

  String outputFolder = 'Results';
  ACPIMatchMode? _lastACPIMatchMode = ACPIMatchMode.leastStrict;
  int _plistBatchDepth = 0;
  final Map<String, Map<String, dynamic>> _batchedPlists = {};

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
  }) async =>
      await d.dumpTables(
        filePath,
        disassemble: disassemble,
        onRequestSudoPassword: onRequestSudoPassword,
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
          Log("即将反编译 $dsdt，以验证是否需要应用预制补丁…");
          final (result, failed) = await d.loadTable(
            path.join(fileOrFolderPath, dsdt),
          );
          if (result.isNotEmpty) {
            exclude.add(dsdt);
            Log('=> 无需应用预制补丁!\n');
          } else {
            troubleDsdt = dsdt;
          }
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
      final (result, failed) = await d.loadTable(
        fileOrFolderPath,
        exclude: exclude,
      );

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

    final List<String> iaslArgs =
        config.force ? [iaslPath, '-f', tmpDsl] : [iaslPath, tmpDsl];

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

  /// 提取 Field 内部所有行（保留 Offset 和原始格式）
  List<String> getFieldVarWithPath(String devicePath) {
    final deviceInfo = getDeviceAllInfo(devicePath: devicePath);
    final fields = deviceInfo['fields'];
    final lines = <String>[];
    // 遍历 fields，找到包含 PMEE 的 Field
    for (var field in fields) {
      // 找到大括号 { 和 } 之间的内容
      final braceStart = field.indexOf('{');
      final braceEnd = field.lastIndexOf('}');

      if (braceStart == -1 || braceEnd == -1 || braceEnd <= braceStart) {
        // 如果没有找到大括号，直接返回空列表
        return lines;
      }

      // 提取内部文本
      final body = field.substring(braceStart + 1, braceEnd);

      // 按行拆分，保留每一行原始缩进和逗号
      for (var line in body.split(RegExp(r'[\r\n]+'))) {
        line = line.trim();
        if (line.isNotEmpty) {
          lines.add(line);
        }
      }
    }

    return lines;
  }

  /// 获取设备的所有信息
  /// [devicePath] 设备路径
  /// [table] ACPI 表 （可选）
  Map<String, dynamic> getDeviceAllInfo({
    required String devicePath,
    Map<String, dynamic>? table,
  }) {
    table ??= d.getDsdt();

    final List<String> names = [];
    final List<String> methods = [];
    final List<String> opRegions = [];
    final List<String> fields = [];
    final List<String> devices = [];

    // 获取设备完整 Scope（每行为一项）
    final scope = d.getScopeOfDevice(
      devicePath: devicePath,
      table: table,
      stripComments: true,
    );

    if (scope.isEmpty) {
      Log("=> 未找到设备 $devicePath 的 Scope");
      return {
        "valid": false,
        "device": devicePath,
        "names": names,
        "methods": methods,
        "operationRegions": opRegions,
        "fields": fields,
        "devices": devices,
      };
    }

    // 逐行解析 scope，使用 depth 跟踪大括号层级
    // 只收集 depth == 1 的一级成员；当遇到子 Device 时，把它加入 devices 并跳过其 block
    final lines = scope; // List<String>
    int depth = 0;

    // 首先确定 scope 起始处并初始化 depth：
    // 找到第一个含 "{" 的行并把 depth 置为 1，从下一行开始解析
    int startIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains("{")) {
        startIndex = i + 1;
        depth = 1;
        break;
      }
    }
    // 如果没有找到 '{'，仍从 0 开始（防御）
    if (depth == 0) {
      startIndex = 0;
      depth = 1;
    }

    // 从 given index 起找到与之匹配的 '}' 的行索引（根据 brace 计数）
    int findMatchingBrace(int fromIndex) {
      int b = 0;
      for (int j = fromIndex; j < lines.length; j++) {
        final l = lines[j];
        // 在同一行可能同时包含 { 和 }
        for (int k = 0; k < l.length; k++) {
          if (l[k] == '{') {
            b++;
          } else if (l[k] == '}') {
            if (b == 0) {
              // 如果先出现 } 而 b==0，说明在外层遇到结束，返回当前行
              return j;
            } else {
              b--;
              if (b == 0) return j;
            }
          }
        }
      }
      return lines.length - 1;
    }

    // 主循环：从 startIndex 解析到 scope 结束（depth 回到 0）
    int i = startIndex;
    while (i < lines.length) {
      String raw = lines[i];
      String line = raw.trim();

      // 更新 depth 基于当前行的 { 和 } 出现数量（在跳块时控制 i）
      // 若行里含 'Device (' 开头，且当前 depth==1，表示子设备（一级子设备）
      final deviceHeaderMatch = RegExp(
        r'^\s*Device\s*\(\s*([A-Za-z0-9_]+)\s*\)',
        caseSensitive: false,
      ).firstMatch(raw);

      if (deviceHeaderMatch != null && depth == 1) {
        // 记录子设备 header 原始行
        devices.add(raw.trim());

        // 跳过该子设备的整个块：找匹配的 '}' 行
        // 寻找从当前行开始第一个 '{'，再找到匹配的 '}'
        int firstBraceLine = -1;
        for (int t = i; t < lines.length; t++) {
          if (lines[t].contains("{")) {
            firstBraceLine = t;
            break;
          }
        }
        if (firstBraceLine == -1) {
          // 没找到 '{'，就仅跳过当前行
          i++;
          continue;
        }
        int matchLine = findMatchingBrace(firstBraceLine);
        // 继续解析从 matchLine + 1
        i = matchLine + 1;
        continue;
      }

      // 若当前 depth == 1，采集 Name / Method / OperationRegion / Field
      if (depth == 1) {
        // ---- Name (single-line) ----
        if (line.startsWith("Name (")) {
          names.add(raw.trim());
          i++;
          continue;
        }

        // ---- OperationRegion (通常单行) ----
        if (line.startsWith("OperationRegion")) {
          opRegions.add(raw.trim());
          i++;
          continue;
        }

        // ---- Method (可能多行，有大括号) ----
        if (line.startsWith("Method (") || line.startsWith("method (")) {
          // 捕获从当前行开始直到匹配的 '}' 为止的完整 block
          // 找到第一行包含 '{' 的行（可能是当前行或后续行）
          int braceStart = -1;
          for (int t = i; t < lines.length; t++) {
            if (lines[t].contains("{")) {
              braceStart = t;
              break;
            }
          }
          if (braceStart == -1) {
            // 没有找到 '{'，将当前行作为 method（防御）
            methods.add(raw.trim());
            i++;
            continue;
          }
          int matchLine = findMatchingBrace(braceStart);
          // 拼接从 i 到 matchLine 的所有行
          final buffer = StringBuffer();
          for (int t = i; t <= matchLine; t++) {
            buffer.writeln(lines[t]);
          }
          methods.add(buffer.toString().trim());
          i = matchLine + 1;
          continue;
        }

        // ---- Field (完整保留所有内容，包括定义行 + 大括号内部) ----
        if (line.startsWith("Field (") || line.startsWith("field (")) {
          // 找到第一行包含 '{' 的行（可能是当前行，也可能在后面）
          int braceStart = i;
          while (
              braceStart < lines.length && !lines[braceStart].contains("{")) {
            braceStart++;
          }

          // 如果没找到 '{'，至少保留当前行
          if (braceStart >= lines.length) {
            fields.add(raw.trim());
            i++;
            continue;
          }

          // 找到匹配闭合 '}'
          int braceCount = 0;
          int matchLine = braceStart;
          for (int t = braceStart; t < lines.length; t++) {
            final l = lines[t];
            for (int c = 0; c < l.length; c++) {
              if (l[c] == '{') braceCount++;
              if (l[c] == '}') {
                braceCount--;
                if (braceCount == 0) {
                  matchLine = t;
                  break;
                }
              }
            }
            if (braceCount == 0) break;
          }

          // 拼接从定义行 i 到 matchLine 的所有行
          final buffer = StringBuffer();
          for (int t = i; t <= matchLine; t++) {
            buffer.writeln(lines[t]);
          }
          fields.add(buffer.toString().trim());

          // 跳到闭合行的下一行
          i = matchLine + 1;
          continue;
        }
      }

      // 若未特殊匹配，按行更新 depth：count '{' 和 '}'
      // 子设备 Device 内的深度会影响外层采集（已通过跳块处理）,这里仅更新 depth 基于行出现的 { 和 }
      int opens = RegExp(r'\{').allMatches(raw).length;
      int closes = RegExp(r'\}').allMatches(raw).length;
      depth += opens - closes;

      // 当 depth <= 0 时结束（scope 结束）
      if (depth <= 0) break;

      i++;
    }

    return {
      "valid": true,
      "device": devicePath,
      "names": names,
      "methods": methods,
      "operationRegions": opRegions,
      "fields": fields,
      "devices": devices,
    };
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
            final devOverflow = (deviceDict[pathKey]!["dev_overflow"] ??
                <String>[]) as List<String>;
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
              final busParent =
                  pathParts.sublist(0, pathParts.length - 1).join('.');
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
          List<int> repl1 =
              repl.map((y) => y >= rem ? y & (rem ^ 0xFFFF) : y).toList();

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
      gotMem = memAccess != null &&
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
      ssdt = """
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
  }) async =>
      prebuilt
          ? await _ssdtPNLFPrebuilt()
          : await _ssdtPNLF(
              uid: uid,
              getIgpu: getIgpu,
              manualIGPUPath: manualIGPUPath,
            );

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
    // 检查是否提供了有效的 uid
    if (uid == null) {
      Log.warning("未提供有效的 UID，终止操作！");
      return;
    }

    final uidList = PNLFUIDs.map((item) => item['UID']).toList();
    if (!uidList.contains(uid)) {
      Log.warning("$uid 是一个自定义的 UID，可能需要手动定制设置，或者可能根本不受支持!");
    }

    String igpu = "";
    bool guessed = false;
    bool manual = false;
    bool getIGpuInfo = false;
    if (uid == 14) {
      Log("");
      Log.warning(
        "注意:英特尔第1代Arrandale,第2代Sandy Bridge,第3代Ivy Bridge 默认使用 UID:14,但是有些机器使用UID: 14 会遇到最大亮度受限或其他问题.为了解决这些问题,必须设置正确的 iGPU（集成显卡）的设备路径，并且可能需要补充IGPU寄存器信息",
      );
      Log("");
      getIGpuInfo = getIgpu ?? false;
    }
    final String ssdtName = "SSDT-PNLF";
    Log("正在创建预编译 $ssdtName.dsl...");
    // 打印所用的UID，使用的平台和对应的PWMMax
    for (var item in PNLFUIDs) {
      if (item['UID'] == uid) {
        Log("=> 使用的UID: ${item['UID']}");
        Log("=> 适用平台: ${item['Platform']}");
        break;
      }
    }
    // 检查是否构建 UID 为 14 的 SSDT
    if (getIGpuInfo) {
      if (uid == 14 && (manualIGPUPath == null || manualIGPUPath.isEmpty)) {
        Log("未提供有效 iGPU 路径，尝试自动查找...");
      }
      Log("正在寻找位于 0x00020000 的 iGPU 设备…");
      final tableNameList = d.acpiTables.keys.toList();
      final sortedTableNames = sortedNicely(tableNameList, first: "DSDT.aml");
      // 第一阶段：通过地址查找 iGPU 设备
      for (var tableName in sortedTableNames) {
        var table = d.acpiTables[tableName];
        Log("正在检查 $tableName…");
        // 尝试获取 iGPU 设备路径
        var paths = d.getPathOfType(objType: "Name", obj: "_ADR", table: table);

        for (var path in paths) {
          var adr = getAddressFromLine(path[1], table: table);
          if (adr == 0x00020000) {
            igpu = path[0].substring(0, path[0].length - 5);
            Log("=> 在 $igpu 处找到 iGPU 设备!");
            break;
          }
        }
        if (igpu.isNotEmpty) break;
      }
      // 如果第一阶段未找到 iGPU
      if (igpu.isEmpty) {
        Log("未通过地址找到 iGPU 设备!");
        Log("正在搜索常见的 iGPU 名称…");

        // 第二阶段：通过常见名称查找 iGPU
        for (var tableName in sortedTableNames) {
          var table = d.acpiTables[tableName];
          Log("正在检查 $tableName…");
          // 获取 PCI 根设备路径
          var pciRoots = [
            d.getDevicePathsWithHid(hid: "PNP0A08", table: table),
            d.getDevicePathsWithHid(hid: "PNP0A03", table: table),
            d.getDevicePathsWithHid(hid: "ACPI0016", table: table),
          ];

          List<dynamic> external = [];
          table["lines"]?.forEach((line) {
            final trimmedLine = line.toString().trim();
            if (!trimmedLine.startsWith("External (")) return;
            try {
              final pathPart = trimmedLine.split('(')[1].split(', ')[0];
              final processedPath = pathPart
                  .split('.')
                  .map(
                    (segment) => segment
                        .replaceAll('\\', '')
                        .replaceAll(RegExp(r'_+$'), ''),
                  )
                  .join('.');
              external.add('\\$processedPath');
            } catch (_) {
              // 忽略异常
              debugPrint("Error processing line: $trimmedLine");
            }
          });

          for (var root in pciRoots) {
            for (var name in [
              "IGPU",
              "_VID",
              "VID0",
              "VID1",
              "GFX0",
              "VGA",
              "_VGA",
            ]) {
              if (root.isEmpty) {
                break;
              }
              var testPath = "${root[0]}.$name";
              var devicePaths = d.getDevicePaths(obj: testPath, table: table);
              String? device;
              if (devicePaths.isNotEmpty) {
                /// 找到 iGPU 设备路径
                device = devicePaths[0][0];
              } else {
                /// 遍历外部路径，查找是否有声明
                device = external.firstWhere(
                  (x) => testPath == x,
                  orElse: () => null,
                );
              }

              /// 未找到 iGPU 设备路径,继续
              if (device == null) continue;

              /// 检查是否有 _ADR,如果有,则跳过,因为它在之前的循环中是错误的
              if (d
                  .getPathOfType(
                    objType: "Name",
                    obj: "$device._ADR",
                    table: table,
                  )
                  .isNotEmpty) {
                continue;
              }

              /// 找到 iGPU 设备路径
              igpu = device;
              guessed = true;
              Log("=> 在 $igpu 处发现了可能的 iGPU 设备");
            }
          }

          /// 找到 iGPU 设备路径,退出
          if (igpu.isNotEmpty) break;
        }
      }
    }

    if (getIGpuInfo && (igpu.isEmpty || guessed)) {
      if (igpu.isNotEmpty) {
        Log("在 $igpu 处发现了可能的 iGPU 设备\n");
      }

      /// 如果没有找到有效的 iGPU 路径
      if (igpu.isEmpty) {
        if (!guessed) {
          Log.warning("在传递的 ACPI 表中未找到有效的 iGPU 路径!\n");
        }
        if (manualIGPUPath == null || manualIGPUPath.isEmpty) {
          Log.warning(
            "请输入要使用的 iGPU ACPI 路径。每个路径元素的字符限制为 4 个字母数字字符（以字母或下划线开头），并用空格分隔。例如: SB.PCI0.GFX0\n",
          );
        } else {
          Log("已按照给定iGPU路径,手动设置为 $manualIGPUPath \n");
        }

        /// 传入的IGPU设备地址
        if (manualIGPUPath != null && manualIGPUPath.isNotEmpty) {
          List<String> parts =
              manualIGPUPath.replaceFirst("\\", "").toUpperCase().split(".");
          String valid = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
          String noStart = "0123456789";

          if (parts.any(
            (p) =>
                p.isEmpty ||
                p.length > 4 ||
                noStart.contains(p[0]) ||
                p.split("").any((x) => !valid.contains(x)),
          )) {
            Log("无效的 iGPU 路径：$manualIGPUPath");
          }
          parts = parts.map((p) => p.replaceAll(RegExp(r"_+$"), "")).toList();
          igpu = "\\${parts.join(".")}";
          guessed = false;
          manual = true;
        }
      }
    }

    List<Map<String, dynamic>> patches = [];

    final tableNameList = d.acpiTables.keys.toList();
    final sortedTableNames = sortedNicely(tableNameList);

    // 检查所有表，寻找包含 "PNLF" 的表，并生成一个重命名
    for (String tableName in sortedTableNames) {
      final table = d.acpiTables[tableName]!;
      if (table["table"] != null &&
          table["table"].isNotEmpty &&
          table["table"]!.contains("PNLF")) {
        Log("=> 在 $tableName 中检测到 PNLF, 正在生成重命名补丁…");
        patches.add({
          "Comment": "PNLF to XNLF rename - requires $ssdtName.aml",
          "Find": "504E4C46",
          "Replace": "584E4C46",
        });
        // 只生成一个重命名后退出循环
        break;
      }
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
          "Find": "084E4243460A00",
          "Replace": "084E4243460A01",
          "Enabled": true,
          "Disabled": false,
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
          "Find": "084E42434600",
          "Replace": "084E42434601",
          "Enabled": true,
          "Disabled": false,
        });
      }

      // 如果两种模式都已检测到，则提前退出
      if (hasNbcfOld && hasNbcfNew) {
        break;
      }
    }

    String ssdt = """//
// Much of the info pulled from: https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/AcpiSamples/Source/SSDT-PNLF.dsl
//
DefinitionBlock ("", "SSDT", 2, "RAPID", "PNLF", 0x00000000)
{""";
    if (igpu.isNotEmpty) {
      ssdt += """
    External ([[igpu_path]], DeviceObj)
""";
    }
    ssdt += """
    Device (PNLF)
    {
        Name (_HID, EisaId ("APP0002"))  // _HID: Hardware ID
        Name (_CID, "backlight")  // _CID: Compatible ID
        Name (_UID, [[uid_value]])  // _UID: Unique ID: [[uid_dec]]
        
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
        }""";
    if (igpu.isNotEmpty) {
      ssdt += """
        Method (_INI, 0, Serialized)
        {
            If (LAnd (_OSI ("Darwin"), CondRefOf ([[igpu_path]])))
            {
                OperationRegion ([[igpu_path]].RMP3, PCI_Config, Zero, 0x14)
                Field ([[igpu_path]].RMP3, AnyAcc, NoLock, Preserve)
                {
                    Offset (0x02), GDID,16,
                    Offset (0x10), BAR1,32,
                }
                // IGPU PWM backlight register descriptions:
                //   LEV2 not currently used
                //   LEVL level of backlight in Sandy/Ivy
                //   P0BL counter, when zero is vertical blank
                //   GRAN see description below in INI1 method
                //   LEVW should be initialized to 0xC0000000
                //   LEVX PWMMax except FBTYPE_HSWPLUS combo of max/level (Sandy/Ivy stored in MSW)
                //   LEVD level of backlight for Coffeelake
                //   PCHL not currently used
                OperationRegion (RMB1, SystemMemory, BAR1 & ~0xF, 0xe1184)
                Field(RMB1, AnyAcc, Lock, Preserve)
                {
                    Offset (0x48250),
                    LEV2, 32,
                    LEVL, 32,
                    Offset (0x70040),
                    P0BL, 32,
                    Offset (0xc2000),
                    GRAN, 32,
                    Offset (0xc8250),
                    LEVW, 32,
                    LEVX, 32,
                    LEVD, 32,
                    Offset (0xe1180),
                    PCHL, 32,
                }
                // Now fixup the backlight PWM depending on the framebuffer type
                // At this point:
                //   Local4 is RMCF.BLKT value (unused here), if specified (default is 1)
                //   Local0 is device-id for IGPU
                //   Local2 is LMAX, if specified (Ones means based on device-id)
                //   Local3 is framebuffer type

                // Adjustment required when using WhateverGreen.kext
                Local0 = GDID
                Local2 = Ones
                Local3 = 0

                // check Sandy/Ivy
                // #define FBTYPE_SANDYIVY 1
                If (LOr (LEqual (1, Local3), LNotEqual (Match (Package()
                {
                    // Sandy HD3000
                    0x010b, 0x0102,
                    0x0106, 0x1106, 0x1601, 0x0116, 0x0126,
                    0x0112, 0x0122,
                    // Ivy
                    0x0152, 0x0156, 0x0162, 0x0166,
                    0x016a,
                    // Arrandale
                    0x0046, 0x0042,
                }, MEQ, Local0, MTR, 0, 0), Ones)))
                {
                    if (LEqual (Local2, Ones))
                    {
                        // #define SANDYIVY_PWMMAX 0x710
                        Store (0x710, Local2)
                    }
                    // change/scale only if different than current...
                    Store (LEVX >> 16, Local1)
                    If (LNot (Local1))
                    {
                        Store (Local2, Local1)
                    }
                    If (LNotEqual (Local2, Local1))
                    {
                        // set new backlight PWMMax but retain current backlight level by scaling
                        Store ((LEVL * Local2) / Local1, Local0)
                        Store (Local2 << 16, Local3)
                        If (LGreater (Local2, Local1))
                        {
                            // PWMMax is getting larger... store new PWMMax first
                            Store (Local3, LEVX)
                            Store (Local0, LEVL)
                        }
                        Else
                        {
                            // otherwise, store new brightness level, followed by new PWMMax
                            Store (Local0, LEVL)
                            Store (Local3, LEVX)
                        }
                    }
                }
            }
        }""";
    }
    ssdt += """
    }
}""";

    // 替换占位符
    ssdt = ssdt
        .replaceAll(r"[[uid_value]]", util.hexy(uid))
        .replaceAll(r"[[uid_dec]]", uid.toString())
        .replaceAll(r"[[igpu_path]]", igpu);
    // 写入 SSDT 文件
    writeSSDT(ssdtName, ssdt);
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

    hasNbcfOld = patches.any((p) => p["Comment"].contains("NBCF 0x00"));
    hasNbcfNew = patches.any((p) => p["Comment"].contains("NBCF Zero"));
    if (hasNbcfOld || hasNbcfNew) {
      Log.warning(
        "注意：已生成 NBCF 补丁(依赖BrightnessKeys.kext驱动),默认启用！如果在使用过程中遇到问题,请禁用该补丁!",
      );
    }
  }

  Future<void> ssdtEC({
    bool prebuilt = false,
    bool isLaptop = false,
    bool injectUSBPower = false,
  }) async =>
      prebuilt
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
    String ssdtName =
        injectUSBPower ? 'SSDT-EC-USBX-DESKTOP' : 'SSDT-EC-DESKTOP';
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
      ssdt += """
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
      ssdt += """
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
      ssdt += """
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
  }) async =>
      prebuilt ? null : await _ssdtUSBX(usbxProps: usbxProps);

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
      ssdt += '''
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
  }) async =>
      prebuilt
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

        var ssdt = """
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
            var uid0 =
                table["lines"][uid[0][1]].split("_UID, ")[1].split(")")[0];
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

          ssdt += """
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
    final parents = tasks
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

        ssdt += '''
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
        ssdt += '''
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
      for (var item in pciRootPaths
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
        _ => adrInt > 0xFFFF
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
        final bool isValidProcessorApic = line.contains('Subtable Type :') &&
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

    final List<String> basePaths =
        devices.map((e) => e.first.toString()).toList();

    for (String path in basePaths) {
      ssdt += '    External ($path, DeviceObj)\n';
      if (hasStaMap[path] == true) {
        ssdt += '    External ($path.XSTA, MethodObj)\n';
      }
    }

    ssdt += '\n';

    for (String path in basePaths) {
      final bool hasSta = hasStaMap[path] ?? false;

      String devName =
          path.replaceAll(RegExp(r'_+$'), '').replaceAll('_SB_', '\\_SB');

      if (hasSta) {
        ssdt += '''
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
        ssdt += '''
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

  Future<void> _ssdtLED() async {
    if (!await ensureDSDT()) return;
    String sstPath = "";
    List<dynamic> wak = [];
    List<dynamic> zwak = [];
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
      if (wak.isEmpty) {
        Log("正在检查是否存在 _WAK方法...");
        wak = d.getMethodInfo(obj: "_WAK", table: table);
        if (wak.isNotEmpty) {
          Log("=> 已找到 ${wak.first} 方法!");
        } else {
          Log("=> 未找到 _WAK 方法!");
        }
      }

      if (wak.isEmpty && zwak.isEmpty) {
        Log("正在检查是否存在 ZWAK 方法...");
        // 检查是否存在 ZWAK 方法
        zwak = d.getMethodInfo(obj: "ZWAK");
        if (zwak.isNotEmpty) {
          Log.warning("=> 已找到 ${zwak.first} 方法!");
        }
        if (zwak.isNotEmpty) {
          Log.warning("=> 当前方法已经被重命名,可能非原始ACPI表!");
        }
      }
    }
    if (sstPath.isEmpty) {
      Log.warning("=> 在上述所有ACPI表中均未找到 _SST 方法! 已终止操作！\n");
      return;
    }
    final ssdtName = "SSDT-LED";
    Log("正在创建 $ssdtName.dsl...");
    final ssdt = '''
 DefinitionBlock ("", "SSDT", 1, "RAPID", "LED", 0x00000000)
{
    External ($sstPath, MethodObj)
    External (ZWAK, MethodObj)
    Method (_WAK, 1, ${wak.last})
    {
      
      If (_OSI ("Darwin"))
        {
            If (Arg0 = 0x03)
            {
                $sstPath (One)
            }
        }

        Return (ZWAK (Arg0))
    }
}
    ''';
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Fixing LED issues - requires _WAK to ZWAK rename",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    final patches = [
      {
        "Comment": "_WAK to ZWAK (1,${wak.last[0]})",
        "Find": wak.last == "NotSerialized" ? "5F57414B01" : "5F57414B09",
        "Replace": wak.last == "NotSerialized" ? "5A57414B01" : "5A57414B09",
      },
    ];
    makePlist(acpi: acpi, patches: patches, replace: true);
  }

  Future<void> ssdtWakeScreen({bool prebuilt = false}) async =>
      _ssdtWakeScreen();

  Future<void> _ssdtWakeScreen() async {
    if (!await ensureDSDT()) return;
    String devicePath = "";
    List<dynamic> wak = [];
    List<dynamic> zwak = [];
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
      if (wak.isEmpty) {
        Log("正在检查是否存在 _WAK方法...");
        wak = d.getMethodInfo(obj: "_WAK", table: table);
        if (wak.isNotEmpty) {
          Log("=> 已找到 ${wak.first} 方法!");
          break;
        } else {
          Log("=> 未找到 _WAK 方法!");
        }
      }
      if (wak.isEmpty && zwak.isEmpty) {
        Log("正在检查是否存在 ZWAK 方法...");
        // 检查是否存在 ZWAK 方法
        zwak = d.getMethodInfo(obj: "ZWAK");
        if (zwak.isNotEmpty) {
          Log.warning("=> 已找到 ${zwak.first} 方法!");
          break;
        }
        if (zwak.isNotEmpty) {
          Log.warning("=> 当前方法已经被重命名,可能非原始ACPI表!");
        }
      }
    }
    if (devicePath.isEmpty) {
      Log.warning("=> 在上述所有ACPI表中均未找到 PNP0C0D 设备! 已终止操作！\n");
      return;
    }
    if (wak.isEmpty && zwak.isEmpty) {
      Log.warning("=> 在上述所有ACPI表中均未找到 _WAK、ZWAK 方法! 已终止操作！\n");
      return;
    }
    final ssdtName = "SSDT-WakeScreen";
    Log("正在创建 $ssdtName.dsl...");
    String ssdt = '''
  DefinitionBlock("", "SSDT", 2, "RAPID", "WakeS", 0x00000000)
{
    External($devicePath, DeviceObj)
    External (ZWAK, MethodObj)
    Method (_WAK, 1, ${wak.last})
    {   
        If (_OSI ("Darwin"))
        {
            If (Arg0 = 0x03)
            {
                Notify ($devicePath, 0x80)
            }
        }
        Return (ZWAK (Arg0))
    }
}      
      ''';
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment": "Fixing WakeScreen issues - requires _WAK to ZWAK rename",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    final patches = [
      {
        "Comment": "_WAK to ZWAK (1,${wak.last[0]})",
        "Find": wak.last == "NotSerialized" ? "5F57414B01" : "5F57414B09",
        "Replace": wak.last == "NotSerialized" ? "5A57414B01" : "5A57414B09",
      },
    ];
    makePlist(acpi: acpi, patches: patches, replace: true);
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
    final ssdt = '''
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
    List<dynamic> pts = [];
    List<dynamic> wak = [];
    List<dynamic> tts = [];
    List<dynamic> zpts = [];
    List<dynamic> zwak = [];
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
      if (pts.isEmpty) {
        Log("正在检查是否存在 _PTS方法...");
        pts = d.getMethodInfo(obj: "_PTS", table: table);
        if (pts.isNotEmpty) {
          Log("=> 已找到 ${pts.first} 方法!");
        } else {
          Log("=> 未找到 _PTS 方法!");
        }
      }
      if (wak.isEmpty) {
        Log("正在检查是否存在 _WAK方法...");
        wak = d.getMethodInfo(obj: "_WAK", table: table);
        if (wak.isNotEmpty) {
          Log("=> 已找到 ${wak.first} 方法!");
        } else {
          Log("=> 未找到 _WAK 方法!");
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
      if (pts.isNotEmpty && wak.isNotEmpty && tts.isNotEmpty) {
        Log("");
        break;
      }
      // 通常是成对处理 _PTS 和 _WAK 方法
      if ((pts.isEmpty || wak.isEmpty) && zpts.isEmpty && zwak.isEmpty) {
        Log("正在检查是否存在 ZPTS/ZWAK 方法...");
        // 检查是否存在 ZPTS 方法
        zpts = d.getMethodInfo(obj: "ZPTS");
        zwak = d.getMethodInfo(obj: "ZWAK");
        if (zpts.isNotEmpty) {
          Log.warning("=> 已找到 ${zpts.first} 方法!");
        }
        if (zwak.isNotEmpty) {
          Log.warning("=> 已找到 ${zwak.first} 方法!");
        }
        if (zpts.isNotEmpty || zwak.isNotEmpty) {
          Log.warning("=> 当前方法已经被重命名,可能非原始ACPI表!");
        }
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
    if (pts.isEmpty || wak.isEmpty) {
      Log.warning("=> 在上述所有ACPI表中均未找到 _PTS/_WAK 方法! 已终止操作！\n");
      return;
    }
    if (zpts.isNotEmpty || zwak.isNotEmpty) {
      Log.warning("=> 注意: 当前提取的ACPI表中,方法_PTS/_WAK已经被重命名为ZPTS/ZWAK!\n");
    }

    final ssdtName = "SSDT-LID";
    Log("正在创建 $ssdtName.dsl...");
    final ssdt = '''
DefinitionBlock("", "SSDT", 2, "RAPID", "LID", 0x00000000)
{
    External($devicePath, DeviceObj)
    External($devicePath.XLID, MethodObj)
    External (ZPTS, MethodObj)
    External (ZWAK, MethodObj)
    Scope (_SB)
    {
        Device (PCI9)
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
        }
    }
   
    Method (_PTS, 1, NotSerialized)
    {
      If (_OSI ("Darwin")) {
          If (Arg0 == 0x03)
        {
            \\_SB.PCI9.FNOK = 1
        }
        Else
        {
            \\_SB.PCI9.FNOK = 0
        }
       }
       ZPTS(Arg0)
    }

    Method (_WAK, 1, NotSerialized)
    {
       If (_OSI ("Darwin")) {
            \\_SB.PCI9.FNOK = 0
        }
        Return (ZWAK(Arg0))
    }

    Scope ($devicePath)
    {
        Method (_LID, 0, NotSerialized)
        {
            If (_OSI ("Darwin"))
            {
                if(\\_SB.PCI9.FNOK==1)
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

    writeSSDT(ssdtName, ssdt);

    final acpi = {
      "Comment":
          "Spoof a PNP0C0E sleep button for macOS sleep and wake - requires _LID to XLID rename",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    final patches = [
      {
        "Comment": "_PTS to ZPTS (1,${pts.last[0]})",
        "Find": pts.last == "NotSerialized" ? "5F50545301" : "5F50545309",
        "Replace": pts.last == "NotSerialized" ? "5A50545301" : "5A50545309",
      },
      {
        "Comment": "_WAK to ZWAK (1,${wak.last[0]})",
        "Find": wak.last == "NotSerialized" ? "5F57414B01" : "5F57414B09",
        "Replace": wak.last == "NotSerialized" ? "5A57414B01" : "5A57414B09",
      },
      {
        "Comment": "_LID to XLID rename - requires $ssdtName.aml",
        "Find": "5F4C494400",
        "Replace": "584C494400",
      },
    ];
    makePlist(acpi: acpi, patches: patches, replace: true);
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
        ssdt = '''
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
        ssdt = '''
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
    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment":
          "Fixing Shutdown for XHC Controllers - requires _PTS to ZPTS rename",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    final patches = [
      {
        "Comment": "_PTS to ZPTS rename - requires $ssdtName.aml",
        "Find": "5F505453",
        "Replace": "5A505453",
        "Count": 1,
      },
    ];
    makePlist(acpi: acpi, patches: patches, replace: true);
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
 * Do note this SSDT requires an ACPI hot patch for _PTS to ZPTS as 
 * we're rerouting the old calls.
 * Source for SSDT: Rehabman
 */

DefinitionBlock ("", "SSDT", 2, "RAPID", "ZPTS", 0x00000000)
{
  """;

    for (String basePath in xhcis) {
      ssdt += '    External ($basePath.PMEE, FieldUnitObj)\n';
    }
    ssdt += '\n';
    ssdt += '    External (ZPTS, MethodObj)';

    ssdt += '''
    Method (_PTS, 1, NotSerialized) 
    {
        ZPTS (Arg0)
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

    writeSSDT(ssdtName, ssdt);
    final acpi = {
      "Comment":
          "Fixing Shutdown for XHC Controllers - requires _PTS to ZPTS rename",
      "Enabled": true,
      "Path": "$ssdtName.aml",
    };
    final patches = [
      {
        "Comment": "_PTS to ZPTS rename - requires $ssdtName.aml",
        "Find": "5F505453",
        "Replace": "5A505453",
        "Count": 1,
      },
    ];
    makePlist(acpi: acpi, patches: patches, replace: true);
  }

  Future<void> ssdtGPRW({bool prebuilt = true}) async =>
      prebuilt ? await _ssdtGPRWPrebuilt() : await _ssdtGPRW();

  Future<void> _ssdtGPRW() async {
    if (!await ensureDSDT()) return;
    // 检查是否存在 GPRW 方法
    Log('正在检查是否存在 GPRW 方法...');
    var gprw = d.getMethodPaths(obj: 'GPRW');
    if (gprw.isEmpty) {
      Log.warning('=> 未找到 GPRW 方法！');
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
    if (gprw.isNotEmpty) {
      Log('=> 已在 ${gprw[0][0]} 找到 GPRW 方法！');
      _ssdtGPRWPrebuilt();
    }
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
    String devName =
        gpioPath.replaceAll(RegExp(r'_+$'), '').replaceAll('_SB_', '\\_SB');
    String ssdt = '''
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
            var uid0 =
                table["lines"][uid[0][1]].split("_UID, ")[1].split(")")[0];
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

          ssdt += """
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
  }) async =>
      await _ssdtPCIDISABLE(
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
        foundMethod = _hasMethodInTables(pciPath, ['_PS3,_DSM']);
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
  String _buildSsdtOFF(String pciPath, String type) => '''
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
  String _buildSsdtPS3(String pciPath, String type) => '''
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
    final dsmMethod = '''
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
    final bridgeBody = '''
    Scope ($pciPath)
    {
        Device (BRG0)
        {
            Name (_ADR, Zero)
            $dsmMethod
        }
    }
  ''';

    final normalBody = '''
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
  }) async =>
      await _ssdtGPUSPOOF(
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

    String ssdt = """
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
      Log(
        success ? '已成功保存 plist: ${entry.key}' : '保存 plist 失败: ${entry.key}',
      );
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
          "NormalizeHeaders": config.acpiMatchMode ==
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
          "FixHeaders": config.acpiMatchMode ==
              ACPIMatchMode.tableIDsAndLengthAndNormalizeHeaders,
        },
        replace,
        type,
      );
    }

    if (!isBatching && plist.isNotEmpty) {
      final success = parser.savePlist(plistPath, plist);
      Log(
        success ? '已成功保存 plist: $plistPath' : '保存 plist 失败: $plistPath',
      );
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
  }

  List<T?> _normalizeItems<T>(dynamic input) {
    if (input == null) return [];

    if (input is List) {
      return input.cast<T?>();
    } else {
      return [input as T?];
    }
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
      current = current.putIfAbsent(path[i], () => <String, dynamic>{})
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

    final section =
        effectivePath.isEmpty ? plist : _getOrInitAtPath(plist, effectivePath);

    final validItems =
        (rawItems ?? []).whereType<T>().where(_isValidItem).toList();

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
        '路径 ${[
          "ACPI",
          ...keyPath
        ].join(".")} 既不是 List 也不是 Map，而是 ${section.runtimeType}',
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

    if (table == null) {
      mode = ACPIMatchMode.leastStrict;
    }

    // 定义零字节数组的大小
    int byteLength = idName == "id" ? 8 : 4;
    List<int> zero = util.getHexBytes("00" * byteLength);

    dynamic rawValue;

    switch (mode) {
      case ACPIMatchMode.tableIDsAndLength:
        rawValue = table?[idName];
        break;
      case ACPIMatchMode.tableIDsAndLengthAndNormalizeHeaders:
        rawValue = table?["${idName}_ascii"] ?? table?[idName] ?? zero;
        break;
      default: // leastStrict / lengthOnly
        return zero;
    }

    if (rawValue is String) {
      return rawValue.codeUnits;
    } else if (rawValue is List<int>) {
      return rawValue;
    } else {
      return zero;
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
