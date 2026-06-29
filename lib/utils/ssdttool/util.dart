//  util.dart
//  Created by JeoJay127
//
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

class Util {
  /// 获取桌面目录
  String getDesktopDirectory() {
    final homeDir =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (homeDir == null) {
      throw UnsupportedError('无法获取主目录');
    }
    const desktopFolder = 'Desktop';
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return path.join(homeDir, desktopFolder);
    }
    throw UnsupportedError('不支持的操作系统: ${Platform.operatingSystem}');
  }

  Future<bool> _isDirectory(String filePath) async {
    final type = await FileSystemEntity.type(filePath);
    if (type != FileSystemEntityType.notFound) {
      return type == FileSystemEntityType.directory;
    }
    return filePath.endsWith(Platform.pathSeparator) ||
        path.extension(filePath).isEmpty;
  }

  /// 清空目录
  /// [dirPath] 目录路径
  /// [folderName] 文件夹名称
  Future<void> clearDirectory(
    String dirPath,
    String folderName, {
    bool recursive = true,
  }) async {
    final dir = Directory(path.join(dirPath, folderName));
    if (await dir.exists()) {
      await dir.delete(recursive: recursive);
    }
  }

  /// 复制目录
  /// [sourceDir] 源目录路径
  /// [targetDir] 目标目录路径
  Future<void> copyDirectory(String sourceDir, String targetDir) async {
    final source = Directory(sourceDir);
    final target = Directory(targetDir);

    if (!await source.exists()) throw Exception('源目录不存在');
    if (!await target.exists()) await target.create(recursive: true);

    await for (final entity in source.list(recursive: true)) {
      final relativePath = path.relative(entity.path, from: sourceDir);
      final targetPath = path.join(targetDir, relativePath);

      if (entity is File) {
        await entity.copy(targetPath);
      } else if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      }
    }
  }

  /// 检查并准备输出路径
  /// [filePath]：输出路径（可为空、文件或目录）
  Future<String> checkPath({
    String? filePath,
    Function(String)? onError,
  }) async {
    try {
      String baseDir = getDesktopDirectory();
      if (baseDir.isEmpty) throw Exception('无法获取桌面目录');

      if (filePath == null || filePath.isEmpty) {
        return baseDir;
      }

      final isDir = await _isDirectory(filePath);
      final targetPath = path.isAbsolute(filePath)
          ? filePath
          : path.join(baseDir, filePath);

      final dir = isDir
          ? Directory(targetPath)
          : Directory(path.dirname(targetPath));
      if (!await dir.exists()) await dir.create(recursive: true);

      return targetPath;
    } on FileSystemException catch (e) {
      onError?.call('文件系统错误: ${e.message}');
    } catch (e) {
      onError?.call('处理路径错误: $e');
    }
    return '';
  }

  /// 转换IRQ值为十六进制
  /// [irq] IRQ值
  int convertIrqToInt(int irq) {
    String b = "${"0" * (16 - irq)}1${"0" * irq}";
    return int.parse(b, radix: 2);
  }

  /// 获取十六进制字符串
  /// [line] 十六进制值行
  String getHex(String line) =>
      line.split(":")[1].split("//")[0].replaceAll(" ", "");

  /// 获取行内容
  /// [line] 行内容
  String getLine(String line) {
    line = line.split("//")[0];
    if (line.contains(":")) {
      return line.split(":")[1];
    }
    return line;
  }

  /// 转换整数为十六进制字符串
  /// [total] 要转换的整数
  /// [padTo] 可选参数，指定输出字符串的最小长度，不足时在左侧填充 '0'
  String getHexFromInt(int total, {int padTo = 4}) {
    String hexStr = total.toRadixString(16).toUpperCase().padLeft(padTo, '0');
    List<String> hexParts = [];
    for (int i = 0; i < hexStr.length; i += 2) {
      hexParts.add(hexStr.substring(i, i + 2));
    }
    return hexParts.reversed.join();
  }

  /// 转换整数为十六进制字符串
  /// [integer] 要转换的整数
  /// [padTo] 最小长度，不足左侧补0，负数按0处理
  /// [uppercase] 是否大写输出，默认true
  /// [with0x] 是否带0x前缀，默认true
  String hexy(
    int integer, {
    int padTo = 0,
    bool uppercase = true,
    bool with0x = true,
  }) {
    String hex = integer.toRadixString(16);
    hex = uppercase ? hex.toUpperCase() : hex;
    hex = hex.padLeft(padTo < 0 ? 0 : padTo, '0');
    return with0x ? "0x$hex" : hex;
  }

  /// 转换十六进制字符串为字节列表
  /// [line] 十六进制字符串
  Uint8List getHexBytes(String line) {
    List<int> bytes = [];
    for (int i = 0; i < line.length; i += 2) {
      String byteStr = line.substring(i, i + 2);
      bytes.add(int.parse(byteStr.replaceFirst('0x', ''), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  /// 检查字节列表是否包含子列表
  /// [rawData] 要检查的字节列表
  /// [checkBytes] 要查找的子字节列表
  /// [expectedCount] 可选参数，指定要匹配的次数
  bool containsSublist(
    Uint8List rawData,
    Uint8List checkBytes, [
    int? expectedCount,
  ]) {
    final (mainLen, subLen) = (rawData.length, checkBytes.length);

    if (subLen == 0 || mainLen < subLen || (expectedCount ?? 1) <= 0) {
      return false;
    }

    int count = 0;
    for (
      int i = 0;
      i <= mainLen - subLen &&
          (expectedCount == null || count <= expectedCount);
      i++
    ) {
      if (List.generate(
        subLen,
        (j) => rawData[i + j] == checkBytes[j],
      ).every((e) => e)) {
        if (expectedCount == null) return true;
        if (++count > expectedCount) return false;
      }
    }
    return expectedCount != null && count == expectedCount;
  }

  /// 查找子字节数组在主字节数组中的索引
  /// [rawData] 要检查的字节列表
  /// [checkBytes] 要查找的子字节列表
  /// [reverse] 是否反向查找，默认false
  int indexOfSubBytes(
    Uint8List rawData,
    Uint8List checkBytes, {
    bool reverse = false,
  }) {
    final int mainLen = rawData.length;
    final int subLen = checkBytes.length;
    if (subLen == 0 || subLen > mainLen) return -1;

    final int step = reverse ? -1 : 1;
    int start = reverse ? (mainLen - subLen) : 0;
    int end = reverse ? -1 : (mainLen - subLen + 1);

    for (int i = start; i != end; i += step) {
      bool match = true;
      for (int j = 0; j < subLen; j++) {
        if (rawData[i + j] != checkBytes[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  /// 将小端字节转换为整数
  int littleEndianToInt(List<int> bytes) {
    final reversed = bytes.reversed.toList();
    return reversed.fold(0, (acc, byte) => (acc << 8) | byte);
  }

  /// 将十六进制字符串按两个字符一组倒序分割
  String splitHexStringIntoReversedChunks(String input) {
    List<String> chunks = [];
    for (int i = input.length; i > 0; i -= 2) {
      int start = i - 2 >= 0 ? i - 2 : 0;
      chunks.add(input.substring(start, i));
    }
    return chunks.join('');
  }

  /// 将设备 ID 转换小端模式的十六进制字符串
  String convertDeviceIdToSpoof(String deviceId) {
    List<String> bytes = [
      for (int i = 0; i < deviceId.length; i += 2) deviceId.substring(i, i + 2),
    ];
    bytes = bytes.reversed.toList();
    List<String> formattedBytes = bytes.map((byte) => '0x$byte').toList();
    return formattedBytes.join(', ');
  }

  String getAsciiString(Uint8List bytes) {
    return String.fromCharCodes(bytes.where((b) => b >= 0x20 && b <= 0x7E));
  }

  /// 校验PCI路径是否正确
  /// pciPath 设备PCI路径
  /// 正确返回true,否则返回false
  /// 例如: macOS : PciRoot(0x0)/Pci(0x0,0x0)/Pci(0x0,0x0)
  ///      Windows: PCIROOT(0)#PCI(0000)#PCI(0000)
  bool checkPCIPath({String? pciPath}) {
    if (pciPath == null || pciPath.isEmpty) {
      return false;
    }
    // 定义正则表达式，匹配以 PciRoot(0x数字) 开头，后面可跟多个 /Pci(0x数字,0x数字) 的格式
    final RegExp pciPathRegexForMac = RegExp(
      r'^PciRoot\(0x(0|[1-9a-fA-F][0-9a-fA-F]*)\)(\/Pci\(0x(0|[1-9a-fA-F][0-9a-fA-F]*),0x(0|[1-9a-fA-F][0-9a-fA-F]*)\))*$',
    );
    // 定义正则表达式，匹配以 PCIROOT(数字)#PCI(数字)#PCI(数字) 的格式
    final RegExp pciPathRegexForWindows = RegExp(
      r'^PCIROOT\((0|[0-9a-fA-F]{1,2})\)(#PCI\((0x)?[0-9a-fA-F]{4}\))+$',
    );

    return pciPathRegexForMac.hasMatch(pciPath) ||
        pciPathRegexForWindows.hasMatch(pciPath);
  }

  /// 校验ACPI路径是否正确
  /// [acpiPath] 设备ACPI路径
  /// 例如: _SB.PCI0.LPCB.EC00
  bool checkACPIPath({String? acpiPath}) {
    if (acpiPath == null || acpiPath.isEmpty) {
      return false;
    }

    final RegExp acpiPathRegex = RegExp(r'^\\?_SB_?(?:\.[A-Z0-9_]{1,4})*$');
    return acpiPathRegex.hasMatch(acpiPath);
  }

  bool deepEquals(dynamic a, dynamic b) {
    if (a == b) return true;

    if (a is Map && b is Map) {
      if (a.length != b.length) return false;

      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!deepEquals(a[key], b[key])) return false;
      }
      return true;
    }

    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!deepEquals(a[i], b[i])) return false;
      }
      return true;
    }

    if (a is Set && b is Set) {
      if (a.length != b.length) return false;
      final listA = a.toList()..sort();
      final listB = b.toList()..sort();
      return deepEquals(listA, listB);
    }

    return false;
  }

  dynamic ensurePath(
    dynamic plistData,
    List<String>? pathList, [
    dynamic finalType = List,
  ]) {
    if (pathList == null || pathList.isEmpty) return;
    dynamic last = plistData;
    for (int i = 0; i < pathList.length; i++) {
      String path = pathList[i];
      if (last is Map<String, dynamic> && !last.containsKey(path)) {
        if (i >= pathList.length - 1) {
          last[path] = finalType == List
              ? []
              : finalType == Map
              ? <String, dynamic>{}
              : throw ArgumentError('Unsupported finalType: $finalType');
        } else {
          last[path] = <String, dynamic>{};
        }
      }
      if (last is Map<String, dynamic>) {
        last = last[path];
      } else if (last is List<dynamic>) {
        try {
          int index = int.parse(path.replaceFirst('0x', ''));
          last = last[index];
        } catch (e) {
          throw ArgumentError('Invalid index "$path" for List');
        }
      } else {
        throw ArgumentError('last should be either a Map or a List');
      }
    }
    return last;
  }
}
