//  merge.dart
//  Created by JeoJay127
//
import 'dart:convert';
import 'dart:io';
import '../log/log.dart';
import 'parser.dart';
import 'package:path/path.dart' as path;
import 'util.dart';
import 'config.dart';

class PatchMerge {
  String? patchedPath;
  String? configPath;
  String? resultsFolder;
  bool overwrite;
  bool backupBeforeOverwrite;
  PlistParser plistParser = PlistParser();
  final String resultsFolderName = "Results";
  Util util = Util();
  final List<(PlistType, String)> targetPatches = [
    (PlistType.openCore, 'patches_OC.plist')
  ];

  PatchMerge({
    this.patchedPath,
    this.configPath,
    this.overwrite = false,
    this.backupBeforeOverwrite = true,
  });

  List<(String, bool, String)> _getPatchesPlists(String? plistDirectory) {
    List<(String, bool, String)> pathChecks = [];
    for (var (_, name) in targetPatches) {
      if (plistDirectory != null) {
        String p = path.join(plistDirectory, name);
        bool isFile = File(p).existsSync();
        pathChecks.add((p, isFile, name));
      } else {
        pathChecks.add(('', false, name));
      }
    }
    return pathChecks;
  }

  Future<String?> getDefaultResultsFolder() async {
    final String patchedPlistPath = patchedPath ?? '';
    String patchedResults = path.join(patchedPlistPath, resultsFolderName);
    List<String> potentials = [];
    for (String p in [patchedResults]) {
      if (Directory(p).existsSync()) {
        var pathInfoList = _getPatchesPlists(p);
        if (pathInfoList.any((pathInfo) => pathInfo.$2)) {
          potentials.add(p);
        }
      }
    }

    if (potentials.isNotEmpty) {
      return potentials[0];
    }
    return await selectResultsFolder(patchedResults);
  }

  /// 选择并校验结果文件夹路径
  /// [resultsPath]：传入的结果路径
  Future<String?> selectResultsFolder(String resultsPath) async {
    try {
      // 处理异步路径检查
      final folderPath = await util.checkPath(filePath: resultsPath);
      if (folderPath.isEmpty) {
        Log.error("路径检查失败，返回空路径");
        return null;
      }

      // 校验路径是否为有效的目录
      final directory = Directory(folderPath);
      if (!directory.existsSync()) {
        Log.warning("修补ACPI路径不存在: $folderPath");
        return null;
      }

      // 检查目录下是否有目标plist文件
      final pathInfoList = _getPatchesPlists(folderPath);
      // 校验pathInfoList是否合法（避免空列表导致的索引越界）
      if (pathInfoList.length < 2) {
        Log.warning("获取plist文件信息失败，返回结果不完整");
        return null;
      }
      // 检查是否存在至少一个目标plist文件
      if (!(pathInfoList[0].$2 || pathInfoList[1].$2)) {
        Log.warning(
          "在修补ACPI路径: $folderPath 下未找到 patches_OC.plist 和 patches_Clover.plist 文件!请先制作需要的ACPI补丁后再尝试！",
        );
        return null;
      }

      // 所有校验通过，返回有效路径
      return folderPath;
    } catch (e) {
      // 捕获所有异常
      Log.error("处理结果文件夹路径时发生错误: $e");
      return null;
    }
  }

  (bool, String) getAsciiPrint(List<int> data) {
    bool unprintables = false;
    bool allZeroes = true;
    String asciiString = '';
    for (int b in data) {
      if (b != 0) {
        allZeroes = false;
      }
      if (32 <= b && b < 127) {
        asciiString += String.fromCharCode(b);
      } else {
        asciiString += '?';
        unprintables = true;
      }
    }
    return (allZeroes ? false : unprintables, asciiString);
  }

