import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/models/booter/booter.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/amd_config_base.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_config_repository.dart';
import 'package:rapidefi/utils/config/presets/sections/config_booter.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/presets/sections/config_platform_info.dart';
import 'package:rapidefi/utils/config/presets/sections/config_uefi.dart';

class ConfigsAmdDesktop with AmdConfigBase {
  const ConfigsAmdDesktop._();

  static Map<String, ConfigModelFactory> get factories {
    final codes = PlatformCodeRegistry.codes(
      CpuType.amd,
      PlatformType.desktop,
    );

    return {
      codes[0]: createAmdDesktopLegacy,
      codes[1]: createAmdDesktopRyzen,
    };
  }

  static ConfigModel createAmdDesktopLegacy() {
    final model = ConfigModel()
      ..cpuType = CpuType.amd
      ..platformType = PlatformType.desktop
      ..misc = AmdConfigBase.commonMisc()
      ..nvram = AmdConfigBase.commonNvram()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(
            enabled: true,
            path: 'SSDT-EC-USBX-DESKTOP.aml',
          ),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_amd_desktop_legacy.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_amd_desktop_legacy
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_amd_desktop_legacy.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_amd.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi,
        ConfigNvram.ipc_control_port_options,
      }
      ..csrsetting = CsrSetting.partialDisabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith()
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonDesktopLegacyUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
      )
      ..kernel.kernelKexts.addAll([
        ConfigKernel.AMFIPass.copyWith(),
        ConfigKernel.GenericUSBXHCI.copyWith(),
      ]);

    AmdConfigBase.applyAmdDefaults(model, core: '4');

    return model;
  }

  static ConfigModel createAmdDesktopRyzen() {
    final model = ConfigModel()
      ..cpuType = CpuType.amd
      ..platformType = PlatformType.desktop
      ..misc = AmdConfigBase.commonMisc()
      ..nvram = AmdConfigBase.commonNvram()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(
            enabled: true,
            path: 'SSDT-EC-USBX-DESKTOP.aml',
          ),
        ],
      )
      ..specialMotherboard = SpecialMotherboard.amdNormal
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_amd_desktop_ryzen.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_amd_desktop_ryzen
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_amd_desktop_ryzen.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_amd.copyWith(),
      )
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith()
      ..csrsetting = CsrSetting.enabled
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonDesktopUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
      )
      ..kernel.kernelKexts.addAll([
        ConfigKernel.AMDRyzenCPUPowerManagement.copyWith(),
        ConfigKernel.SMCAMDProcessor.copyWith(),
      ]);

    AmdConfigBase.applyAmdDefaults(model, core: '6');

    return model;
  }
}
