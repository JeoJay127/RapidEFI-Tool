import 'dart:typed_data';
import 'package:path/path.dart' as path;

extension StringExtension on String? {
  String get nullSafe => this ?? '';
  String get lastPathComponent {
    return path.basename(nullSafe);
  }

  Uint8List toBytes() {
    // 移除所有空格（如果有）
    String cleanedHexString = nullSafe.replaceAll(' ', '');

    Uint8List result = Uint8List(cleanedHexString.length ~/ 2);

    for (int i = 0; i < cleanedHexString.length; i += 2) {
      String byteString = cleanedHexString.substring(i, i + 2);
      result[i ~/ 2] = int.parse(byteString, radix: 16);
    }

    return result;
  }

  bool containsAny(List<String> list) {
    if (list.isEmpty) return false;
    return list.any((item) => nullSafe.contains(item));
  }
}
