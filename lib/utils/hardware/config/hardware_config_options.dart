import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi_generic.dart';

class HardwareConfigOptions {
  const HardwareConfigOptions({
    this.cpuType,
    this.platformType,
    this.platformCode,
    this.macOSVersion,
    this.alcLayoutId,
    this.enableNpci,
    this.platformInfoGeneric,
  });

  final CpuType? cpuType;
  final PlatformType? platformType;
  final String? platformCode;
  final String? macOSVersion;
  final int? alcLayoutId;
  final bool? enableNpci;
  final PlatformInfoGeneric? platformInfoGeneric;
}
