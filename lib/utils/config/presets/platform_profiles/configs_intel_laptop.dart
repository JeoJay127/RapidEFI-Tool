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
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/presets/patches/acpi_patch.dart';
import 'package:rapidefi/utils/config/presets/patches/booter_patch.dart';
import 'package:rapidefi/utils/config/presets/patches/kernel_patch.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_config_repository.dart';
import 'package:rapidefi/utils/config/presets/sections/config_booter.dart';
import 'package:rapidefi/utils/config/presets/sections/config_device_properties.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_misc.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/presets/sections/config_platform_info.dart';
import 'package:rapidefi/utils/config/presets/sections/config_uefi.dart';
import 'package:rapidefi/utils/config/support/platform_properties.dart';

class ConfigsIntelLaptop {
  const ConfigsIntelLaptop._();

  static Map<String, ConfigModelFactory> get factories {
    final codes = PlatformCodeRegistry.codes(
      CpuType.intel,
      PlatformType.laptop,
    );

    return {
      codes[0]: createIntelLaptop0th,
      codes[1]: createIntelLaptop1th,
      codes[2]: createIntelLaptop2th,
      codes[3]: createIntelLaptop3th,
      codes[4]: createIntelLaptop4th,
      codes[5]: createIntelLaptop5th,
      codes[6]: createIntelLaptop6th,
      codes[7]: createIntelLaptop7th,
      codes[8]: createIntelLaptop8th,
      codes[9]: createIntelLaptop9th,
      codes[10]: createIntelLaptop10thCometLake,
      codes[11]: createIntelLaptop10thIceLake,
      codes[12]: createIntelLaptop11thTigerLake,
      codes[13]: createIntelLaptop12thAlderLake,
      codes[14]: createIntelLaptop13thRaptorLake,
      codes[15]: createIntelLaptop14thRaptorLake,
    };
  }

  static ConfigModel createIntelLaptopBase() {
    final model = ConfigModel()
      ..cpuType = CpuType.intel
      ..platformType = PlatformType.laptop
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.wegnoegpu,
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

  static ConfigModel createIntelLaptopLegacy() {
    final model = createIntelLaptopBase()
      ..legacy = true
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-LAPTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-XOSI.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PNLF.aml'),
        ],
        acpiPatchItems: [
          AcpiPatch.osiToXOSI.copyWith(),
        ],
        acpiQuirks: AcpiQuirks(fadtEnableReset: true),
      )
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonLaptopLegacyDriversItems
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

