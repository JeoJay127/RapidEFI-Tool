class HistoryModel {
  String name;

  /// 文件名
  String fileName;

  int timestamp;

  ///文件路径
  String path;

  ///备注
  String note;

  HistoryModel({
    this.fileName = '',
    this.name = '',
    this.timestamp = 0,
    this.path = '',
    this.note = '',
  });

  factory HistoryModel.fromJson(Map<String, dynamic> map) {
    return HistoryModel(
      fileName: _stringValue(map['fileName']),
      path: _stringValue(map['path']),
      name: _stringValue(map['name']),
      timestamp: _intValue(map['timestamp']),
      note: _stringValue(map['note']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'fileName': fileName,
      'name': name,
      'timestamp': timestamp,
      'note': note,
    };
  }

  static String _stringValue(Object? value) {
    return value?.toString() ?? '';
  }

  static int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
