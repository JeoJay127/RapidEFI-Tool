import 'package:rapidefi/utils/config/models/enums/config_enums.dart';

enum SsdtBuildMode { custom, original }

enum SsdtItemGroup { basic, recommend, optional }

class SsdtItem {
  const SsdtItem({
    required this.name,
    required this.remark,
    required this.group,
    this.note,
    this.extra,
  });

  final String name;
  final String remark;
  final SsdtItemGroup group;
  final String? note;
  final dynamic extra;

  bool get isBasic => group == SsdtItemGroup.basic;
  bool get isRecommend => group == SsdtItemGroup.recommend;
  bool get isOptional => group == SsdtItemGroup.optional;

  String get key => '$name:${extra ?? ''}';

  Map<String, dynamic> toAction() => {
        'name': name,
        'remark': remark,
        'note': note,
        'extra': extra,
        'isBasic': isBasic,
        'isRecommend': isRecommend,
        'isOptional': isOptional,
        'prebuilt': false,
      };
}

class SsdtSelection {
  const SsdtSelection({
    required this.cpuType,
    required this.platformType,
    required this.platformCode,
    required this.items,
  });

  final CpuType cpuType;
  final PlatformType platformType;
  final String platformCode;
  final List<SsdtItem> items;

  List<Map<String, dynamic>> get actions =>
      items.map((item) => item.toAction()).toList();

  bool get isEmpty => items.isEmpty;
}
