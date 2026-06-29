class NvramAddItem {
  //键
  String? key;

  String? dataType;
  //值
  String? value;
  //备注
  String? comment;

  NvramAddItem(
      {required this.key,
      required this.dataType,
      required this.value,
      this.comment = ''});

  NvramAddItem copyWith({
    String? key,
    String? dataType,
    String? value,
    String? comment,
  }) {
    return NvramAddItem(
      key: key ?? this.key,
      dataType: dataType ?? this.dataType,
      value: value ?? this.value,
      comment: comment ?? this.comment,
    );
  }

  factory NvramAddItem.fromJson(Map<String, dynamic> json) {
    return NvramAddItem(
      key: json['key'] ?? '',
      dataType: json['dataType'] ?? '',
      value: json['value'] ?? '',
      comment: json['comment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'dataType': dataType,
      'value': value,
      'comment': comment
    };
  }
}
