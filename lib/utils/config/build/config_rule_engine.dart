import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:rapidefi/extension/string_extension.dart';
import 'package:rapidefi/utils/config/accessors/amd_settings_accessor.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/build/config_draft.dart';
import 'package:rapidefi/utils/config/build/efi_build_options.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/models/device_properties/igpu_model.dart';
import 'package:rapidefi/utils/config/models/enums/brand_enum.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_drivers_item.dart';
import 'package:rapidefi/utils/config/presets/patches/kernel_patch.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_configs.dart';
import 'package:rapidefi/utils/config/presets/sections/config_acpi.dart';
import 'package:rapidefi/utils/config/presets/sections/config_device_properties.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/services/config_session.dart';
import 'package:rapidefi/utils/config/services/config_model_editor.dart';
import 'package:rapidefi/utils/config/services/config_service.dart';
import 'package:rapidefi/utils/config/support/smbios_compatibility.dart';
import 'package:rapidefi/utils/config/support/smbios_util.dart';
import 'package:rapidefi/utils/log/log.dart';

class ConfigRuleEngine {
  const ConfigRuleEngine(this.configService);

  final ConfigService configService;
  static Future<Set<String>?>? _assetManifestCache;

  static final List<AcpiAddItem> managedOtherSSDTs = [
    ConfigAcpi.SSDT_IMEI,
    ConfigAcpi.SSDT_RMNE,
    ConfigAcpi.SSDT_ALS0,
    ConfigAcpi.SSDT_CPUR,
    ConfigAcpi.SSDT_RHUB,
  ];

  Future<ConfigDraft> buildDraft({
    EfiBuildOptions options = const EfiBuildOptions(),
  }) async {
    configService.normalizeRuntimeConfigModel();
    preOptions();
    await updateSMBIOS();

    final outputDirectory =
        options.outDirectory ?? configService.outputDirectory;
    final macOSVersionName =
        configService.configModel.macOSVersion.split(' ').first;
    var efiName =
        '$macOSVersionName-EFI-${configService.ocVersion}-${configService.plantformInfo}';
    if (configService.configModelMode == ConfigModelMode.auto) {
      efiName =
          'AutoEFI-${configService.ocVersion}-${configService.plantformInfo}';
    }
    if (options.efiNameOverride != null &&
        options.efiNameOverride!.trim().isNotEmpty) {
      efiName = options.efiNameOverride!.trim();
    }

    final patchModel = configService.buildPatchModel(configService.configModel);
    final persistedModel =
        configService.buildPersistedConfigModel(configService.configModel);
    await _removeMissingStaticAcpiItems(
      patchModel,
      persistedModel,
      options.acpiSourceDirectory,
    );
    return ConfigDraft(
      sourceModel: configService.configModel,
      patchModel: patchModel,
      persistedModel: persistedModel,
      acpiItems: patchModel.acpi.acpiAddItems,
      kexts: patchModel.kernel.kernelKexts,
      outputDirectory: outputDirectory,
      efiName: efiName,
      saveHistory: options.saveHistory,
      acpiSourceDirectory: options.acpiSourceDirectory,
      saveConfigModel: options.saveConfigModel,
      zipEfi: options.zipEfi,
      afterConfigWritten: options.afterConfigWritten,
    );
  }

  Future<void> _removeMissingStaticAcpiItems(
    ConfigModel patchModel,
    ConfigModel persistedModel,
    String? acpiSourceDirectory,
  ) async {
    final assets = await _assetManifestAssets();
    if (assets == null) return;
    final sourceDirectory = acpiSourceDirectory?.trim() ?? '';

    final missingPaths = patchModel.acpi.acpiAddItems
        .map((item) => item.path)
        .where((itemPath) =>
            !assets.contains('assets/acpi/$itemPath') &&
            !_externalAcpiExists(sourceDirectory, itemPath))
        .toSet();
    if (missingPaths.isEmpty) return;

    patchModel.acpi.acpiAddItems
        .removeWhere((item) => missingPaths.contains(item.path));
    persistedModel.acpi.acpiAddItems
        .removeWhere((item) => missingPaths.contains(item.path));

    for (final path in missingPaths) {
      Log('静态 ACPI 资源不存在，已跳过: assets/acpi/$path');
    }
  }

