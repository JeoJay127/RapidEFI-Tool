class EfiDriverOption {
  final String id;
  final String title;
  final String path;
  final String category;
  final String description;
  final String tip;
  final List<String> legacyAliases;

  const EfiDriverOption({
    required this.id,
    required this.title,
    required this.path,
    required this.category,
    this.description = '',
    this.tip = '',
    this.legacyAliases = const [],
  });

  factory EfiDriverOption.fromJson(Map<String, dynamic> json) {
    return EfiDriverOption(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      path: json['path'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tip: json['tip'] as String? ?? '',
      legacyAliases: (json['legacyAliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
