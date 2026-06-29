import 'dart:typed_data';

class KernelPatchItem {
  String arch;
  String base;
  String comment;
  int count;
  bool enabled;
  Uint8List? find;
  String identifier;
  int limit;
  Uint8List? mask;
  String maxKernel;
  String minKernel;
  Uint8List? replace;
  Uint8List? replaceMask;
  int skip;
  String note;

  KernelPatchItem({
    this.arch = '',
    this.base = '',
    this.comment = '',
    this.count = 0,
    this.enabled = false,
    this.find,
    this.identifier = '',
    this.limit = 0,
    this.mask,
    this.maxKernel = '',
    this.minKernel = '',
    this.replace,
    this.replaceMask,
    this.skip = 0,
    this.note = '',
  });
  KernelPatchItem copyWith({
    String? arch,
    String? base,
    String? comment,
    int? count,
    bool? enabled,
    Uint8List? find,
    String? identifier,
    int? limit,
    Uint8List? mask,
    String? maxKernel,
    String? minKernel,
    Uint8List? replace,
    Uint8List? replaceMask,
    int? skip,
    String? note,
  }) {
    return KernelPatchItem(
      arch: arch ?? this.arch,
      base: base ?? this.base,
      comment: comment ?? this.comment,
      count: count ?? this.count,
      enabled: enabled ?? this.enabled,
      find: find ?? this.find,
      identifier: identifier ?? this.identifier,
      limit: limit ?? this.limit,
      mask: mask ?? this.mask,
      maxKernel: maxKernel ?? this.maxKernel,
      minKernel: minKernel ?? this.minKernel,
      replace: replace ?? this.replace,
      replaceMask: replaceMask ?? this.replaceMask,
      skip: skip ?? this.skip,
      note: note ?? this.note,
    );
  }

  factory KernelPatchItem.fromJson(Map<String, dynamic> json) {
    return KernelPatchItem(
      arch: json['Arch'] ?? '',
      base: json['Base'] ?? '',
      comment: json['Comment'] ?? '',
      count: json['Count'] ?? 0,
      enabled: json['Enabled'] ?? false,
      find: json['Find'] != null
          ? Uint8List.fromList(List<int>.from(json['Find']))
          : null,
      identifier: json['Identifier'] ?? '',
      limit: json['Limit'] ?? 0,
      mask: json['Mask'] != null
          ? Uint8List.fromList(List<int>.from(json['Mask']))
          : null,
      maxKernel: json['MaxKernel'] ?? '',
      minKernel: json['MinKernel'] ?? '',
      replace: json['Replace'] != null
          ? Uint8List.fromList(List<int>.from(json['Replace']))
          : null,
      replaceMask: json['ReplaceMask'] != null
          ? Uint8List.fromList(List<int>.from(json['ReplaceMask']))
          : null,
      skip: json['Skip'] ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'Arch': arch,
      'Base': base,
      'Comment': comment,
      'Count': count,
      'Enabled': enabled,
      'Find': find,
      'Identifier': identifier,
      'Limit': limit,
      'Mask': mask,
      'MaxKernel': maxKernel,
      'MinKernel': minKernel,
      'Replace': replace,
      'ReplaceMask': replaceMask,
      'Skip': skip,
    };
  }
}
