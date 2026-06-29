import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/models/booter/booter.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_quirks.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/amd_config_base.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_config_repository.dart';
import 'package:rapidefi/utils/config/presets/sections/config_booter.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/presets/sections/config_platform_info.dart';
import 'package:rapidefi/utils/config/presets/sections/config_uefi.dart';

class ConfigsAmdNuc with AmdConfigBase {
  const ConfigsAmdNuc._();

  static Map<String, ConfigModelFactory> get factories {
    final codes = PlatformCodeRegistry.codes(
      CpuType.amd,
      PlatformType.nuc,
    );

    return {
      codes[0]: createAmdNucLegacy,
      codes[1]: createAmdNucRyzen,
    };
  }

  static ConfigModel createAmdNucBase() {
    final model = ConfigModel()
      ..cpuType = CpuType.amd
      ..platformType = PlatformType.nuc
      ..misc = AmdConfigBase.commonMisc()
      ..nvram = AmdConfigBase.commonNvram();

    return model;
  }

  static ConfigModel createAmdNucLegacy() {
    final model = createAmdNucBase()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi_get_out_of_my_way,
        ConfigNvram.ipc_control_port_options
      }
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(
            enabled: true,
            path: 'SSDT-EC-USBX-DESKTOP.aml',
          ),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_amd_nuc_legacy.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_amd_nuc_legacy
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_amd_nuc_legacy.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_amd.copyWith(),
      )
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith()
      ..csrsetting = CsrSetting.partialDisabled
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonNucUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
        uefiQuirks: UefiQuirks(
          releaseUsbOwnership: true,
          ignoreInvalidFlexRatio: false,
        ),
      )
      ..kernel.kernelKexts.addAll([
        ConfigKernel.AMFIPass.copyWith(),
        ConfigKernel.GenericUSBXHCI.copyWith(),
      ]);

    AmdConfigBase.applyAmdDefaults(
      model,
      core: '4',
    );
    return model;
  }

  static ConfigModel createAmdNucRyzen() {
    final model = createAmdNucBase()
      ..specialMotherboard = SpecialMotherboard.amdNormal
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(
            enabled: true,
            path: 'SSDT-EC-USBX-DESKTOP.aml',
          ),
          AcpiAddItem(
            enabled: true,
            path: 'SSDT-PLUG-ALT.aml',
          ),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_amd_nuc_ryzen.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_amd_hedt_ryzen
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_amd_hedt_ryzen.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_amd.copyWith(),
      )
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith()
      ..csrsetting = CsrSetting.enabled
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonHedtUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
        uefiQuirks: UefiQuirks(
          releaseUsbOwnership: true,
          ignoreInvalidFlexRatio: false,
        ),
      )
      ..kernel.kernelKexts.addAll([
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