  bool checkNormalize(
    Map<String, dynamic> patchOrDrop,
    bool normalizeHeaders, {
    String checkType = 'Patch',
  }) {
    List<String> sig = ['OemTableId', 'TableSignature'];
    if (normalizeHeaders) {
      for (String key in sig) {
        var (unprintable, _) = getAsciiPrint(
          _extractData(patchOrDrop[key] ?? 0),
        );
        if (unprintable) {
          Log.warning('\n注意: NormalizeHeaders 已启用，且表 ID 包含不可打印字符！');
          Log.warning('$checkType 可能无法匹配或应用！\n');
          return true;
        }
      }
    } else {
      for (String key in sig) {
        if (_extractData(patchOrDrop[key] ?? 0).contains(0x3F)) {
          Log.warning('\n注意: NormalizeHeaders 未启用，且表 ID 包含 \'?\' 字符！');
          Log.warning('$checkType 可能无法匹配或应用！\n');
          return true;
        }
      }
    }
    return false;
  }

  List<int> _extractData(dynamic data) {
    if (data is List<int>) {
      return data;
    } else if (data is String) {
      return utf8.encode(data);
    }
    return [];
  }

  String getUniqueName(
    String name,
    String targetFolder, [
    String nameAppend = '',
  ]) {
    name = path.basename(name);
    String ext = path.extension(name);
    if (ext.isNotEmpty) {
      name = name.substring(0, name.length - ext.length);
    }
    if (nameAppend.isNotEmpty) {
      name += nameAppend;
    }
    String checkName = ext.isNotEmpty ? '$name$ext' : name;
    if (!File(path.join(targetFolder, checkName)).existsSync()) {
      return checkName;
    }
    int num = 1;
    while (true) {
      checkName = ext.isNotEmpty ? '$name-$num$ext' : '$name-$num';
      if (!File(path.join(targetFolder, checkName)).existsSync()) {
        return checkName;
      }
      num++;
    }
  }

  Future<void> mergePlist() async {
    if (!validateConfigPath()) return;
    if (!await findResultsFolder()) return;

    var (plistType, configData, e) = getPlistInfo(configPath!);
    if (!handlePlistLoadingError(plistType, e)) return;
    Log('=> 当前引导类型: ${plistType.value}');
    Log('=> 当前config路径: $configPath');
    Log('=> 当前补丁路径: $resultsFolder');
    var pathInfo = getPatchPlistForType(resultsFolder!, plistType);
    if (!validatePatchFile(pathInfo)) return;
    var (_, targetData, e2) = getPlistInfo(pathInfo.$1);
    if (!handlePatchFileLoadingError(plistType, e2)) return;
    final resultMap = setupData(configData, targetData, plistType);

    handleSsdts(
      plistType,
      resultMap['ssdts'],
      resultMap['sOrig'],
      resultMap['errorsFound'],
    );
    handlePatches(
      plistType,
      resultMap['patch'],
      resultMap['pOrig'],
      resultMap['normalizeHeaders'],
      resultMap['errorsFound'],
    );
    handleDrops(
      plistType,
      resultMap['drops'],
      resultMap['dOrig'],
      resultMap['normalizeHeaders'],
      resultMap['errorsFound'],
    );
    handleQuirks(plistType, resultMap['quirks'], resultMap['quirksOrig']);
    await saveConfig(plistType, configData, resultMap['errorsFound']);
  }

  bool validateConfigPath() {
    if (configPath == null) {
      Log.warning('未选择目标 config.plist 文件！');
      return false;
    }
    if (!File(configPath!).existsSync()) {
      Log.warning('未找到目标 config.plist 文件：$configPath');
      return false;
    }
    return true;
  }

  Future<bool> findResultsFolder() async {
    resultsFolder = await getDefaultResultsFolder();
    if (resultsFolder == null || resultsFolder!.isEmpty) {
      return false;
    }
    return true;
  }

  bool handlePlistLoadingError(PlistType plistType, dynamic e) {
    String configName = path.basename(configPath!);
    Log('正在加载 $configName...');
    if (e != null) {
      Log.error('=> 加载失败！失败原因: $e \n');
      return false;
    }
    if (plistType == PlistType.unknown) {
      Log.warning('=> 无法确定 config.plist 类型！\n');
      return false;
    }
    return true;
  }

