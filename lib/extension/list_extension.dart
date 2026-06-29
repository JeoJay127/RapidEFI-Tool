extension ListStringExtension<T> on List<T> {
  String get descriptionList => asMap()
      .entries
      .map((entry) => '${entry.key + 1}.${entry.value}')
      .join('\n');

  String get description =>
      asMap().entries.map((entry) => entry.value).join('\n');
}