  bool _externalAcpiExists(String sourceDirectory, String itemPath) {
    if (sourceDirectory.isEmpty || itemPath.isEmpty) return false;
    return File(path.join(sourceDirectory, itemPath)).existsSync();
  }

  Future<Set<String>?> _assetManifestAssets() {
    return _assetManifestCache ??= _loadAssetManifestAssets();
  }

  Future<Set<String>?> _loadAssetManifestAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().toSet();
    } catch (error) {
      Log('读取资源清单失败，跳过静态 ACPI 缺失检查: $error');
      return null;
    }
  }

  void preOptions() {
    final model = configService.configModel;
    if (configService.configModelMode != ConfigModelMode.process) {
      final editor = ConfigModelEditor(configService);
      final audioKext = [
        ConfigKernel.AppleALC,
        ConfigKernel.VoodooHDA,
      ].firstWhere(
        (kext) => configService.hasKext(kext),
        orElse: () => KernelKext(),
      );
      editor.updateSoundDriverType(
        audioKext.bundlePath.isEmpty ? null : audioKext,
        model.hpetPath,
        alcidPickerSelection: model.alcidPickerSelection,
      );
    }

    if (configService.useNootRXKext) {
      model.kernel.kernelKexts.removeWhere(
          (e) => e.bundlePath == ConfigKernel.WhateverGreen.bundlePath);
    }

    model.booter.booterQuirks.resizeAppleGpuBars =
        configService.resizeAppleGpuBarsToZero ? 0 : -1;

    if (configService.checkMacOSVersion() == 26) {
      if (!model.uefi.uefiDriversItems
          .any((e) => e.path == 'apfs_aligned.efi')) {
        model.uefi.uefiDriversItems.insert(
          0,
          UefiDriversItem(path: 'apfs_aligned.efi', enabled: true),
        );
      }

      if (configService.hasKext(ConfigKernel.LucyRTL8125Ethernet)) {
        if (model.kernel.kernelBlockItems != null &&
            !model.kernel.kernelBlockItems!.any((e) =>
                e.identifier == KernelPatch.fixLucy8125Ethernet.identifier)) {
          model.kernel.kernelBlockItems!.add(KernelPatch.fixLucy8125Ethernet);
        }
      } else {
        model.kernel.kernelBlockItems?.removeWhere(
            (e) => e.identifier == KernelPatch.fixLucy8125Ethernet.identifier);
      }
    } else {
      model.uefi.uefiDriversItems
          .removeWhere((e) => e.path == 'apfs_aligned.efi');
    }
  }

  Set<String> get managedOtherSSDTPaths =>
      managedOtherSSDTs.map((item) => item.path).toSet();

  List<IgpuPropertyModel> addOtherDeviceProperties() {
    if (!configService.isIntel) return const [];

    if (configService.mixedCPUWithIvyBridge) {
      return [_cloneIgpuProperty(ConfigDp.intel_desktop_imei_3th)];
    }
    if (configService.mixedCPUWithSandyBridge) {
      return [_cloneIgpuProperty(ConfigDp.intel_desktop_imei_2th)];
    }

    return const [];
  }

  IgpuPropertyModel _cloneIgpuProperty(IgpuPropertyModel model) {
    return model.copyWith(
      propertyItems:
          model.propertyItems.map((item) => item.copyWith()).toList(),
    );
  }

  List<AcpiAddItem> addOtherSSDTs() {
    final model = configService.configModel;
    final otherSSDTs = <AcpiAddItem>[];
    if (configService.mixedCPUWithMainboard) {
      otherSSDTs.add(ConfigAcpi.SSDT_IMEI);
    }
    if (configService.hasKext(ConfigKernel.NullEthernet)) {
      otherSSDTs.add(ConfigAcpi.SSDT_RMNE);
    }
    if (configService.hasKext(ConfigKernel.SMCLightSensor)) {
      otherSSDTs.add(ConfigAcpi.SSDT_ALS0);
    }
    if (configService.isAMD &&
        model.specialMotherboard == SpecialMotherboard.amdB550A520) {
      otherSSDTs.add(ConfigAcpi.SSDT_CPUR);
    }
    if ((configService.isIntel && model.platformRank >= 6) &&
        (model.brand == Brand.asus || model.brand == Brand.msi)) {
      otherSSDTs.add(ConfigAcpi.SSDT_RHUB);
    }

    return otherSSDTs;
  }

  List<KernelKext> addOtherKexts() {
    final model = configService.configModel;
    final otherKexts = <KernelKext>[];
    final macOSVersion = configService.checkMacOSVersion();

    if (macOSVersion > 12) {
      if (configService.isIntel) {
        if (configService.isHEDT) {
          if (model.platformRank < 3 || model.pentiumOrCeleron) {
            otherKexts.add(ConfigKernel.CryptexFixup);
          }
        } else if (configService.isNuc) {
          if (model.platformRank < 4 || model.pentiumOrCeleron) {
            otherKexts.add(ConfigKernel.CryptexFixup);
          }
          if (model.platformRank < 1) {
            otherKexts.add(ConfigKernel.NoAVXFSCompressionTypeZlibAVXpel);
          }
        } else if (configService.isDesktop || configService.isLaptop) {
          if (model.platformRank < 4 || model.pentiumOrCeleron) {
            otherKexts.add(ConfigKernel.CryptexFixup);
          }
          if (model.platformRank < 1) {
            otherKexts.add(ConfigKernel.NoAVXFSCompressionTypeZlibAVXpel);
          }
        }
      } else if (model.platformRank < 1 && !configService.isHEDT) {
        otherKexts.add(ConfigKernel.CryptexFixup);
      }
    }

    if (configService.isAMD ||
        (model.platformInfo.generic != null &&
            model.platformInfo.generic!.systemProductName.nullSafe
                .contains('MacPro')) ||
        model.processorType != ProcessorType.none ||
        BootArgsAccessor.contains(model, ConfigNvram.revpatch_sbvmm.arg)) {
      otherKexts.add(ConfigKernel.RestrictEvents);
    }

    if (configService.isAMD ||
        (model.platformInfo.generic != null &&
            model.platformInfo.generic!.systemProductName.nullSafe
                .contains('MacPro'))) {
      otherKexts.add(ConfigKernel.AppleMCEReporterDisabler);
    }

    if (configService.isAMD && AmdSettingsAccessor.usesRyzenGpu(model)) {
      otherKexts.add(ConfigKernel.NootedRed);
    }

    final selectedKexts = configService.selectedKexts();
    bool hasSelected(KernelKext kext) =>
        selectedKexts.any((e) => e.bundlePath == kext.bundlePath);

    final intelWifiKexts = [
      ConfigKernel.itlwm,
      ConfigKernel.AirportItlwm_Sequoia,
      ConfigKernel.AirportItlwm_Sonoma_14_4,
      ConfigKernel.AirportItlwm_Sonoma,
      ConfigKernel.AirportItlwm_Ventura,
      ConfigKernel.AirportItlwm_Monterey,
      ConfigKernel.AirportItlwm_BigSur,
      ConfigKernel.AirportItlwm_Catalina,
      ConfigKernel.AirportItlwm_Mojave,
      ConfigKernel.AirportItlwm_HighSierra,
    ];
    if (intelWifiKexts.any(hasSelected)) {
      if (hasSelected(ConfigKernel.AirportItlwm_Sequoia)) {
        otherKexts.addAll([
          ConfigKernel.IOSkywalkFamily.copyWith(minKernel: '24.0.0'),
          ConfigKernel.IO80211FamilyLegacy.copyWith(minKernel: '24.0.0'),
        ]);
      }
      otherKexts.add(ConfigKernel.IntelBluetoothFirmware);
      if (macOSVersion >= 12) {
        otherKexts.addAll([
          ConfigKernel.BlueToolFixup,
          ConfigKernel.IntelBTPatcher,
        ]);
      }
      if (macOSVersion <= 11) {
        otherKexts.add(ConfigKernel.IntelBluetoothInjector);
      }
    }

    final hasBcm943xx = hasSelected(ConfigKernel.AirportBrcmFixup);
    final hasBcm4331 = hasSelected(ConfigKernel.IO80211ElCap_AirPortBrcm4331);
    final hasBcm43224 =
        hasSelected(ConfigKernel.IO80211ElCap_AppleAirPortBrcm43224);
    if (hasBcm943xx || hasBcm4331 || hasBcm43224) {
      if (macOSVersion >= 12) {
        otherKexts.add(ConfigKernel.BlueToolFixup);
      }
      if (macOSVersion <= 11) {
        otherKexts.add(ConfigKernel.BrcmBluetoothInjector);
      }
      otherKexts.add(ConfigKernel.BrcmFirmwareData);
      if (macOSVersion <= 10) {
        otherKexts.add(ConfigKernel.BrcmPatchRAM2);
      }
      if (macOSVersion >= 10) {
        otherKexts.add(ConfigKernel.BrcmPatchRAM3);
      }
      if (hasBcm943xx) {
        if (macOSVersion > 13) {
          otherKexts.addAll([
            ConfigKernel.IOSkywalkFamily,
            ConfigKernel.IO80211FamilyLegacy,
            ConfigKernel.IO80211FamilyLegacyAirPortBrcmNIC,
          ]);
        }
      } else if (hasBcm4331) {
        otherKexts.addAll([
          ConfigKernel.corecaptureElCap,
          ConfigKernel.IO80211ElCap,
          ConfigKernel.IO80211ElCap_AirPortBrcm4331,
        ]);
      } else if (hasBcm43224) {
        otherKexts.addAll([
          ConfigKernel.corecaptureElCap,
          ConfigKernel.IO80211ElCap,
          ConfigKernel.IO80211ElCap_AppleAirPortBrcm43224,
        ]);
      }
    }

    final atherosWifiKexts = ConfigKextGroups.atherosWifiModels.kexts;
    if (atherosWifiKexts.any(hasSelected)) {
      otherKexts.addAll([
        ConfigKernel.Ath3kBT,
        ConfigKernel.Ath3kBTInjector,
      ]);
      if (macOSVersion <= 11) {
        otherKexts.addAll(ConfigKextGroups.atherosWifiLegacySupport.kexts);
      } else {
        otherKexts.addAll(ConfigKextGroups.atherosWifiModernSupport.kexts);
      }
    }

    if (hasSelected(ConfigKernel.IntelBluetoothFirmware)) {
      if (macOSVersion >= 12) {
        otherKexts.addAll([
          ConfigKernel.BlueToolFixup,
          ConfigKernel.IntelBTPatcher,
        ]);
      }
      if (macOSVersion <= 11) {
        otherKexts.add(ConfigKernel.IntelBluetoothInjector);
      }
    } else if (hasSelected(ConfigKernel.BrcmFirmwareData)) {
      if (macOSVersion >= 12) {
        otherKexts.add(ConfigKernel.BlueToolFixup);
      }
      if (macOSVersion <= 11) {
        otherKexts.add(ConfigKernel.BrcmBluetoothInjector);
      }
      if (macOSVersion <= 10) {
        otherKexts.add(ConfigKernel.BrcmPatchRAM2);
      }
      if (macOSVersion >= 10 && macOSVersion <= 11) {
        otherKexts.add(
          ConfigKernel.BrcmPatchRAM3.copyWith(maxKernel: '20.99.99'),
        );
      }
    } else if (hasSelected(ConfigKernel.Ath3kBT)) {
      otherKexts.addAll([
        ConfigKernel.Ath3kBT,
        ConfigKernel.Ath3kBTInjector,
      ]);
    } else if (hasSelected(ConfigKernel.BlueToolFixup)) {
      otherKexts.add(ConfigKernel.BlueToolFixup);
    }

    return otherKexts;
  }

  Future<void> updateSMBIOS() async {
    final model = configService.configModel;
    if (model.platformInfo.generic != null &&
        model.platformInfo.generic!.systemProductName.isEmpty) {
      final platformInfoGenerics = Configs()
          .configsRepository
          .getPlatformModel(
            model.cpuType,
            model.platformType,
          )!
          .platforms[model.platformCode]!
          .smbiosOptions;
      final recommended = SMBIOSCompatibility.recommendForDarwinMajor(
            platformInfoGenerics,
            model.darwinMajorVersion,
            current: model.platformInfo.generic,
          ) ??
          platformInfoGenerics.first;
      model.platformInfo.generic = recommended.copyWith(
        processorType: model.platformInfo.generic!.processorType,
      );
    }
    if (model.platformInfo.generic != null &&
        model.platformInfo.generic!.systemSerialNumber.isEmpty) {
      model.platformInfo.generic =
          await SMBIOSUtils.generate(model.platformInfo.generic!);
    }
  }
}