  bool validatePatchFile((String, bool, String) pathInfo) {
    if (!pathInfo.$2) {
      Log.error('未找到补丁路径下 ${pathInfo.$3} 文件！已终止操作！\n');
      return false;
    }
    if (!File(pathInfo.$1).existsSync()) {
      Log.error('未找到所需修补文件：${pathInfo.$1}！已终止操作！\n');
      return false;
    }
    String targetName = path.basename(pathInfo.$1);
    Log('正在加载补丁 $targetName...');
    return true;
  }

  bool handlePatchFileLoadingError(PlistType plistType, dynamic e2) {
    if (e2 != null) {
      Log.error('=> 加载失败！失败原因: $e2\n');
      return false;
    }
    String configName = path.basename(configPath!);
    String targetName = path.basename(
      getPatchPlistForType(resultsFolder!, plistType).$1,
    );
    Log('正在检查并确保 $configName 和 $targetName 中的路径配置无误...');
    return true;
  }

  Map<String, dynamic> setupData(
    dynamic configData,
    dynamic targetData,
    PlistType plistType,
  ) {
    bool errorsFound = false;
    dynamic normalizeHeaders;
    List<dynamic> ssdts = [];
    List<dynamic> patch = [];
    List<dynamic> drops = [];
    Map<dynamic, dynamic> quirks = {};
    List<dynamic> sOrig = [];
    List<dynamic> pOrig = [];
    List<dynamic> dOrig = [];
    Map<dynamic, dynamic> quirksOrig = {};
    final ensurePath = util.ensurePath;
    if (plistType == PlistType.openCore) {
      normalizeHeaders =
          configData['ACPI']['Quirks']['NormalizeHeaders'] ?? false;
      if (normalizeHeaders is! bool) {
        errorsFound = true;
        normalizeHeaders = false;
      }
      ssdts = ensurePath(targetData, ["ACPI", "Add"], List);
      patch = ensurePath(targetData, ["ACPI", "Patch"], List);
      drops = ensurePath(targetData, ["ACPI", "Delete"], List);
      quirks = ensurePath(targetData, ["ACPI", "Quirks"], Map);
      sOrig = ensurePath(configData, ["ACPI", "Add"], List);
      pOrig = ensurePath(configData, ["ACPI", "Patch"], List);
      dOrig = ensurePath(configData, ["ACPI", "Delete"], List);
      quirksOrig = ensurePath(configData, ["ACPI", "Quirks"], Map);
    } else {
      ssdts = ensurePath(targetData, ["ACPI", "SortedOrder"], List);
      patch = ensurePath(targetData, ["ACPI", "DSDT", "Patches"], List);
      drops = ensurePath(targetData, ["ACPI", "DropTables"], List);
      quirks = ensurePath(targetData, ["ACPI"], Map);
      sOrig = ensurePath(configData, ["ACPI", "SortedOrder"], List);
      pOrig = ensurePath(configData, ["ACPI", "DSDT", "Patches"], List);
      dOrig = ensurePath(configData, ["ACPI", "DropTables"], List);
      quirksOrig = ensurePath(configData, ["ACPI"], Map);
    }

    return {
      'ssdts': ssdts,
      'patch': patch,
      'drops': drops,
      'quirks': quirks,
      'sOrig': sOrig,
      'pOrig': pOrig,
      'dOrig': dOrig,
      'quirksOrig': quirksOrig,
      'normalizeHeaders': normalizeHeaders,
      'errorsFound': errorsFound,
    };
  }

