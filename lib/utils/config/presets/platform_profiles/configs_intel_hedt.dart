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
import 'package:rapidefi/utils/config/presets/sections/config_booter.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_misc.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/presets/sections/config_platform_info.dart';
import 'package:rapidefi/utils/config/presets/sections/config_uefi.dart';

class ConfigsIntelHedt {
  const ConfigsIntelHedt._();

  static Map<String, ConfigModelFactory> get factories {
    final codes = PlatformCodeRegistry.codes(
      CpuType.intel,
      PlatformType.hedt,
    );

    return {
      codes[0]: createIntelHedt1th,
      codes[1]: createIntelHedt2th,
      codes[2]: createIntelHedt3th,
      codes[3]: createIntelHedt4th,
      codes[4]: createIntelHedt5th,
      codes[5]: createIntelHedt6th,
      codes[6]: createIntelHedt10th,
    };
  }

  static ConfigModel createIntelHedtBase() {
    final model = ConfigModel()
      ..cpuType = CpuType.intel
      ..platformType = PlatformType.hedt
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-DESKTOP.aml'),
        ],
      )
      ..misc = _commonMisc()
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

  static ConfigModel createIntelHedtLegacy() {
    final model = createIntelHedtBase()
      ..legacy = true
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-DESKTOP.aml'),
        ],
        acpiQuirks: AcpiQuirks(fadtEnableReset: true),
      )
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonHedtLegacyDriversItems
            .map((item) => item.copyWith())
            .toList(),
        uefiInput: UefiInput(keySupport: false),
        uefiQuirks: UefiQuirks(ignoreInvalidFlexRatio: true),
      );

    return model;
  }

  static ConfigModel createIntelHedtUefi() {
    final model = createIntelHedtBase()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
        ],
      )
      ..kernel.kernelKexts.addAll([
        ConfigKernel.XHCIUnsupported.copyWith(),
      ])
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonHedtUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
      );

    return model;
  }

  static ConfigModel createIntelHedtSkylake() {
    final model = createIntelHedtUefi()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-RTC0-RANGE.aml'),
        ],
      )
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonHedtUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
        uefiQuirks: UefiQuirks(ignoreInvalidFlexRatio: false),
      );

    return model;
  }

  static ConfigModel createIntelHedt1th() {
    final model = createIntelHedtLegacy()
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_hedt_1th.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi_get_out_of_my_way,
        ConfigNvram.ipc_control_port_options,
      }
      ..misc = _legacyMisc()
      ..csrsetting = CsrSetting.fullyDisabled
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_hedt_1th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_hedt_1th.copyWith(),
      )
      ..kernel.kernelKexts.addAll([
        ConfigKernel.NullCPUPowerManagement.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelHedt2th() {
    final model = createIntelHedtLegacy()
      ..legacy = true
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-UNC.aml'),
        ],
        acpiQuirks: AcpiQuirks(fadtEnableReset: true),
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_hedt_2th.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi_get_out_of_my_way,
        ConfigNvram.ipc_control_port_options,
      }
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_hedt_2th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_hedt_2th.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_Haswell_Before.copyWith(),
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

  static ConfigModel createIntelHedt3th() {
    final model = createIntelHedt2th()
      ..legacy = false
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_hedt_3th.copyWith(),
      )
      ..bootArgModels = {
        ConfigNvram.verbose,
        ConfigNvram.keepsyms1,
        ConfigNvram.debug100,
        ConfigNvram.amfi,
        ConfigNvram.ipc_control_port_options,
      }
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_hedt_3th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_hedt_3th.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_Haswell_Before.copyWith(),
      )
      ..csrsetting = CsrSetting.fullyDisabled
      ..kernel.kernelKexts.addAll([
        ConfigKernel.NullCPUPowerManagement.copyWith(),
        ConfigKernel.AMFIPass.copyWith(),
        ConfigKernel.XHCIUnsupported.copyWith(),
      ])
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith()
      ..uefi = Uefi(
        uefiApfs: ConfigUefi.commonUefiApfs.copyWith(),
        uefiDriversItems: ConfigUefi.commonHedtUefiDriversItems
            .map((item) => item.copyWith())
            .toList(),
      );
    return model;
  }

  static ConfigModel createIntelHedt4th() {
    final model = createIntelHedtUefi()
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(enabled: true, path: 'SSDT-EC-USBX-DESKTOP.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-PLUG.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-RTC0-RANGE.aml'),
          AcpiAddItem(enabled: true, path: 'SSDT-UNC.aml'),
        ],
      )
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_hedt_4th.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_hedt_4th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_hedt_4th.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_Haswell_HEDT.copyWith(),
      )
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelHedt5th() {
    final model = createIntelHedt4th()
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_hedt_5th.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_hedt_5th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_hedt_5th.copyWith(),
        kernelEmulate: ConfigKernel.kernelEmulate_Broadwell_HEDT.copyWith(),
      )
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelHedt6th() {
    final model = createIntelHedtSkylake()
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_hedt_6th.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_hedt_6th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_hedt_6th.copyWith(),
      )
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static ConfigModel createIntelHedt10th() {
    final model = createIntelHedtSkylake()
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_hedt_10th.copyWith(),
      )
      ..kernel = Kernel(
        kernelKexts: ConfigKernel.kernelKextsList_hedt_10th
            .map((item) => item.copyWith())
            .toList(),
        kernelQuirks: ConfigKernel.kernelQuirks_hedt_4th.copyWith(),
      )
      ..csrsetting = CsrSetting.enabled
      ..platformInfo = ConfigPi.commonPlatformInfo.copyWith();
    return model;
  }

  static Misc _commonMisc() {
    return Misc(
      miscBoot: ConfigMisc.commonMiscBoot.copyWith(),
      miscSecurity: ConfigMisc.commonMiscSecurity.copyWith(),
      miscToolsItems: ConfigMisc.commoMiscToolsItems
          .map((item) => item.copyWith())
          .toList(),
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
