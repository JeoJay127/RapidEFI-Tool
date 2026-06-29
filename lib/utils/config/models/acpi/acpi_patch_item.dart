import 'dart:typed_data';

class AcpiPatchItem {
  String base;
  int baseSkip;
  String comment;
  int count;
  bool enabled;
  Uint8List? find;
  int limit;
  Uint8List? mask;
  Uint8List? oemTableId;
  Uint8List? replace;
  Uint8List? replaceMask;
  int skip;
  int tableLength;
  Uint8List? tableSignature;
  String note;
  AcpiPatchItem({
    this.base = '',
    this.baseSkip = 0,
    this.comment = '',
    this.count = 0,
    this.enabled = false,
    this.find,
    this.limit = 0,
    this.mask,
    this.oemTableId,
    this.replace,
    this.replaceMask,
    this.skip = 0,
    this.tableLength = 0,
    this.tableSignature,
    this.note = '',
  });
  AcpiPatchItem copyWith({
    String? base,
    int? baseSkip,
    String? comment,
    int? count,
    bool? enabled,
    Uint8List? find,
    int? limit,
    Uint8List? mask,
    Uint8List? oemTableId,
    Uint8List? replace,
    Uint8List? replaceMask,
    int? skip,
    int? tableLength,
    Uint8List? tableSignature,
    String? note,
  }) {
    return AcpiPatchItem(
      base: base ?? this.base,
      baseSkip: baseSkip ?? this.baseSkip,
      comment: comment ?? this.comment,
      count: count ?? this.count,
      enabled: enabled ?? this.enabled,
      find: find ?? this.find,
      limit: limit ?? this.limit,
      mask: mask ?? this.mask,
      oemTableId: oemTableId ?? this.oemTableId,
      replace: replace ?? this.replace,
      replaceMask: replaceMask ?? this.replaceMask,
      skip: skip ?? this.skip,
      tableLength: tableLength ?? this.tableLength,
      tableSignature: tableSignature ?? this.tableSignature,
      note: note ?? this.note,
    );
  }

  factory AcpiPatchItem.fromJson(Map<String, dynamic> json) {
    return AcpiPatchItem(
      base: json['Base'] as String? ?? '',
      baseSkip: json['BaseSkip'] as int? ?? 0,
      comment: json['Comment'] as String? ?? '',
      count: json['Count'] as int? ?? 0,
      enabled: json['Enabled'] as bool? ?? false,
      find: json['Find'] != null
          ? Uint8List.fromList(List<int>.from(json['Find']))
          : null,
      limit: json['Limit'] as int? ?? 0,
      mask: json['Mask'] != null
          ? Uint8List.fromList(List<int>.from(json['Mask']))
          : null,
      oemTableId: json['OemTableId'] != null
          ? Uint8List.fromList(List<int>.from(json['OemTableId']))
          : null,
      replace: json['Replace'] != null
          ? Uint8List.fromList(List<int>.from(json['Replace']))
          : null,
      replaceMask: json['ReplaceMask'] != null
          ? Uint8List.fromList(List<int>.from(json['ReplaceMask']))
          : null,
      skip: json['Skip'] as int? ?? 0,
      tableLength: json['TableLength'] as int? ?? 0,
      tableSignature: json['TableSignature'] != null
          ? Uint8List.fromList(List<int>.from(json['TableSignature']))
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'Base': base,
      'BaseSkip': baseSkip,
      'Comment': comment,
      'Count': count,
      'Enabled': enabled,
      'Find': find,
      'Limit': limit,
      'Mask': mask,
      'OemTableId': oemTableId,
      'Replace': replace,
      'ReplaceMask': replaceMask,
      'Skip': skip,
      'TableLength': tableLength,
      'TableSignature': tableSignature,
    };
  }
}
