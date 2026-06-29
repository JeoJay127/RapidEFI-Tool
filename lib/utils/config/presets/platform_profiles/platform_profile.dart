import 'package:rapidefi/utils/config/models/device_properties/igpu_model.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi_generic.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';

class PlatformEntry {
  final String label;
  final List<PlatformInfoGeneric> smbiosOptions;
  final List<List<IgpuPropertyModel>>? igpuModes;

  const PlatformEntry({
    required this.label,
    required this.smbiosOptions,
    this.igpuModes,
  });
}

class PlatformModel {
  final CpuType cpuType;
  final PlatformType platformType;
  final Map<String, PlatformEntry> platforms;

  PlatformModel({
    required this.cpuType,
    required this.platformType,
    required this.platforms,
  });

  List<String> get platformCodes => platforms.keys.toList();

  int indexOfCode(String platformCode) {
    final index = platformCodes.indexOf(platformCode);
    return index >= 0 ? index : 0;
  }

  String codeAt(int index) {
    final codes = platformCodes;
    if (index >= 0 && index < codes.length) {
      return codes[index];
    }
    return codes.isNotEmpty ? codes.first : '';
  }

  Map<String, dynamic> toJson() {
    return {
      'cpuType': cpuType.toString(),
      'platformType': platformType.toString(),
      'platformCodes': platformCodes,
    };
  }
}
