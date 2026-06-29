class BluetoothNvramOption {
  final String id;
  final String title;
  final String key;
  final String dataType;
  final String value;
  final String description;
  final String comment;
  final List<String> legacyAliases;

  const BluetoothNvramOption({
    required this.id,
    required this.title,
    required this.key,
    required this.dataType,
    required this.value,
    this.description = '',
    this.comment = '',
    this.legacyAliases = const [],
  });

  factory BluetoothNvramOption.fromJson(Map<String, dynamic> json) {
    return BluetoothNvramOption(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      key: json['key'] as String? ?? '',
      dataType: json['dataType'] as String? ?? '',
      value: json['value'] as String? ?? '',
      description: json['description'] as String? ?? '',
      comment:
          json['comment'] as String? ?? json['description'] as String? ?? '',
      legacyAliases: (json['legacyAliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
