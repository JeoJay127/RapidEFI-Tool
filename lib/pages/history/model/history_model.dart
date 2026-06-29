class HistoryModel {
  String name;

  /// 文件名
  String fileName;

  int timestamp;

  ///文件路径
  String path;

  ///备注
  String note;


  HistoryModel(
      {this.fileName = '',
      this.name = '',
      this.timestamp = 0,
      this.path = '',
      this.note = ''});

  factory HistoryModel.fromJson(Map<String, dynamic> map) {
    return HistoryModel(
      fileName: map['fileName'],
      path: map['path'],
      name: map['name'],
      timestamp: map['timestamp'],
      note: map['note'],
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
}
