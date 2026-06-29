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
import 'package:rapidefi/utils/config/presets/sections/config_platform_info.dart';
import 'package:rapidefi/utils/config/presets/sections/config_uefi.dart';

class ConfigsAmdHedt with AmdConfigBase {
  const ConfigsAmdHedt._();

  static Map<String, ConfigModelFactory> get factories {
    final codes = PlatformCodeRegistry.codes(
      CpuType.amd,
      PlatformType.hedt,
    );

    return {
      codes[0]: createAmdHedtRyzen,
    };
  }

  static ConfigModel createAmdHedtBase() {
    final model = ConfigModel()
      ..cpuType = CpuType.amd
      ..platformType = PlatformType.hedt
      ..acpi = Acpi(
        acpiAddItems: [
          AcpiAddItem(
            enabled: true,
            path: 'SSDT-EC-USBX-DESKTOP.aml',
          ),
        ],
      )
      ..misc = AmdConfigBase.commonMisc()
      ..nvram = AmdConfigBase.commonNvram();

    return model;
  }

  static ConfigModel createAmdHedtRyzen() {
    final model = createAmdHedtBase()
      ..specialMotherboard = SpecialMotherboard.amdNormal
      ..booter = Booter(
        booterQuirks: ConfigBooter.booterQuirks_amd_hedt_ryzen.copyWith(),
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
      )
      ..kernel.kernelKexts.addAll([
        ConfigKernel.AMDRyzenCPUPowerManagement.copyWith(),
        ConfigKernel.SMCAMDProcessor.copyWith(),
      ]);

    AmdConfigBase.applyAmdDefaults(model, core: '6');

    return model;
  }
}
