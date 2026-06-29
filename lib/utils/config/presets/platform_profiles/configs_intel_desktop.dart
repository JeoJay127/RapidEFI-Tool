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
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_config_repository.dart';
import 'package:rapidefi/utils/config/presets/patches/acpi_patch.dart';
import 'package:rapidefi/utils/config/presets/patches/booter_patch.dart';
import 'package:rapidefi/utils/config/presets/patches/kernel_patch.dart';
import 'package:rapidefi/utils/config/presets/sections/config_acpi.dart';
import 'package:rapidefi/utils/config/presets/sections/config_booter.dart';
import 'package:rapidefi/utils/config/presets/sections/config_device_properties.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_misc.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/presets/sections/config_platform_info.dart';
import 'package:rapidefi/utils/config/presets/sections/config_uefi.dart';
import 'package:rapidefi/utils/config/support/platform_properties.dart';

class ConfigsIntelDesktop {
  const ConfigsIntelDesktop._();

  static Map<String, ConfigModelFactory> get factories {
    final codes = PlatformCodeRegistry.codes(
      CpuType.intel,
      PlatformType.desktop,
    );

    return {
      codes[0]: createIntelDesktop0th,
      codes[1]: createIntelDesktop1th,
      codes[2]: createIntelDesktop2th,
      codes[3]: createIntelDesktop3th,
      codes[4]: createIntelDesktop4th,
      codes[5]: createIntelDesktop5th,
      codes[6]: createIntelDesktop6th,
      codes[7]: createIntelDesktop7th,
      codes[8]: createIntelDesktop8th,
      codes[9]: createIntelDesktop9th,
      codes[10]: createIntelDesktop10th,
      codes[11]: createIntelDesktop11th,
      codes[12]: createIntelDesktop12th,
      codes[13]: createIntelDesktop13th,
      codes[14]: createIntelDesktop14th,
      codes[15]: createIntelDesktop15th,
    };
  }

