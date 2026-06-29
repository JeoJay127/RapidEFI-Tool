import '../../models/enums/enum_meta.dart';
import '../../models/enums/enum_codec.dart';

enum MotherboardVendor {
  intel,
  amd,
}

enum SpecialMotherboard {
  // 通用
  none(
    vendor: MotherboardVendor.intel,
    text: EnumText(
      title: '',
    ),
  ),

  amdNormal(
    vendor: MotherboardVendor.amd,
    text: EnumText(
      title: '常规主板',
    ),
  ),
  amdB550A520(
    vendor: MotherboardVendor.amd,
    text: EnumText(
      title: 'B850,B650,B550和A520主板,550系列芯片组笔记本',
    ),
  ),
  amdTrx40(
    vendor: MotherboardVendor.amd,
    text: EnumText(
      title: 'TRx40主板',
    ),
  ),
  amdX570(
    vendor: MotherboardVendor.amd,
    text: EnumText(
      title: 'X570主板',
    ),
  ),
  amdX470B450(
    vendor: MotherboardVendor.amd,
    text: EnumText(
      title: 'X470或B450主板2020年底或更新BIOS',
    ),
  ),

  intelS6(
    vendor: MotherboardVendor.intel,
    text: EnumText(
      title: '6系芯片组',
      description: 'Intel 3代CPU,6系芯片组(例如:H61,HM65)混合时勾选',
    ),
  ),
  intelS7(
    vendor: MotherboardVendor.intel,
    text: EnumText(
      title: '7系芯片组',
      description: 'Intel 2代CPU,7系芯片组(例如:B75,HM76)混合时勾选',
    ),
  ),
  intelOem(
    vendor: MotherboardVendor.intel,
    text: EnumText(
      title: 'H110,B150,B250,Q270等',
      description: '部分OEM主板存在USB所有权释放问题:EHCI Hand-off失效',
    ),
  ),
  intelZ390(
    vendor: MotherboardVendor.intel,
    text: EnumText(
      title: 'Z390',
    ),
  ),
  intelB460(
    vendor: MotherboardVendor.intel,
    text: EnumText(
      title: 'B460',
    ),
  ),
  intelZ490(
    vendor: MotherboardVendor.intel,
    text: EnumText(
      title: 'Z490等2020年更新BIOS',
    ),
  ),
  intelZ590(
    vendor: MotherboardVendor.intel,
    text: EnumText(
      title: 'Z590',
    ),
  );

  const SpecialMotherboard({
    required this.vendor,
    required this.text,
  });

  final MotherboardVendor vendor;
  final EnumText text;

  String get value {
    if (text.description.isEmpty) {
      return text.title;
    }
    return '${text.title}(${text.description})';
  }

  static List<SpecialMotherboard> byVendor(MotherboardVendor vendor) {
    return values.where((item) => item.vendor == vendor).toList();
  }

  static List<SpecialMotherboard> get intelValues {
    return byVendor(MotherboardVendor.intel);
  }

  static List<SpecialMotherboard> get amdValues {
    return byVendor(MotherboardVendor.amd);
  }

  static SpecialMotherboard fromJson(Object? raw) {
    return EnumCodec.decode(
      raw,
      values,
      fallback: SpecialMotherboard.none,
      ignoreCase: true,
      aliases: {
        'AMDMLB.nomal': SpecialMotherboard.amdNormal,
        'AMDMLB.normal': SpecialMotherboard.amdNormal,
        'nomal': SpecialMotherboard.amdNormal,
        'normal': SpecialMotherboard.amdNormal,
        '常规主板': SpecialMotherboard.amdNormal,
        'AMDMLB.b550AndA520': SpecialMotherboard.amdB550A520,
        'b550AndA520': SpecialMotherboard.amdB550A520,
        'B850,B650,B550和A520主板,550系列芯片组笔记本': SpecialMotherboard.amdB550A520,
        'AMDMLB.trx40': SpecialMotherboard.amdTrx40,
        'trx40': SpecialMotherboard.amdTrx40,
        'TRx40主板': SpecialMotherboard.amdTrx40,
        'AMDMLB.x570': SpecialMotherboard.amdX570,
        'x570': SpecialMotherboard.amdX570,
        'X570主板': SpecialMotherboard.amdX570,
        'AMDMLB.x470': SpecialMotherboard.amdX470B450,
        'x470': SpecialMotherboard.amdX470B450,
        'X470或B450主板2020年底或更新BIOS': SpecialMotherboard.amdX470B450,
        'SpecialMainBoard.nil': SpecialMotherboard.none,
        'nil': SpecialMotherboard.none,
        '': SpecialMotherboard.none,
        'SpecialMainBoard.S6': SpecialMotherboard.intelS6,
        'S6': SpecialMotherboard.intelS6,
        '6系芯片组(Intel 3代CPU,6系芯片组(例如:H61,HM65)混合时勾选)':
            SpecialMotherboard.intelS6,
        'SpecialMainBoard.S7': SpecialMotherboard.intelS7,
        'S7': SpecialMotherboard.intelS7,
        '7系芯片组(Intel 2代CPU,7系芯片组(例如:B75,HM76)混合时勾选)':
            SpecialMotherboard.intelS7,
        'SpecialMainBoard.OEM': SpecialMotherboard.intelOem,
        'OEM': SpecialMotherboard.intelOem,
        'H110,B150,B250,Q270等(部分OEM主板存在USB所有权释放问题:EHCI Hand-off失效)':
            SpecialMotherboard.intelOem,
        'SpecialMainBoard.Z390': SpecialMotherboard.intelZ390,
        'Z390': SpecialMotherboard.intelZ390,
        'SpecialMainBoard.B460': SpecialMotherboard.intelB460,
        'B460': SpecialMotherboard.intelB460,
        'SpecialMainBoard.Z490': SpecialMotherboard.intelZ490,
        'Z490': SpecialMotherboard.intelZ490,
        'Z490等2020年更新BIOS': SpecialMotherboard.intelZ490,
        'SpecialMainBoard.Z590': SpecialMotherboard.intelZ590,
        'Z590': SpecialMotherboard.intelZ590,
      },
    );
  }

  String toJson() => EnumCodec.encode(this);
}
