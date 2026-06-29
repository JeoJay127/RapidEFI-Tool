import 'dart:typed_data';

class AcpiDeleteItem {
  bool all;
  String comment;
  bool enabled;
  Uint8List? oemTableId;
  int tableLength;
  Uint8List? tableSignature;

  AcpiDeleteItem({
    this.all = false,
    this.comment = '',
    this.enabled = false,
    this.oemTableId,
    this.tableLength = 0,
    this.tableSignature,
  });
  AcpiDeleteItem copyWith({
    bool? all,
    String? comment,
    bool? enabled,
    Uint8List? oemTableId,
    int? tableLength,
    Uint8List? tableSignature,
  }) {
    return AcpiDeleteItem(
      all: all ?? this.all,
      comment: comment ?? this.comment,
      enabled: enabled ?? this.enabled,
      oemTableId: oemTableId ?? this.oemTableId,
      tableLength: tableLength ?? this.tableLength,
      tableSignature: tableSignature ?? this.tableSignature,
    );
  }

  factory AcpiDeleteItem.fromJson(Map<String, dynamic> json) {
    return AcpiDeleteItem(
      all: json['All'] as bool? ?? false,
      comment: json['Comment'] as String? ?? '',
      enabled: json['Enabled'] as bool? ?? false,
      oemTableId: json['OemTableId'] != null
          ? Uint8List.fromList(List<int>.from(json['OemTableId']))
          : null,
      tableLength: json['TableLength'] as int? ?? 0,
      tableSignature: json['TableSignature'] != null
          ? Uint8List.fromList(List<int>.from(json['TableSignature']))
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'All': all,
      'Comment': comment,
      'Enabled': enabled,
      'OemTableId': oemTableId,
      'TableLength': tableLength,
      'TableSignature': tableSignature,
    };
  }
}
