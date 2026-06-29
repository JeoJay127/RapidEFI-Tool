class UefiDriversItem {
  String arguments;
  String comment;
  bool enabled;
  bool loadEarly;
  String path;

  UefiDriversItem({
    this.arguments = '',
    this.comment = '',
    this.enabled = true,
    this.loadEarly = false,
    this.path = '',
  });
  UefiDriversItem copyWith({
    String? arguments,
    String? comment,
    bool? enabled,
    bool? loadEarly,
    String? path,
  }) {
    return UefiDriversItem(
      arguments: arguments ?? this.arguments,
      comment: comment ?? this.comment,
      enabled: enabled ?? this.enabled,
      loadEarly: loadEarly ?? this.loadEarly,
      path: path ?? this.path,
    );
  }

  factory UefiDriversItem.fromJson(Map<String, dynamic> json) {
    return UefiDriversItem(
      arguments: json['Arguments'] as String? ?? '',
      comment: json['Comment'] as String? ?? '',
      enabled: json['Enabled'] as bool? ?? false,
      loadEarly: json['LoadEarly'] as bool? ?? false,
      path: json['Path'] as String? ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'Arguments': arguments,
      'Comment': comment,
      'Enabled': enabled,
      'LoadEarly': loadEarly,
      'Path': path,
    };
  }
}
