class NvramDeleteItem {
  //值
  String? value;
  NvramDeleteItem({this.value});
  NvramDeleteItem copyWith({
    String? value,
  }) {
    return NvramDeleteItem(
      value: value ?? this.value,
    );
  }

  factory NvramDeleteItem.fromJson(Map<String, dynamic> json) {
    return NvramDeleteItem(
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
    };
  }
}
