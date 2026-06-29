typedef HardwareModelBuilder<T> = T Function(Map<String, dynamic> json);

class HardwareModelParsing {
  const HardwareModelParsing._();

  static Map<String, dynamic> map(Object? value) {
    if (value is! Map) return <String, dynamic>{};

    return value.map(
      (key, entryValue) => MapEntry(key.toString(), entryValue),
    );
  }

  static List<dynamic> list(Object? value) {
    if (value is! List) return const <dynamic>[];
    return value;
  }

  static String? string(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String stringValue(Object? value, {String fallback = ''}) {
    return string(value) ?? fallback;
  }

  static int? intValue(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final text = value.toString().trim();
    return int.tryParse(text) ?? double.tryParse(text)?.toInt();
  }

  static double? doubleValue(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  static bool boolValue(Object? value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value.toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return fallback;
  }

  static Map<String, T> objectMap<T>(
    Object? value,
    HardwareModelBuilder<T> builder,
  ) {
    return map(value).map(
      (key, entryValue) => MapEntry(key, builder(map(entryValue))),
    );
  }

  static List<T> objectList<T>(
    Object? value,
    HardwareModelBuilder<T> builder,
  ) {
    return list(value).map((entryValue) => builder(map(entryValue))).toList();
  }
}
