import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_quirks.dart';
import 'package:rapidefi/utils/config/models/booter/booter.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel.dart';
import 'package:rapidefi/utils/config/models/misc/misc.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_add.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_delete.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_input.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_quirks.dart';
import 'package:rapidefi/utils/config/presets/patches/booter_patch.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_config_repository.dart';
import 'package:rapidefi/utils/config/presets/sections/config_booter.dart';
import 'package:rapidefi/utils/config/presets/sections/config_device_properties.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_misc.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/presets/sections/config_platform_info.dart';
import 'package:rapidefi/utils/config/presets/sections/config_uefi.dart';
import 'package:rapidefi/utils/config/support/platform_properties.dart';

class ConfigsIntelNuc {
  const ConfigsIntelNuc._();

  static Map<String, ConfigModelFactory> get factories {
    final codes = PlatformCodeRegistry.codes(
      CpuType.intel,
      PlatformType.nuc,
    );

    return {
      codes[0]: createIntelNuc0th,
      codes[1]: createIntelNuc1th,
      codes[2]: createIntelNuc2th,
      codes[3]: createIntelNuc3th,
      codes[4]: createIntelNuc4th,
      codes[5]: createIntelNuc5th,
      codes[6]: createIntelNuc6th,
      codes[7]: createIntelNuc7th,
      codes[8]: createIntelNuc8th,
      codes[9]: createIntelNuc9th,
      codes[10]: createIntelNuc10thCometLake,
      codes[11]: createIntelNuc10thIceLake,
      codes[12]: createIntelNuc11thTigerLake,
      codes[13]: createIntelNuc12thAlderLake,
      codes[14]: createIntelNuc13thRaptorLake,
      codes[15]: createIntelNuc14thRaptorLake,
    };
  }

  static ConfigModel createIntelNucBase() {
    final model = ConfigModel()
      ..cpuType = CpuType.intel
      ..platformType = PlatformType.nuc
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
      }
      ..misc = Misc(
        miscBoot: ConfigMisc.commonMiscBoot.copyWith(),
        miscSecurity: ConfigMisc.commonMiscSecurity.copyWith(),
        miscToolsItems: ConfigMisc.commoMiscToolsItems
            .map((item) => item.copyWith())
            .toList(),
      )
      ..nvram = NVRAM(
        nvramAdd: NvramAdd(
          addList: ConfigNvram.createAddList(),
        ),
        nvramDelete: NvramDelete(
          deleteList: ConfigNvram.createDeleteList(),
        ),
      );