  void handleSsdts(
    PlistType plistType,
    List<dynamic> ssdts,
    List<dynamic> sOrig,
    bool errorsFound,
  ) {
    Log('');
    if (ssdts.isEmpty) {
      Log.warning('=> 未找到 SSDT 表！跳过...');
      return;
    }
    Log('=> 正在检查目标 SSDT 表（共 ${ssdts.length} 个）...');
    List<dynamic> sRem = [];
    List<dynamic> sBroken = plistType == PlistType.openCore
        ? sOrig.where((x) => x is! Map).toList()
        : [];
    for (var s in ssdts) {
      if (plistType == PlistType.openCore) {
        Log('=> 正在检查 ${s['Path']}...');
        List<dynamic> existing =
            sOrig.where((x) => x is Map && x['Path'] == s['Path']).toList();
        if (existing.isNotEmpty) {
          Log('=> 已找到 ${existing.length} 个相同 SSDT 表，标记为替换...');
          sRem.addAll(existing);
        }
      } else {
        Log('=> 正在检查 $s...');
        List<dynamic> existing = sOrig.where((x) => x == s).toList();
        if (existing.isNotEmpty) {
          Log('=> 已找到 ${existing.length} 个相同 SSDT 表，标记为替换...');
          sRem.addAll(existing);
        }
      }
    }
    if (sRem.isNotEmpty) {
      Log('=> 正在移除 ${sRem.length} 个重复 SSDT 表...');
      for (var r in sRem) {
        sOrig.remove(r);
      }
    } else {
      Log('=> 未找到重复 SSDT 表！');
    }
    Log('=> 正在添加 ${ssdts.length} 个 SSDT 表...');
    sOrig.addAll(ssdts);
    if (sBroken.isNotEmpty) {
      errorsFound = true;
      Log.error(
        '\n注意: 已找到 ${sBroken.length} 个格式错误的 SSDT 表,请修复 ${path.basename(configPath!)}！',
      );
    }
  }

  void handlePatches(
    PlistType plistType,
    List<dynamic> patch,
    List<dynamic> pOrig,
    dynamic normalizeHeaders,
    bool errorsFound,
  ) {
    Log('');
    if (patch.isEmpty) {
      Log('=> 未找到 Patch 补丁！跳过...');
      return;
    }
    Log('=> 正在检查目标 Patch 补丁（共 ${patch.length} 个）...');
    List<dynamic> pRem = [];
    List<dynamic> pBroken = pOrig.where((x) => x is! Map).toList();
    for (var p in patch) {
      Log('=> 正在检查 ${p['Comment']}...');
      if (plistType == PlistType.openCore &&
          checkNormalize(p, normalizeHeaders)) {
        errorsFound = true;
      }
      List<dynamic> existing = pOrig
          .where(
            (x) =>
                x is Map &&
                util.deepEquals(x['Find'], p['Find']) &&
                util.deepEquals(x['Replace'], p['Replace']),
          )
          .toList();
      if (existing.isNotEmpty) {
        Log('=> 已找到 ${existing.length} 个相同 Patch 补丁，标记为替换...');
        pRem.addAll(existing);
      }
    }
    if (pRem.isNotEmpty) {
      Log('=> 正在移除 ${pRem.length} 个重复 Patch 补丁...');
      for (var r in pRem) {
        pOrig.remove(r);
      }
    } else {
      Log('=> 未找到重复 Patch 补丁！');
    }
    Log('=> 正在添加 ${patch.length} 个 Patch 补丁...');
    pOrig.addAll(patch);
    if (pBroken.isNotEmpty) {
      errorsFound = true;
      Log.error(
        '\n注意: 已找到 ${pBroken.length} 个格式错误的 Patch 补丁,请修复 ${path.basename(configPath!)}！',
      );
    }
  }

