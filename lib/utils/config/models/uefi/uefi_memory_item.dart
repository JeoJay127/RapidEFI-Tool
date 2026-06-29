class UefiMemoryItem {
  int address;
  String comment;
  bool enabled;
  int size;
  String type;

  UefiMemoryItem({
    this.address = 0,
    this.comment = '',
    this.enabled = false,
    this.size = 0,
    this.type = '',
  });
  UefiMemoryItem copyWith({
    int? address,
    String? comment,
    bool? enabled,
    int? size,
    String? type,
  }) {
    return UefiMemoryItem(
      address: address ?? this.address,
      comment: comment ?? this.comment,
      enabled: enabled ?? this.enabled,
      size: size ?? this.size,
      type: type ?? this.type,
    );
  }

  factory UefiMemoryItem.fromJson(Map<String, dynamic> json) {
    return UefiMemoryItem(
      address: json['Address'] as int? ?? 0,
      comment: json['Comment'] as String? ?? '',
      enabled: json['Enabled'] as bool? ?? false,
      size: json['Size'] as int? ?? 0,
      type: json['Type'] as String? ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'Address': address,
      'Comment': comment,
      'Enabled': enabled,
      'Size': size,
      'Type': type,
    };
  }
}
