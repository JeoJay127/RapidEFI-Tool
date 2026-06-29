class BooterMmioWhitelistItem {
  String comment;
  bool enabled;
  int address;
  BooterMmioWhitelistItem(
      {this.comment = '', this.enabled = false, this.address = 0});

  factory BooterMmioWhitelistItem.fromJson(Map<String, dynamic> json) {
    return BooterMmioWhitelistItem(
      comment: json['Comment'],
      enabled: json['Enabled'],
      address: json['Address'],
    );
  }
  BooterMmioWhitelistItem copyWith({
    String? comment,
    bool? enabled,
    int? address,
  }) {
    return BooterMmioWhitelistItem(
      comment: comment ?? this.comment,
      enabled: enabled ?? this.enabled,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Comment': comment,
      'Enabled': enabled,
      'Address': address,
    };
  }
}