  void handleDrops(
    PlistType plistType,
    List<dynamic> drops,
    List<dynamic> dOrig,
    dynamic normalizeHeaders,
    bool errorsFound,
  ) {
    Log('');
    if (drops.isEmpty) {
      Log('=> 未找到 Drop 补丁！跳过...');
      return;
    }
    Log('=> 正在检查目标 Drop 补丁（共 ${drops.length} 个）...');
    List<dynamic> dRem = [];
    List<dynamic> dBroken = dOrig.where((x) => x is! Map).toList();
    for (var d in drops) {
      if (plistType == PlistType.openCore) {
        Log('=> 正在检查 ${d['Comment']}...');
        if (checkNormalize(d, normalizeHeaders, checkType: 'Dropped table')) {
          errorsFound = true;
        }
        List<dynamic> existing = dOrig
            .where(
              (x) =>
                  x is Map &&
                  util.deepEquals(x['TableSignature'], d['TableSignature']) &&
                  util.deepEquals(x['OemTableId'], d['OemTableId']),
            )
            .toList();
        if (existing.isNotEmpty) {
          Log('=> 已找到 ${existing.length} 个相同 Drop 补丁，标记为替换...');
          dRem.addAll(existing);
        }
      } else {
        String name = [
          d['Signature'] ?? '',
          d['TableId'] ?? '',
        ].where((x) => x.isNotEmpty).join(' - ');
        Log('=> 正在检查 $name...');
        List<dynamic> existing = dOrig
            .where(
              (x) =>
                  x is Map &&
                  util.deepEquals(x['Signature'], d['Signature']) &&
                  util.deepEquals(x['TableId'], d['TableId']),
            )
            .toList();
        if (existing.isNotEmpty) {
          Log('=> 已找到 ${existing.length} 个相同 Drop 补丁，标记为替换...');
          dRem.addAll(existing);
        }
      }
    }
    if (dRem.isNotEmpty) {
      Log('=> 正在移除 ${dRem.length} 个重复 Drop 补丁...');
      for (var r in dRem) {
        dOrig.remove(r);
      }
    } else {
      Log('=> 未找到重复 Drop 补丁！');
    }
    Log('=> 正在添加 ${drops.length} 个 Drop 补丁...');
    dOrig.addAll(drops);
    if (dBroken.isNotEmpty) {
      errorsFound = true;
      Log.error(
        '\n注意: ${dBroken.length} 个格式错误的 Drop 补丁,请修复 ${path.basename(configPath!)}！',
      );
    }
  }

  void handleQuirks(
    PlistType plistType,
    Map<dynamic, dynamic> quirks,
    Map<dynamic, dynamic> quirksOrig,
  ) {
    Log('');
    if (quirks.isEmpty) {
      Log('=> 未找到需要更新的 Quirks 配置！跳过...');
      return;
    }
    Log('=> 正在检查目标 Quirks 配置...');
    for (var q in quirks.entries) {
      if (q.value is bool) {
        Log('=> 更新 ${q.key} 为 ${q.value}');
        quirksOrig[q.key] = quirks[q.key];
      }
    }
  }

  String _generateBackupFileName(String originalPath) {
    final directory = path.dirname(originalPath);
    final fileName = path.basenameWithoutExtension(originalPath);
    final extension = path.extension(originalPath);

    int counter = 1;
    String backupFileName;
    String backupPath;

    do {
      backupFileName = '$fileName-backup-$counter$extension';
      backupPath = path.join(directory, backupFileName);
      counter++;
    } while (File(backupPath).existsSync());

    return backupPath;
  }

  void backupConfig(String configPath) {
    Log('正在备份当前config配置文件...');
    String backupPath = _generateBackupFileName(configPath);
    File(configPath).copySync(backupPath);
    Log('已成功备份文件到: $backupPath');
  }

  String resolveOutputPath() {
    if (overwrite) {
      return configPath!;
    }
    return path.join(resultsFolder!, path.basename(configPath!));
  }

