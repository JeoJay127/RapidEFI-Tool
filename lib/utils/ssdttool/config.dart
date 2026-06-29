//  config.dart
//  Created by JeoJay127
//
/// ACPI 匹配模式
enum ACPIMatchMode {
  leastStrict, // 最宽松的模式
  lengthOnly, //  仅长度匹配
  tableIDsAndLength, // 表 ID 和长度
  tableIDsAndLengthAndNormalizeHeaders, // 表 ID 和长度 + 标准化头部
}

/// ACPI 匹配模式扩展
extension ACPIMathModeExtension on ACPIMatchMode {
  String get value => ["最宽松", "仅长度", "表ID和长度,禁用标准化头部", "表ID和长度,启用标准化头部"][index];
}

enum PlistType { openCore, clover, unknown }

extension PlistTypeExtension on PlistType {
  String get value => ['OpenCore', 'Clover', '未知'][index];
}

final osiStrings = {
  "Windows 2000": "Windows 2000",
  "Windows XP": "Windows 2001",
  "Windows XP SP1": "Windows 2001 SP1",
  "Windows Server 2003": "Windows 2001.1",
  "Windows XP SP2": "Windows 2001 SP2",
  "Windows Server 2003 SP1": "Windows 2001.1 SP1",
  "Windows Vista": "Windows 2006",
  "Windows Vista SP1": "Windows 2006 SP1",
  "Windows Server 2008": "Windows 2006.1",
  "Windows 7, Win Server 2008 R2": "Windows 2009",
  "Windows 8, Win Server 2012": "Windows 2012",
  "Windows 8.1": "Windows 2013",
  "Windows 10": "Windows 2015",
  "Windows 10, version 1607": "Windows 2016",
  "Windows 10, version 1703": "Windows 2017",
  "Windows 10, version 1709": "Windows 2017.2",
  "Windows 10, version 1803": "Windows 2018",
  "Windows 10, version 1809": "Windows 2018.2",
  "Windows 10, version 1903": "Windows 2019",
  "Windows 10, version 2004": "Windows 2020",
  "Windows 11": "Windows 2021",
  "Windows 11, version 22H2": "Windows 2022",
};

// ignore: non_constant_identifier_names
final PNLFUIDs = [
  {
    "UID": 14,
    "Platform": "Intel第1代Arrandale,第2代Sandy Bridge,第3代Ivy Bridge",
    "PWMMax": "0x0710",
  },
  {"UID": 15, "Platform": "Intel第4代Haswell,第5代Broadwell", "PWMMax": "0x0AD9"},
  {
    "UID": 16,
    "Platform": "Intel第6代Skylake,第7代Kaby Lake, 某些第4代Haswell",
    "PWMMax": "0x056C",
  },
  {"UID": 17, "Platform": "自定义亮度,通常用于一些非标准设备或特殊需求设置", "PWMMax": "0x07A1"},
  {"UID": 18, "Platform": "自定义亮度,通常用于一些非标准设备或特殊需求设置", "PWMMax": "0x1499"},
  {
    "UID": 19,
    "Platform": "Intel第8代CoffeeLake ~ 10代,以及AMD笔记本",
    "PWMMax": "0xFFFF",
  },
  {
    "UID": 99,
    "Platform": "其他（需要自定义 applbkl-name / applbkl-data 设备属性）,可能不受支持",
    "PWMMax": "",
  },
];

const Map<String, String> defaultProps = {
  'kUSBSleepPowerSupply': '0x13EC',
  'kUSBSleepPortCurrentLimit': '0x0834',
  'kUSBWakePowerSupply': '0x13EC',
  'kUSBWakePortCurrentLimit': '0x0834',
};

/// ACPI 配置
class AcpiConfig {
  final bool useLocaliAsl;
  final bool deleteDsl;
  final bool useLeagcyiAsl;
  final bool force;
  final bool overwriteEFI;
  final ACPIMatchMode acpiMatchMode;
  final String? outputDirectory;
  final String? acpiDirectory;

  const AcpiConfig({
    this.useLocaliAsl = true,
    this.deleteDsl = true,
    this.useLeagcyiAsl = false,
    this.force = true,
    this.overwriteEFI = true,
    this.acpiMatchMode = ACPIMatchMode.leastStrict,
    this.outputDirectory,
    this.acpiDirectory,
  });

  AcpiConfig copyWith({
    bool? useLocaliAsl,
    bool? deleteDsl,
    bool? useLeagcyiAsl,
    bool? force,
    bool? overwriteEFI,
    ACPIMatchMode? acpiMatchMode,
    String? outputDirectory,
    String? acpiDirectory,
  }) => AcpiConfig(
    useLocaliAsl: useLocaliAsl ?? this.useLocaliAsl,
    deleteDsl: deleteDsl ?? this.deleteDsl,
    useLeagcyiAsl: useLeagcyiAsl ?? this.useLeagcyiAsl,
    force: force ?? this.force,
    overwriteEFI: overwriteEFI ?? this.overwriteEFI,
    acpiMatchMode: acpiMatchMode ?? this.acpiMatchMode,
    outputDirectory: outputDirectory ?? this.outputDirectory,
    acpiDirectory: acpiDirectory ?? this.acpiDirectory,
  );
}