  static ConfigModel createIntelLaptopUefi() {
    final model = createIntelLaptopBase()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-LAPTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-XOSI.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PNLF.aml'),
        ],
        acpiPatchItems: [
          AcpiPatch.osiToXOSI.copyWith(),
        ],
      )
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonLaptopUefiDriversItems
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

  static ConfigModel createIntelLaptop0th() {
    final model = createIntelLaptopLegacy()
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_laptop_0th.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_0th
            .map((item) => item.copyWith())
            .toList(),
        kernelPatchItems: [
          KernelPatch.fixLegacyUSBKeyboard.copyWith(),
        ],
        kernelQuirks: ConfigKernel.kernelQuirks_laptop_0th.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi_get_out_of_my_way,
        ConfigNvram.ipc_control_port_options,
      }
      ..misc = Misc(
        miscBoot: ConfigMisc.commonMiscBoot.copyWith(
          pollAppleHotKeys: false,
        ),
        miscSecurity: ConfigMisc.commonMiscSecurity.copyWith(),
        miscToolsItems: ConfigMisc.commoMiscToolsItems
            .map((item) => item.copyWith())
            .toList(),
      )
      ..csrsetting = CsrSetting.fullyDisabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.NullCPUPowerManagement.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelLaptop1th() {
    final model = createIntelLaptopLegacy()
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_laptop_1th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_laptop_1th.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_1th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_laptop_1th.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi_get_out_of_my_way,
        ConfigNvram.ipc_control_port_options,
      }
      ..misc = Misc(
        miscBoot: ConfigMisc.commonMiscBoot.copyWith(
          pollAppleHotKeys: false,
        ),
        miscSecurity: ConfigMisc.commonMiscSecurity.copyWith(),
        miscToolsItems: ConfigMisc.commoMiscToolsItems
            .map((item) => item.copyWith())
            .toList(),
      )
      ..csrsetting = CsrSetting.fullyDisabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.NullCPUPowerManagement.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelLaptop2th() {
    final model = createIntelLaptopLegacy()
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_laptop_2th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_laptop_2th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_2th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_laptop_2th.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.wegnoegpu,
        ConfigNvram.amfi_get_out_of_my_way,
        ConfigNvram.ipc_control_port_options,
      }
      ..misc = Misc(
        miscBoot: ConfigMisc.commonMiscBoot.copyWith(
          pollAppleHotKeys: false,
        ),
        miscSecurity: ConfigMisc.commonMiscSecurity.copyWith(),
        miscToolsItems: ConfigMisc.commoMiscToolsItems
            .map((item) => item.copyWith())
            .toList(),
      )
      ..csrsetting = CsrSetting.fullyDisabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.NullCPUPowerManagement.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelLaptop3th() {
    final model = createIntelLaptopUefi()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-LAPTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-XOSI.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PNLF.aml'),
        ],
        acpiPatchItems: [
          AcpiPatch.osiToXOSI.copyWith(),
        ],
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
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_laptop_3th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_laptop_3th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_3th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_laptop_3th.copyWith(),
      )
      ..kernel.kernelKexts.addAll([
        ConfigKernel.NullCPUPowerManagement.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith()
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonLaptopLegacyDriversItems
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

  static ConfigModel createIntelLaptop4th() {
    final model = createIntelLaptopUefi()
      ..acpi = _standardPlugLaptopAcpi()
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_laptop_4th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_laptop_4th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_4th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_laptop_4th.copyWith(),
      )
      ..uefi = _standardLaptopUefi()
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

  static ConfigModel createIntelLaptop5th() {
    final model = createIntelLaptopUefi()
      ..acpi = _standardPlugLaptopAcpi()
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_laptop_5th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_laptop_5th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_5th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_laptop_5th.copyWith(),
      )
      ..uefi = _standardLaptopUefi()
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

  static ConfigModel createIntelLaptop6th() {
    final base = createIntelLaptopUefi();

    final model = base
      ..acpi = _modernLaptopAcpi(includeAwac: false, includePmc: false)
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_laptop_6th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_laptop_6th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_6th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_laptop_6th.copyWith(),
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

  static ConfigModel createIntelLaptop7th() {
    final base = createIntelLaptopUefi();

    final model = base
      ..acpi = _modernLaptopAcpi(includeAwac: false, includePmc: false)
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_laptop_7th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_laptop_7th_1.map((item) => item.copyWith()).toList()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.wegnoegpu,
        ConfigNvram.igfxblr,
        ConfigNvram.igfxblt,
      }
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_7th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_laptop_7th.copyWith(),
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

  static ConfigModel createIntelLaptop8th() {
    final base = createIntelLaptopUefi();

    final model = base
      ..acpi = _modernLaptopAcpi(includeAwac: true, includePmc: false)
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_laptop_8th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_laptop_8th_1.map((item) => item.copyWith()).toList()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.wegnoegpu,
        ConfigNvram.igfxblr,
        ConfigNvram.igfxblt,
      }
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_8th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_laptop_8th.copyWith(),
      )
      ..kernel.kernelKexts.addAll([
        ConfigKernel.SMCBatteryManager.copyWith(),
        ConfigKernel.VoodooI2C.copyWith(),
        ConfigKernel.XHCIUnsupported.copyWith(),
      ])
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

  static ConfigModel createIntelLaptop9th() {
    final base = createIntelLaptop8th();

    final model = base
      ..acpi = _modernLaptopAcpi(includeAwac: true, includePmc: true)
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_laptop_9th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_laptop_9th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_9th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_laptop_9th.copyWith(),
      )
      ..uefi.uefiQuirks = createIntelLaptopUefi().uefi.uefiQuirks.copyWith(
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

  static ConfigModel createIntelLaptop10thCometLake() {
    final base = createIntelLaptop8th();

    final model = base
      ..acpi = _modernLaptopAcpi(includeAwac: true, includePmc: true)
      ..booter = Booter(
        booterQuirks:
            ConfigBooter.booterQuirks_laptop_10th_cometLake.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_laptop_10th_1.map((item) => item.copyWith()).toList()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.wegnoegpu,
      }
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_10th_cometLake
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks:
            ConfigKernel.kernelQuirks_laptop_10th_cometLake.copyWith(),
      )
      ..uefi.uefiQuirks = createIntelLaptopUefi().uefi.uefiQuirks.copyWith(
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

  static ConfigModel createIntelLaptop10thIceLake() {
    final base = createIntelLaptop8th();

    final model = base
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_laptop_10th_IceLake.copyWith(),
      )
      ..deviceProperties.addList = ConfigDp.intel_laptop_iceLake_1
          .map((item) => item.copyWith())
          .toList()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.wegnoegpu,
      }
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_10th_IceLake
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_laptop_10th_IceLake.copyWith(),
      )
      ..uefi.uefiQuirks = createIntelLaptopUefi().uefi.uefiQuirks.copyWith(
            ignoreInvalidFlexRatio: false,
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

  static ConfigModel createIntelLaptop11thTigerLake() {
    final base = createIntelLaptop8th();

    final model = base
      ..acpi = _modernLaptopAcpi(includeAwac: true, includePmc: false)
      ..booter = Booter(
        booterQuirks:
            ConfigBooter.booterQuirks_laptop_11th_TigerLake.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
      }
      ..deviceProperties.addList = []
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_10th_IceLake
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks:
            ConfigKernel.kernelQuirks_laptop_11th_TigerLake.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_TigerLake_Later.copyWith(),
      )
      ..uefi.uefiQuirks = createIntelLaptopUefi().uefi.uefiQuirks.copyWith(
            ignoreInvalidFlexRatio: false,
          )
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelLaptop12thAlderLake() {
    final model = createIntelLaptop11thTigerLake()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-AWAC.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-LAPTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG-ALT.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-XOSI.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PNLF.aml'),
        ],
        acpiPatchItems: [
          AcpiPatch.osiToXOSI.copyWith(),
        ],
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_laptop_10th_IceLake
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks:
            ConfigKernel.kernelQuirks_laptop_12th_AlderLake.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_TigerLake_Later.copyWith(),
      );
    return model;
  }

  static ConfigModel createIntelLaptop13thRaptorLake() {
    final model = createIntelLaptop12thAlderLake();
    return model;
  }

  static ConfigModel createIntelLaptop14thRaptorLake() {
    final model = createIntelLaptop12thAlderLake();
    return model;
  }

  static Acpi _standardPlugLaptopAcpi() {
    return Acpi(
      acpiAddItems: [
        AcpiAddItem(enabled: true, path: 'SSDT-EC-LAPTOP.aml'),
        AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
        AcpiAddItem(enabled: true, path: 'SSDT-XOSI.aml'),
        AcpiAddItem(enabled: true, path: 'SSDT-PNLF.aml'),
      ],
      acpiPatchItems: [
        AcpiPatch.osiToXOSI.copyWith(),
      ],
    );
  }

  static Acpi _modernLaptopAcpi({
    required bool includeAwac,
    required bool includePmc,
  }) {
    return Acpi(
      acpiAddItems: [
        AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-LAPTOP.aml'),
        if (includeAwac) AcpiAddItem(enabled: true, path: 'SSDT-AWAC.aml'),
        AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
        AcpiAddItem(enabled: true, path: 'SSDT-XOSI.aml'),
        AcpiAddItem(enabled: true, path: 'SSDT-PNLF.aml'),
        if (includePmc) AcpiAddItem(enabled: true, path: 'SSDT-PMC.aml'),
      ],
      acpiPatchItems: [
        AcpiPatch.osiToXOSI.copyWith(),
      ],
    );
  }

  static Uefi _standardLaptopUefi() {
    return Uefi(
      uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
      uefiDriversItems: ConfigUefi.commonLaptopUefiDriversItems
          .map((item) => item.copyWith())
          .toList(),
      uefiInput: UefiInput(keySupport: true),
      uefiQuirks: UefiQuirks(
        releaseUsbOwnership: true,
        ignoreInvalidFlexRatio: true,
      ),
    );
  }
}
