import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/models/booter/booter.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_quirks.dart';
import 'package:rapidefi/utils/config/presets/patches/acpi_patch.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/amd_config_base.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_config_repository.dart';
import 'package:rapidefi/utils/config/presets/sections/config_booter.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/presets/sections/config_platform_info.dart';
import 'package:rapidefi/utils/config/presets/sections/config_uefi.dart';

class ConfigsAmdLaptop with AmdConfigBase {
  const ConfigsAmdLaptop._();

  static Map<String, ConfigModelFactory> get factories {
    final codes = PlatformCodeRegistry.codes(
      CpuType.amd,
      PlatformType.laptop,
    );

    return {
      codes[0]: createAmdLaptopLegacy,
      codes[1]: createAmdLaptopRyzen,
    };
  }

  static ConfigModel createAmdLaptopBase() {
    final model = ConfigModel()
      ..cpuType = CpuType.amd
      ..platformType = PlatformType.laptop
      ..misc = AmdConfigBase.commonMisc()
      ..nvram = AmdConfigBase.commonNvram();

    return model;
  }

  static ConfigModel createAmdLaptopLegacy() {
    final model = createAmdLaptopBase()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.wegnoegpu,
        ConfigNvram.amfi_get_out_of_my_way,
        ConfigNvram.ipc_control_port_options
      }
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(
            enabled: true,
            path: 'SSDT-EC-USBX-LAPTOP.aml',
          ),
          AcpiAddItem(
            enabled: true,
            path: 'SSDT-PNLF.aml',
          ),
          AcpiAddItem(
            enabled: true,
            path: 'SSDT-XOSI.aml',
          ),
        ],
        acpiPatchItems: [
          AcpiPatch.osiToXOSI.copyWith(),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_amd_laptop_legacy.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_amd_laptop_legacy
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_amd_laptop_legacy.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_amd.copyWith(),
      )
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith()
      ..csrsetting = CsrSetting.partialDisabled
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonDesktopUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
        uefiQuirks: UefiQuirks(
          releaseUsbOwnership: true,
          ignoreInvalidFlexRatio: false,
        ),
      )
      ..kernel.kernelKexts.addAll([
        ConfigKernel.ACPIBatteryManager.copyWith(),
        ConfigKernel.VoodooPS2Controller.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
        ConfigKernel.GenericUSBXHCI.copyWith(),
      ]);

    AmdConfigBase.applyAmdDefaults(
      model,
      core: '4',
    );
    return model;
  }

  static ConfigModel createAmdLaptopRyzen() {
    final model = createAmdLaptopBase()
      ..specialMotherboard = SpecialMotherboard.amdNormal
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.wegnoegpu,
        ConfigNvram.i2c_force_polling,
      }
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(
            enabled: true,
            path: 'SSDT-EC-USBX-LAPTOP.aml',
          ),
          AcpiAddItem(
            enabled: true,
            path: 'SSDT-PLUG-ALT.aml',
          ),
          AcpiAddItem(
            enabled: true,
            path: 'SSDT-PNLF.aml',
          ),
          AcpiAddItem(
            enabled: true,
            path: 'SSDT-XOSI.aml',
          ),
        ],
        acpiPatchItems: [
          AcpiPatch.osiToXOSI.copyWith(),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_amd_laptop_ryzen.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_amd_laptop_ryzen
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_amd_laptop_ryzen.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_amd.copyWith(),
      )
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith()
      ..csrsetting = CsrSetting.enabled
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonLaptopUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
        uefiQuirks: UefiQuirks(
          releaseUsbOwnership: true,
          ignoreInvalidFlexRatio: false,
        ),
      )
      ..kernel.kernelKexts.addAll([
        ConfigKernel.SMCBatteryManager.copyWith(),
        ConfigKernel.VoodooPS2Controller.copyWith(),
        ConfigKernel.AMDRyzenCPUPowerManagement.copyWith(),
        ConfigKernel.SMCAMDProcessor.copyWith(),
        ConfigKernel.GenericUSBXHCI.copyWith(),
      ]);

    AmdConfigBase.applyAmdDefaults(
      model,
      core: '6',
      useRyzenGpu: true,
    );
    return model;
  }
}
