import 'dart:typed_data';

class BooterPatchItem {
  String arch;
  String comment;
  int count;
  bool enabled;
  Uint8List? find;
  Uint8List? mask;
  Uint8List? replaceMask;
  String identifier;
  int limit;
  Uint8List? replace;
  int skip;

  BooterPatchItem({
    this.arch = '',
    this.comment = '',
    this.count = 0,
    this.enabled = false,
    this.mask,
    this.replaceMask,
    this.find,
    this.identifier = '',
    this.limit = 0,
    this.replace,
    this.skip = 0,
  });
  BooterPatchItem copyWith({
    String? arch,
    String? comment,
    int? count,
    bool? enabled,
    Uint8List? find,
    Uint8List? mask,
    Uint8List? replaceMask,
    String? identifier,
    int? limit,
    Uint8List? replace,
    int? skip,
  }) {
    return BooterPatchItem(
      arch: arch ?? this.arch,
      comment: comment ?? this.comment,
      count: count ?? this.count,
      enabled: enabled ?? this.enabled,
      find: find ?? this.find,
      mask: mask ?? this.mask,
      replaceMask: replaceMask ?? this.replaceMask,
      identifier: identifier ?? this.identifier,
      limit: limit ?? this.limit,
      replace: replace ?? this.replace,
      skip: skip ?? this.skip,
    );
  }

  factory BooterPatchItem.fromJson(Map<String, dynamic> json) {
    return BooterPatchItem(
      arch: json['Arch'],
      comment: json['Comment'],
      count: json['Count'],
      enabled: json['Enabled'],
      mask: json['Mask'] != null
          ? Uint8List.fromList(List<int>.from(json['Mask']))
          : null,
      replaceMask: json['ReplaceMask'] != null
          ? Uint8List.fromList(List<int>.from(json['ReplaceMask']))
          : null,
      find: json['Find'] != null
          ? Uint8List.fromList(List<int>.from(json['Find']))
          : null,
      identifier: json['Identifier'],
      limit: json['Limit'],
      replace: json['Replace'] != null
          ? Uint8List.fromList(List<int>.from(json['Replace']))
          : null,
      skip: json['Skip'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Arch': arch,
      'Comment': comment,
      'Count': count,
      'Enabled': enabled,
      'Mask': mask,
      'ReplaceMask': replaceMask,
      'Find': find,
      'Identifier': identifier,
      'Limit': limit,
      'Replace': replace,
      'Skip': skip,
    };
  }
}
