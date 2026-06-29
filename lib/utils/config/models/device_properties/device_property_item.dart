class DevicePropertyItem {
  //键
  String? key;

  String? dataType;
  //值
  String? value;
  //备注
  String? comment;

  ///核显参数是否用于输出显示
  bool display;

  DevicePropertyItem({
    required this.key,
    required this.dataType,
    required this.value,
    this.comment = '',
    this.display = true,
  });
  DevicePropertyItem copyWith(
      {String? key,
      String? dataType,
      String? value,
      String? comment,
      bool? display}) {
    return DevicePropertyItem(
      key: key ?? this.key,
      dataType: dataType ?? this.dataType,
      value: value ?? this.value,
      comment: comment ?? this.comment,
      display: display ?? this.display,
    );
  }

  factory DevicePropertyItem.fromJson(Map<String, dynamic> json) {
    return DevicePropertyItem(
      key: json['key'] ?? '',
      dataType: json['dataType'] ?? '',
      value: json['value'] ?? "",
      comment: json['comment'] ?? '',
      display: json['display'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'dataType': dataType,
      'value': value,
      'comment': comment,
      'display': display
    };
  }
}
