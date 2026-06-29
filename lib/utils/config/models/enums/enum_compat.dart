class JsonCompat {
  const JsonCompat._();
  static Object? pickEnumRaw(
    Map<String, dynamic> json,
    List<String> keys, {
    Set<String> nilValues = const {
      '',
      'nil',
      'none',
      'null',
    },
  }) {
    for (final key in keys) {
      final raw = json[key];
      if (raw == null) continue;

      final text = raw.toString().trim();
      if (text.isEmpty) continue;

      final valueName = text.contains('.') ? text.split('.').last : text;
      final normalized = valueName.toLowerCase();

      if (nilValues.contains(normalized)) {
        continue;
      }

      return raw;
    }

    return null;
  }
}
