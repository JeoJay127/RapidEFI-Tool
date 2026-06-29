import 'package:rapidefi/extension/string_extension.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi_generic.dart';

class ConfigPi {
  static PlatformInfoGeneric commonPlatformInfoGeneric = PlatformInfoGeneric(
    spoofVendor: false,
    rom: '666666666666'.toBytes(),
  );

  static PlatformInfo commonPlatformInfo = PlatformInfo(
      updateSMBIOSMode: 'Custom', generic: commonPlatformInfoGeneric);
}