    return model;
  }

  static ConfigModel createIntelNucLegacy() {
    final model = createIntelNucBase()
      ..legacy = true
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-DESKTOP.aml'),
        ],
        acpiQuirks: AcpiQuirks(fadtEnableReset: true),
      )
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonNucLegacyDriversItems
            .map((item) => item.copyWith())
            .toList(),
        uefiInput: UefiInput(keySupport: false),
        uefiQuirks: UefiQuirks(
          releaseUsbOwnership: true,
          ignoreInvalidFlexRatio: true,
        ),
      );

    return model;
  }

  static ConfigModel createIntelNucUefi() {
    final model = createIntelNucBase()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-DESKTOP.aml'),
        ],
      )
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonNucUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
        uefiInput: UefiInput(keySupport: true),
        uefiQuirks: UefiQuirks(
          releaseUsbOwnership: true,
          ignoreInvalidFlexRatio: true,
        ),
      );

    return model;
  }

  static ConfigModel createIntelNuc0th() {
    final model = createIntelNucLegacy()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi_get_out_of_my_way,
        ConfigNvram.ipc_control_port_options,
      }
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_nuc_0th.copyWith(),
      )
      ..deviceProperties.addList = []
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_0th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_0th.copyWith(),
      )
      ..misc = _legacyMisc()
      ..csrsetting = CsrSetting.fullyDisabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.NullCPUPowerManagement.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelNuc1th() {
    final model = createIntelNucLegacy()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi_get_out_of_my_way,
        ConfigNvram.ipc_control_port_options,
      }
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_nuc_1th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_nuc_1th.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_1th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_1th.copyWith(),
      )
      ..misc = _legacyMisc()
      ..csrsetting = CsrSetting.fullyDisabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.NullCPUPowerManagement.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelNuc2th() {
    final model = createIntelNucLegacy()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi_get_out_of_my_way,
        ConfigNvram.ipc_control_port_options,
      }
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_nuc_2th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_nuc_2th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_2th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_2th.copyWith(),
      )
      ..misc = _legacyMisc()
      ..csrsetting = CsrSetting.fullyDisabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.NullCPUPowerManagement.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelNuc3th() {
    final model = createIntelNucUefi()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi,
        ConfigNvram.ipc_control_port_options,
      }
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_nuc_3th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_nuc_3th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_3th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_3th.copyWith(),
      )
      ..csrsetting = CsrSetting.partialDisabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.NullCPUPowerManagement.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith()
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonNucLegacyUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
        uefiInput: UefiInput(keySupport: true),
        uefiQuirks: UefiQuirks(
          releaseUsbOwnership: true,
          ignoreInvalidFlexRatio: true,
        ),
      );
    return model;
  }

  static ConfigModel createIntelNuc4th() {
    final model = createIntelNucUefi()
      ..acpi = _plugDesktopAcpi()
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_nuc_4th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_nuc_4th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_4th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_4th.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.wegnoegpu,
        ConfigNvram.amfi,
        ConfigNvram.ipc_control_port_options,
      }
      ..csrsetting = CsrSetting.partialDisabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    DevicePropertiesAccessor.addIGPUProperties(model, [
      framebuffer_stolenmem_1k,
      framebuffer_fbmem,
      framebuffer_cursormem_1k,
    ]);
    return model;
  }

  static ConfigModel createIntelNuc5th() {
    final model = createIntelNuc4th()
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_nuc_5th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_nuc_5th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_5th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_5th.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.wegnoegpu,
        ConfigNvram.amfi,
        ConfigNvram.ipc_control_port_options,
      }
      ..csrsetting = CsrSetting.partialDisabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    DevicePropertiesAccessor.addIGPUProperties(model, [
      framebuffer_stolenmem_1k,
      framebuffer_fbmem,
    ]);
    return model;
  }

  static ConfigModel createIntelNuc6th() {
    final base = createIntelNucUefi();

    final model = base
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_nuc_6th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_nuc_6th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_6th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_6th.copyWith(),
      )
      ..uefi.uefiQuirks = base.uefi.uefiQuirks.copyWith(
        ignoreInvalidFlexRatio: false,
      )
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    DevicePropertiesAccessor.addIGPUProperties(model, [
      framebuffer_stolenmem_1k,
      framebuffer_fbmem,
    ]);
    return model;
  }

  static ConfigModel createIntelNuc7th() {
    final model = createIntelNuc6th()
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_nuc_7th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_nuc_7th_1.map((item) => item.copyWith()).toList()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.igfxblr,
        ConfigNvram.igfxblt,
      }
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_7th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_7th.copyWith(),
      )
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    DevicePropertiesAccessor.addIGPUProperties(model, [
      framebuffer_stolenmem_1k,
      framebuffer_fbmem,
    ]);
    return model;
  }

  static ConfigModel createIntelNuc8th() {
    final model = createIntelNuc6th()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-AWAC.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_nuc_8th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_nuc_8th_1.map((item) => item.copyWith()).toList()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.igfxonln,
        ConfigNvram.igfxblr,
        ConfigNvram.igfxblt,
      }
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_8th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_8th.copyWith(),
      )
      ..csrsetting = CsrSetting.enabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.XHCIUnsupported.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    DevicePropertiesAccessor.addIGPUProperties(model, [
      framebuffer_stolenmem_1k,
      framebuffer_fbmem,
    ]);
    return model;
  }

  static ConfigModel createIntelNuc9th() {
    final model = createIntelNuc8th()
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_nuc_9th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_nuc_9th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_9th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_9th.copyWith(),
      )
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    DevicePropertiesAccessor.addIGPUProperties(model, [
      framebuffer_stolenmem_1k,
      framebuffer_fbmem,
    ]);
    return model;
  }

  static ConfigModel createIntelNuc10thCometLake() {
    final model = createIntelNuc8th()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-AWAC.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PMC.aml'),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_nuc_10th_cometLake.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_nuc_10th_1.map((item) => item.copyWith()).toList()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.igfxonln,
      }
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_10th_cometLake
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_10th_cometLake.copyWith(),
      )
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    DevicePropertiesAccessor.addIGPUProperties(model, [
      framebuffer_stolenmem_1k,
      framebuffer_fbmem,
    ]);
    return model;
  }

  static ConfigModel createIntelNuc10thIceLake() {
    final model = createIntelNuc8th()
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_nuc_10th_IceLake.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_nuc_iceLake_1.map((item) => item.copyWith()).toList()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.igfxonln,
      }
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_10th_IceLake
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_10th_IceLake.copyWith(),
      )
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    DevicePropertiesAccessor.addIGPUProperties(model, [
      framebuffer_enable_dbuf_early_optimizer,
      framebuffer_enable_dvmt_calc_fix,
      framebuffer_enable_cdclk_frequency_fix,
      framebuffer_stolenmem_1k,
      framebuffer_fbmem,
    ]);
    return model;
  }

  static ConfigModel createIntelNuc11thTigerLake() {
    final base = createIntelNucUefi();

    final model = createIntelNuc10thIceLake()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-AWAC.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_nuc_11th_TigerLake.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
      }
      ..deviceProperties.addList = []
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_10th_IceLake
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_11th_TigerLake.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_TigerLake_Later.copyWith(),
      )
      ..uefi.uefiQuirks = base.uefi.uefiQuirks.copyWith(
        ignoreInvalidFlexRatio: false,
      )
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelNuc12thAlderLake() {
    final model = createIntelNuc11thTigerLake()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-AWAC.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG-ALT.aml'),
        ],
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_nuc_10th_IceLake
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_nuc_12th_AlderLake.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_TigerLake_Later.copyWith(),
      );
    return model;
  }

  static ConfigModel createIntelNuc13thRaptorLake() {
    final model = createIntelNuc12thAlderLake();
    return model;
  }

  static ConfigModel createIntelNuc14thRaptorLake() {
    final model = createIntelNuc12thAlderLake();
    return model;
  }

  static Acpi _plugDesktopAcpi() {
    return Acpi(
      acpiAddItems: [
        AcpiAddItem(enabled: true, path: 'SSDT-EC-DESKTOP.aml'),
        AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
      ],
    );
  }

  static Misc _legacyMisc() {
    return Misc(
      miscBoot: ConfigMisc.commonMiscBoot.copyWith(
        pollAppleHotKeys: false,
      ),
      miscSecurity: ConfigMisc.commonMiscSecurity.copyWith(),
      miscToolsItems: ConfigMisc.commoMiscToolsItems
          .map((item) => item.copyWith())
          .toList(),
    );
  }
}