  static ConfigModel createIntelDesktopBase() {
    return ConfigModel()
      ..cpuType = CpuType.intel
      ..platformType = PlatformType.desktop
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
      }
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-DESKTOP.aml'),
        ],
      )
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
  }

  static ConfigModel createIntelDesktopLegacy() {
    final model = createIntelDesktopBase()
      ..legacy = true
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-DESKTOP.aml'),
        ],
        acpiQuirks: AcpiQuirks(fadtEnableReset: true),
      )
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonDesktopLegacyDriversItems
            .map((item) => item.copyWith())
            .toList(),
        uefiInput: UefiInput(keySupport: false),
        uefiQuirks: UefiQuirks(ignoreInvalidFlexRatio: true),
      );

    return model;
  }

  static ConfigModel createIntelDesktopUefi() {
    final model = createIntelDesktopBase()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
        ],
      )
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonDesktopUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
      );

    return model;
  }

  static ConfigModel createIntelDesktopSkylake() {
    final model = createIntelDesktopUefi()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
        ],
      )
      ..kernel.kernelKexts.addAll([
        ConfigKernel.XHCIUnsupported.copyWith(),
      ])
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonDesktopUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
      );

    return model;
  }

  static ConfigModel createIntelDesktop0th() {
    final model = createIntelDesktopLegacy()
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_intel_desktop_0th.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_desktop_0th
            .map((item) => item.copyWith())
            .toList(),
        kernelPatchItems: [
          KernelPatch.fixLegacyUSBKeyboard.copyWith(),
        ],
        kernelQuirks: ConfigKernel.kernelQuirks_desktop_0th.copyWith(),
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

  static ConfigModel createIntelDesktop3th() {
    final model = createIntelDesktopUefi()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-DESKTOP.aml'),
        ],
        acpiDeleteItems: ConfigAcpi.sandyBridgeAndIvyBridgeDeletePatches
            .map((item) => item.copyWith())
            .toList(),
      )
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_intel_desktop_3th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_desktop_3th.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_desktop_3th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_desktop_3th.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_Haswell_Before.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi,
        ConfigNvram.ipc_control_port_options,
      }
      ..csrsetting = CsrSetting.partialDisabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.NullCPUPowerManagement.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith()
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonDesktopLegacyUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
        uefiQuirks: UefiQuirks(ignoreInvalidFlexRatio: true),
      );
    return model;
  }

  /// 下面几个先给占位示范，迁移时逐步补全。

  static ConfigModel createIntelDesktop1th() {
    final model = createIntelDesktopLegacy()
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_intel_desktop_1th.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_desktop_1th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_desktop_1th.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_Haswell_Before.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi_get_out_of_my_way,
        ConfigNvram.ipc_control_port_options,
      }
      ..csrsetting = CsrSetting.fullyDisabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.NullCPUPowerManagement.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelDesktop2th() {
    final model = createIntelDesktopLegacy()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-DESKTOP.aml'),
        ],
        acpiDeleteItems: ConfigAcpi.sandyBridgeAndIvyBridgeDeletePatches
            .map((item) => item.copyWith())
            .toList(),
      )
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_intel_desktop_2th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_desktop_2th.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_desktop_2th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_desktop_2th.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_Haswell_Before.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi_get_out_of_my_way,
        ConfigNvram.ipc_control_port_options,
      }
      ..csrsetting = CsrSetting.fullyDisabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.NullCPUPowerManagement.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelDesktop4th() {
    final model = createIntelDesktopUefi()
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_intel_desktop_4th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_desktop_4th.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_desktop_4th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_desktop_4th.copyWith(),
      )
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonDesktopUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
        uefiQuirks: UefiQuirks(ignoreInvalidFlexRatio: true),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
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

  static ConfigModel createIntelDesktop5th() {
    final model = createIntelDesktop4th()
      ..booter = Booter(
        booterPatchItems: [
          BooterPatch.skipBoardIDCheck.copyWith(),
        ],
        booterQuirks: ConfigBooter.booterQuirks_intel_desktop_5th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_desktop_5th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_desktop_5th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_desktop_5th.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
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

  static ConfigModel createIntelDesktop6th() {
    final model = createIntelDesktopSkylake()
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_intel_desktop_6th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_desktop_6th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_desktop_6th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_desktop_6th.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
      }
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelDesktop7th() {
    final model = createIntelDesktopSkylake()
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_intel_desktop_7th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_desktop_7th_1.map((item) => item.copyWith()).toList()
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_desktop_7th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_desktop_7th.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
      }
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    DevicePropertiesAccessor.addIGPUProperties(model, [
      framebuffer_stolenmem_1k,
      framebuffer_fbmem,
    ]);
    return model;
  }

  static ConfigModel createIntelDesktop8th() {
    final model = createIntelDesktopSkylake()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-AWAC.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PMC.aml'),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_intel_desktop_8th.copyWith(),
      )
      ..deviceProperties.addList =
          ConfigDp.intel_desktop_8th_1.map((item) => item.copyWith()).toList()
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.igfxonln,
      }
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_desktop_8th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_desktop_8th.copyWith(),
      )
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    DevicePropertiesAccessor.addIGPUProperties(model, [
      framebuffer_stolenmem_1k,
      framebuffer_fbmem,
    ]);
    return model;
  }

  static ConfigModel createIntelDesktop9th() {
    final model = createIntelDesktop8th()
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_intel_desktop_9th.copyWith(),
      );
    return model;
  }

  static ConfigModel createIntelDesktop10th() {
    final model = createIntelDesktop8th()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-AWAC.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_intel_desktop_10th.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_desktop_10th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_desktop_10th.copyWith(),
      )
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelDesktop11th() {
    final model = createIntelDesktop8th()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-AWAC.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_intel_desktop_11th.copyWith(),
      )
      ..deviceProperties.addList = []
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
      }
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_desktop_11th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_desktop_11th.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_RocketLake_Later.copyWith(),
      )
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelDesktop12th() {
    final model = createIntelDesktop11th()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-AWAC.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG-ALT.aml'),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_intel_desktop_12th.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_desktop_12th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_desktop_12th.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_RocketLake_Later.copyWith(),
      )
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelDesktop13th() {
    final model = createIntelDesktop12th();
    return model;
  }

  static ConfigModel createIntelDesktop14th() {
    final model = createIntelDesktop12th();
    return model;
  }

  static ConfigModel createIntelDesktop15th() {
    final model = createIntelDesktop12th()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-AWAC.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG-ALT.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-UNC.aml'),
        ],
        acpiPatchItems: [
          AcpiPatch.ACPI_PCHA_Z890.copyWith(),
        ],
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_desktop_15th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_desktop_15th.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_RocketLake_Later.copyWith(),
      );
    return model;
  }
}