  Future<void> copyAmlFiles(PlistType plistType, String configPath) async {
    Log('准备复制 SSDT 文件...');

    String acpiPath = path.join(path.dirname(configPath), 'ACPI');
    if (plistType == PlistType.clover) {
      acpiPath = path.join(acpiPath, 'patched');
    }

    String? results = await getDefaultResultsFolder();

    if (Directory(acpiPath).existsSync()) {
      if (results != null && Directory(results).existsSync()) {
        Directory(results).listSync().forEach((element) {
          if (element.path.endsWith('.aml')) {
            Log('正在拷贝 " ${path.basename(element.path)} " 到 $acpiPath 目录...');
            File(
              element.path,
            ).copySync(path.join(acpiPath, path.basename(element.path)));
          }
        });
      } else {
        Log('未找到目录: $results');
      }
    } else {
      Log('未找到目录: $acpiPath');
      Log('请手动将 $results 目录下所有 .aml 文件,拷贝到 $acpiPath 目录下！');
    }
  }

  bool savePlist(String outputPath, dynamic configData) {
    final bool success = plistParser.savePlist(
      outputPath,
      configData,
      onError: (error) => Log.error(error),
    );

    if (success) {
      Log('保存配置成功！');
      Log('合并已完成!\n');
    } else {
      Log.error('合并失败!\n');
    }

    return success;
  }

  void logWarningsAndErrors(bool success, bool errorsFound) {
    if (errorsFound) {
      Log.error('注意: 合并过程中发现潜在错误,请检查并修复！');
    } else {
      if (!overwrite) {
        final outputDir = path.dirname(resolveOutputPath());
        final efiDir = path.dirname(configPath!);
        final acpiDir = path.join(path.dirname(configPath!), 'ACPI');
        Log.warning('注意: 当前配置未设置为覆盖目标EFI模式!');
        Log.warning('你需要手动进行以下操作:');
        Log.warning('1. 你需要手动将 $outputDir 目录下 config.plist 文件替换到 $efiDir 目录下！');
        Log.warning('2. 你需要手动将 $outputDir 目录下所有 .aml 文件,拷贝到 $acpiDir 目录下！');
      }
    }
  }

  Future<void> saveConfig(
    PlistType plistType,
    dynamic configData,
    bool errorsFound,
  ) async {
    Log('');
    if (overwrite) {
      if (backupBeforeOverwrite) {
        backupConfig(configPath!);
      }
      await copyAmlFiles(plistType, configPath!);
    }

    final String outputPath = resolveOutputPath();
    Log('正在保存配置到路径: $outputPath...');
    final bool success = savePlist(outputPath, configData);
    logWarningsAndErrors(success, errorsFound);
  }

  (PlistType, Map<String, dynamic>, dynamic) getPlistInfo(String configPath) {
    try {
      PlistParseResult configData = plistParser.loadPlist(configPath);
      if (configData.status != PlistParseStatus.success) {
        return (PlistType.unknown, configData.data ?? {}, null);
      }
      final data = configData.data ?? {};
      PlistType plistType = PlistType.unknown;
      if (_hasCloverFeatures(data)) {
        plistType = PlistType.clover;
      } else if (_hasOpenCoreFeatures(data)) {
        plistType = PlistType.openCore;
      }

      return (plistType, data, null);
    } catch (e) {
      return (PlistType.unknown, {}, e);
    }
  }

  bool _hasCloverFeatures(Map<String, dynamic> data) {
    final acpi = data['ACPI'] as Map<String, dynamic>?;
    return (acpi?.containsKey('SortedOrder') ?? false) ||
        (acpi?.containsKey('DSDT') ?? false) ||
        (acpi?.containsKey('DropTables') ?? false) ||
        data.containsKey('SMBIOS');
  }

  bool _hasOpenCoreFeatures(Map<String, dynamic> data) {
    final acpi = data['ACPI'] as Map<String, dynamic>?;
    return (acpi?.containsKey('Add') ?? false) ||
        (acpi?.containsKey('Patch') ?? false) ||
        (acpi?.containsKey('Delete') ?? false) ||
        data.containsKey('PlatformInfo');
  }

  (String, bool, String) getPatchPlistForType(
    String path,
    PlistType plistType,
  ) {
    var pathInfoList = _getPatchesPlists(path);
    return plistType == PlistType.openCore ? pathInfoList[0] : pathInfoList[1];
  }
}
