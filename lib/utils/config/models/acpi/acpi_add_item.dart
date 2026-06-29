class AcpiAddItem {
  String comment;
  bool enabled;
  String path;
  String note;

  AcpiAddItem(
      {this.comment = '',
      this.enabled = false,
      this.path = '',
      this.note = ''});
  AcpiAddItem copyWith({
    String? comment,
    bool? enabled,
    String? path,
    String? note,
  }) {
    return AcpiAddItem(
        comment: comment ?? this.comment,
        enabled: enabled ?? this.enabled,
        path: path ?? this.path,
        note: note ?? this.note);
  }

  factory AcpiAddItem.fromJson(Map<String, dynamic> json) {
    return AcpiAddItem(
      comment: json['Comment'] as String? ?? '',
      enabled: json['Enabled'] as bool? ?? false,
      path: json['Path'] as String? ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'Comment': comment,
      'Enabled': enabled,
      'Path': path,
    };
  }
}
