import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis_models.dart';

class HardwareConfigKextResolver {
  const HardwareConfigKextResolver();

  List<KernelKext> networkKexts(
    NetworkEntryAnalysis entry, {
    required int darwinMajorVersion,
  }) {
    if (entry.requiresForceAquantiaEthernet) return const [];

    if (_isAirportItlwm(entry.kext)) {
      return [_airportItlwmForDarwinMajor(darwinMajorVersion)];
    }

    if (_matchesBundlePath(entry.kext, ConfigKernel.AirportBrcmFixup)) {
      return _brcmWifiKexts(entry.deviceId);
    }

    if (_isAirPortAtheros40(entry.kext)) {
      return [_atherosWifiKext(entry)];
    }

    return _kextsForListedNames(entry.kext);
  }

  List<KernelKext> sdCardKexts(SdCardEntryAnalysis entry) {
    if (entry.readerName == 'Realtek') {
      return ConfigKextGroups.realtekCardReader.kexts;
    }
    if (entry.readerName.isNotEmpty) return [ConfigKernel.EmeraldSDHC];
    return const [];
  }

  List<KernelKext> _kextsForListedNames(String names) {
    final result = <KernelKext>[];
    final seen = <String>{};
    for (final token in names.split('/')) {
      final kext = _kextFromBundlePath(token);
      if (kext != null && seen.add(kext.bundlePath)) {
        result.add(kext);
      }
    }
    return result;
  }

  KernelKext? _kextFromBundlePath(String bundlePath) {
    final normalized = bundlePath.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final kext in ConfigKernel.sortKernelKexts) {
      if (kext.bundlePath.toLowerCase() == normalized) return kext;
    }
    return null;
  }

  bool _matchesBundlePath(String value, KernelKext kext) {
    return value.trim().toLowerCase() == kext.bundlePath.toLowerCase();
  }

  bool _isAirportItlwm(String value) {
    return value.trim().toLowerCase() == 'airportitlwm.kext';
  }

  bool _isAirPortAtheros40(String value) {
    return value.trim().toLowerCase() == 'airportatheros40.kext';
  }

  KernelKext _airportItlwmForDarwinMajor(int darwinMajorVersion) {
    return switch (darwinMajorVersion) {
      >= 24 => ConfigKernel.AirportItlwm_Sequoia,
      23 => ConfigKernel.AirportItlwm_Sonoma_14_4,
      22 => ConfigKernel.AirportItlwm_Ventura,
      21 => ConfigKernel.AirportItlwm_Monterey,
      20 => ConfigKernel.AirportItlwm_BigSur,
      19 => ConfigKernel.AirportItlwm_Catalina,
      18 => ConfigKernel.AirportItlwm_Mojave,
      _ => ConfigKernel.AirportItlwm_HighSierra,
    };
  }

  List<KernelKext> _brcmWifiKexts(String deviceId) {
    final id = deviceId.trim().toUpperCase();
    if (id == '14E4-4331') {
      return ConfigKextGroups.brcm4331.kexts;
    }
    if (id == '14E4-4324') {
      return ConfigKextGroups.brcm43224.kexts;
    }
    if (const {
      '14E4-43A0',
      '14E4-43A3',
      '14E4-43B1',
      '14E4-43B2',
      '14E4-43BA',
    }.contains(id)) {
      return ConfigKextGroups.brcm94360.kexts;
    }
    return ConfigKextGroups.brcm943xx.kexts;
  }

  KernelKext _atherosWifiKext(NetworkEntryAnalysis entry) {
    final text = '${entry.deviceId} ${entry.name}'.toUpperCase();
    if (text.contains('9285') || text.contains('168C-002B')) {
      return ConfigKernel.AirPortAtheros40_9285;
    }
    if (text.contains('9485') ||
        text.contains('168C-0032') ||
        text.contains('168C-0037')) {
      return ConfigKernel.AirPortAtheros40_9485;
    }
    if (text.contains('9462') || text.contains('168C-0034')) {
      return ConfigKernel.AirPortAtheros40_9462;
    }
    if (text.contains('9463')) {
      return ConfigKernel.AirPortAtheros40_9463;
    }
    if (text.contains('9565') || text.contains('168C-0036')) {
      return ConfigKernel.AirPortAtheros40_9565;
    }
    return ConfigKernel.AirPortAtheros40_9380;
  }
}
