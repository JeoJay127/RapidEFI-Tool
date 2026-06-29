import 'package:flutter/foundation.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/accessors/amd_settings_accessor.dart';
import 'package:rapidefi/utils/config/accessors/efi_driver_accessor.dart';
import 'package:rapidefi/utils/config/accessors/nvram/bluetooth_nvram_accessor.dart';
import 'package:rapidefi/utils/config/catalogs/bluetooth_nvram/bluetooth_nvram_option.dart';
import 'package:rapidefi/utils/config/catalogs/efi_drivers/efi_driver_option.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_patch_item.dart';
import 'package:rapidefi/utils/config/models/booter/booter_quirks.dart';
import 'package:rapidefi/utils/config/models/device_properties/device_property_item.dart';
import 'package:rapidefi/utils/config/models/device_properties/igpu_model.dart';
import 'package:rapidefi/utils/config/models/enums/brand_enum.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_emulate.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_quirks.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi_generic.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_drivers_item.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_output.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_quirks.dart';
import 'package:rapidefi/utils/config/presets/patches/acpi_patch.dart';
import 'package:rapidefi/utils/config/presets/sections/config_acpi.dart';
import 'package:rapidefi/utils/config/presets/sections/config_device_properties.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/services/config_session.dart';
import 'package:rapidefi/utils/config/services/config_service.dart';
import 'package:rapidefi/utils/config/support/platform_properties.dart';
import 'package:rapidefi/utils/config/support/surface_support.dart';
import 'package:rapidefi/utils/config/support/wifi_oclp_support.dart';

class ConfigModelEditor {
  ConfigModelEditor(this._configService);

  final ConfigService _configService;
  List<KernelKext>? _preSurfaceTouchPadKexts;

  ConfigModel get configModel => _configService.configModel;
  ConfigModel get originConfigModel => _configService.originConfigModel;

  void setConfigModel(ConfigModel model) =>
      _configService.setConfigModel(model);

  void setPentiumOrCeleron(bool value) {
    configModel.pentiumOrCeleron = value;

    if (value) {
      final hfsDriversItem = UefiDriversItem(
        path: configModel.platformRank <= 5
            ? 'HfsPlusLegacy.efi'
            : 'OpenHfsPlus.efi',
        enabled: true,
      );

      final index = configModel.uefi.uefiDriversItems
          .indexWhere((e) => e.path == 'HfsPlus.efi');

      if (index != -1) {
        configModel.uefi.uefiDriversItems[index] = hfsDriversItem;
      }
    } else {
      _configService.resetConfigScope(ConfigScope.uefiDrivers);
    }
  }

  void updatePentiumOrCeleronType(bool value) => setPentiumOrCeleron(value);

  void setCometLakeU62(bool value) {
    configModel.isCometLakeU62 = value;
  }

  void setMacOSVersion(String value) {
    configModel.macOSVersion = value;
  }

  void setDarwinMajorVersion(int value) {
    configModel.darwinMajorVersion = value;
  }

  void setPlatformInfoGeneric(
    PlatformInfoGeneric? value, {
    bool syncCpuFriendRecommendation = false,
  }) {
    configModel.platformInfo.generic = value;
    if (syncCpuFriendRecommendation) {
      KextAccessor.applyCpuFriendRecommendation(configModel);
    }
  }

  void setProvideCurrentCpuInfo(bool value) {
    configModel.kernel.kernelQuirks.provideCurrentCpuInfo = value;
  }

  void setUsesRyzenGpu(bool value) {
    AmdSettingsAccessor.setUsesRyzenGpu(configModel, value);
  }

  void setUtbMapPath(String? value) {
    _configService.utbMapPath = value;
  }

  void setOutputDirectory(String value) {
    _configService.outputDirectory = value;
  }

  set outputDirectory(String value) => setOutputDirectory(value);

  void setEdid(String value) {
    configModel.edid = value;
  }

  void setEdidOverride(int connectorIndex, String value) {
    DevicePropertiesAccessor.setEdidOverride(configModel, connectorIndex, value);
  }

  void replaceKexts(
    Iterable<KernelKext> removableKexts,
    Iterable<KernelKext> selectedKexts,
  ) {
    KextAccessor.replaceKexts(configModel, removableKexts, selectedKexts);
  }

  void addKexts(Iterable<KernelKext> kexts) {
    KextAccessor.addKexts(configModel, kexts);
  }

  void removeKexts(Iterable<KernelKext> kexts) {
    KextAccessor.removeKexts(configModel, kexts);
  }

  void updateDeviceProperties(List<IgpuPropertyModel>? addList) {
    configModel.deviceProperties.addList = addList;
    if (addList == null || addList.isEmpty) {
      DevicePropertiesAccessor.replaceIGPUProperties(configModel, {});
      return;
    }

    IgpuPropertyModel? igpuPropertyModel;
    for (final item in addList) {
      if (item.pciPath == ConfigDp.pciPath) {
        igpuPropertyModel = item;
        break;
      }
    }

    if (igpuPropertyModel == null) {
      DevicePropertiesAccessor.replaceIGPUProperties(configModel, {});
      return;
    }

    final display = igpuPropertyModel.propertyItems.any((e) => e.display);
    if (!display || configModel.platformRank <= 2) {
      DevicePropertiesAccessor.replaceIGPUProperties(configModel, {});
    } else {
      DevicePropertiesAccessor.replaceIGPUProperties(configModel, {
        framebuffer_stolenmem_1k,
        framebuffer_unifiedmem_2048,
      });
    }
  }

  Set<DevicePropertyItem> selectedIGPUDeviceProperties() =>
      DevicePropertiesAccessor.selectedIGPUProperties(configModel);

  void updateIGPUDeviceProperties(Set<DevicePropertyItem> selectedItems) =>
      DevicePropertiesAccessor.replaceIGPUProperties(
          configModel, selectedItems);

  void updateIntelConnectorAllData(int connectorIndex, String value) =>
      DevicePropertiesAccessor.setIntelConnectorAllData(
        configModel,
        connectorIndex,
        value,
      );

  void updateBrand(Brand brand) {
    final previousBrand = configModel.brand;
    configModel.brand = brand;
    configModel.kernel.kernelQuirks.lapicKernelPanic =
        configModel.brand == Brand.hp;
    configModel.platformInfo.updateSMBIOSMode =
        (configModel.brand == Brand.dell || configModel.brand == Brand.vaio)
            ? 'Custom'
            : 'Create';
    configModel.kernel.kernelQuirks.customSMBIOSGuid =
        configModel.brand == Brand.dell || configModel.brand == Brand.vaio;
    configModel.uefi.uefiQuirks.unblockFsConnect =
        configModel.brand == Brand.hp;

    if (configModel.brand == Brand.msi) {
      configModel.booter.booterQuirks.protectUefiServices = true;
    } else {
      configModel.booter.booterQuirks.protectUefiServices =
          originConfigModel.booter.booterQuirks.protectUefiServices;
    }
    if (configModel.brand == Brand.chrome) {
      configModel.booter.booterQuirks.protectMemoryRegions = true;
      BootArgsAccessor.add(configModel, ConfigNvram.igfxnotelemetryload.arg);
    } else {
      configModel.booter.booterQuirks.protectMemoryRegions =
          originConfigModel.booter.booterQuirks.protectMemoryRegions;
      BootArgsAccessor.remove(configModel, ConfigNvram.igfxnotelemetryload.arg);
    }

    configModel.uefi.uefiQuirks.disableSecurityPolicy =
        configModel.brand == Brand.microsoft;

    if (previousBrand != Brand.microsoft &&
        configModel.brand == Brand.microsoft) {
      _preSurfaceTouchPadKexts =
          SurfaceSupport.selectedTouchPadKexts(configModel)
              .where(
                (kext) =>
                    !ConfigKextGroups.bigSurface.kexts.contains(kext),
              )
              .toList();
      SurfaceSupport.apply(configModel);
    } else if (previousBrand == Brand.microsoft &&
        configModel.brand != Brand.microsoft) {
      final fallbackTouchPadKexts =
          (_preSurfaceTouchPadKexts?.isNotEmpty ?? false)
              ? _preSurfaceTouchPadKexts!
              : SurfaceSupport.selectedTouchPadKexts(originConfigModel);
      SurfaceSupport.restoreTouchPadSelection(configModel, fallbackTouchPadKexts);
      _preSurfaceTouchPadKexts = null;
    } else if (configModel.brand != Brand.microsoft) {
      SurfaceSupport.removeManagedSurfaceKexts(configModel);
    }
  }

  void updateRyzenMMIO(bool usePrecastMMIO) =>
      BooterMmioAccessor.setUsesPrecastMmio(configModel, usePrecastMMIO);

  void updateUEFISupprtOptions(bool legacy) {
    configModel.legacy = legacy;
    if (!_configService.isLaptop) {
      configModel.uefi.uefiDriversItems
          .removeWhere((e) => e.path == 'OpenUsbKbDxe.efi');
      if (legacy) {
        configModel.uefi.uefiDriversItems
            .add(UefiDriversItem(path: 'OpenUsbKbDxe.efi', enabled: true));
        configModel.uefi.uefiInput.keySupport = false;
      } else {
        configModel.uefi.uefiInput.keySupport = true;
      }
    }
  }

  void updateAMDOptions(SpecialMotherboard amdmlb, String amdCore) {
    configModel.specialMotherboard = amdmlb;
    AmdSettingsAccessor.setAmdCore(configModel, amdCore);
    if (amdmlb == SpecialMotherboard.amdB550A520 &&
        !configModel.acpi.acpiAddItems
            .any((item) => item.path == ConfigAcpi.SSDT_CPUR.path)) {
      configModel.acpi.acpiAddItems.add(ConfigAcpi.SSDT_CPUR.copyWith());
    }

    if (_configService.isAMD) {
      configModel.booter.booterQuirks.devirtualiseMmio =
          configModel.specialMotherboard == amdmlb;

      if (configModel.specialMotherboard == amdmlb ||
          configModel.specialMotherboard == SpecialMotherboard.amdB550A520 ||
          configModel.specialMotherboard == SpecialMotherboard.amdX470B450 ||
          configModel.specialMotherboard == SpecialMotherboard.amdX570) {
        configModel.booter.booterQuirks.setupVirtualMap = false;
      } else {
        configModel.booter.booterQuirks.setupVirtualMap =
            originConfigModel.booter.booterQuirks.setupVirtualMap;
      }
    }
  }

  void configFakeDGPU(String dgpuPath, String dgpuFakeID) =>
      DevicePropertiesAccessor.setDgpuFakeId(configModel, dgpuPath, dgpuFakeID);

  void updateSpecialMotherBoard(SpecialMotherboard specialMainBoard) {
    configModel.specialMotherboard = specialMainBoard;

    if (_configService.isIntel) {
      if (configModel.specialMotherboard == SpecialMotherboard.intelZ390 ||
          configModel.specialMotherboard == SpecialMotherboard.intelZ490 ||
          configModel.specialMotherboard == SpecialMotherboard.intelB460 ||
          configModel.brand == Brand.msi) {
        configModel.booter.booterQuirks.protectUefiServices = true;
      } else {
        configModel.booter.booterQuirks.protectUefiServices =
            originConfigModel.booter.booterQuirks.protectUefiServices;
      }

      if (configModel.specialMotherboard == SpecialMotherboard.intelOem) {
        configModel.uefi.uefiQuirks.releaseUsbOwnership = true;
      } else {
        configModel.uefi.uefiQuirks.releaseUsbOwnership =
            originConfigModel.uefi.uefiQuirks.releaseUsbOwnership;
      }
    }
  }

  void updateAcpiPatchItems(List<AcpiPatchItem> selectedPatches) {
    final currentPatches =
        List<AcpiPatchItem>.from(configModel.acpi.acpiPatchItems);

    bool samePatch(AcpiPatchItem a, AcpiPatchItem b) {
      return listEquals(a.find, b.find) && listEquals(a.replace, b.replace);
    }

    currentPatches.removeWhere((current) {
      final isChoicePatch = AcpiPatch.patchChoicesList.any(
        (choice) => samePatch(current, choice),
      );

      final isSelected = selectedPatches.any(
        (selected) => samePatch(current, selected),
      );

      return isChoicePatch && !isSelected;
    });

    for (final selected in selectedPatches) {
      final exists = currentPatches.any(
        (current) => samePatch(current, selected),
      );

      if (!exists) {
        currentPatches.add(selected.copyWith());
      }
    }

    configModel.acpi.acpiPatchItems = currentPatches;
  }

  void updateExtraSSDTs(List<AcpiAddItem> extraSSDTs) {
    final fixPaths = ConfigAcpi.fixSSDTs.map((e) => e.path).toSet();
    final ssdts = configModel.acpi.acpiAddItems
        .where((e) => !fixPaths.contains(e.path))
        .toList()
      ..addAll(extraSSDTs);
    final patches = configModel.acpi.acpiPatchItems;

    final hasSSDTGprw = ssdts.any((e) => e.path == ConfigAcpi.SSDT_GPRW.path);
    final gprwPatchIndex = patches
        .indexWhere((e) => e.comment == AcpiPatch.rename_GPRW_To_XPRW.comment);

    if (hasSSDTGprw && gprwPatchIndex == -1) {
      patches.add(AcpiPatch.rename_GPRW_To_XPRW);
    } else if (!hasSSDTGprw && gprwPatchIndex != -1) {
      patches.removeAt(gprwPatchIndex);
    }

    final hasSSDTUprw = ssdts.any((e) => e.path == ConfigAcpi.SSDT_UPRW.path);
    final uprwPatchIndex = patches
        .indexWhere((e) => e.comment == AcpiPatch.rename_UPRW_To_XPRW.comment);

    if (hasSSDTUprw && uprwPatchIndex == -1) {
      patches.add(AcpiPatch.rename_UPRW_To_XPRW);
    } else if (!hasSSDTUprw && uprwPatchIndex != -1) {
      patches.removeAt(uprwPatchIndex);
    }

    configModel.acpi.acpiAddItems = ssdts;
    configModel.acpi.acpiPatchItems = patches;
  }

  void updateBooterQuirks(BooterQuirks booterQuirks) {
    final updated = booterQuirks.toEBQuirksMap();
    final current = configModel.booter.booterQuirks.toQuirksMap();

    updated.forEach((key, value) {
      current[key] = value;
    });
    configModel.booter.booterQuirks = BooterQuirks.fromJson(current);
  }

  void updateKernelEmulate(KernelEmulate kernelEmulate) =>
      configModel.kernel.kernelEmulate = kernelEmulate;

  void updateUEFIOutput(UefiOutput uefiOutput) =>
      configModel.uefi.uefiOutput = uefiOutput;

  void updateUEFIQuirks(UefiQuirks uefiQuirks) =>
      configModel.uefi.uefiQuirks = uefiQuirks;

  void updateHfsDriverByPath(String driverPath) {
    EfiDriverAccessor.updateDriverByCategory(
      configModel,
      _configService.efiDriverCatalog,
      'hfs',
      driverPath,
    );
  }

  EfiDriverOption? selectedHfsDriverOption([ConfigModel? model]) {
    return EfiDriverAccessor.selectedOption(
      model ?? configModel,
      _configService.efiDriverCatalog,
      'hfs',
    );
  }

  void updateKernelQuirks(KernelQuirks kernelQuirks) {
    final updated = kernelQuirks.toQuirksMap();
    final current = configModel.kernel.kernelQuirks.toQuirksMap();

    updated.forEach((key, value) {
      if (key != 'SetApfsTrimTimeout') {
        current[key] = value;
      }

      if (key == 'CustomSMBIOSGuid') {
        configModel.platformInfo.updateSMBIOSMode = value ? 'Custom' : 'Create';
      }
    });
    configModel.kernel.kernelQuirks = KernelQuirks.fromJson(current);
  }

  void updateSetApfsTrimTimeoutValue(int setApfsTrimTimeout) =>
      configModel.kernel.kernelQuirks.setApfsTrimTimeout = setApfsTrimTimeout;

  void updateCSRSetting(CsrSetting csrsetting) {
    NvramSettingsAccessor.setCsrSetting(configModel, csrsetting);
    if (csrsetting.needsAmfiBypass) {
      WifiOclpSupport.ensureAmfiBypass(configModel);
    } else {
      WifiOclpSupport.clearAmfiBypass(configModel);
    }
  }

  void updateUIScale(UIScale uiScale) =>
      NvramSettingsAccessor.setUiScale(configModel, uiScale);

  void updateProcessorType(ProcessorType processorType, String cpuName) {
    configModel.processorType = processorType;
    NvramSettingsAccessor.setCustomCpuName(configModel, cpuName);
    if (processorType != ProcessorType.none) {
      configModel.platformInfo.generic?.processorType = processorType.value;
    } else {
      configModel.platformInfo.generic?.processorType = 0;
    }
  }

  void updateReleaseUsbOwnership(bool value) =>
      configModel.uefi.uefiQuirks.releaseUsbOwnership = value;

  void updateSoundDriverType(
    KernelKext? soundDriverType,
    String hpetPath, {
    List<Object>? alcidPickerSelection,
  }) {
    final alcid = _alcidFromSelection(alcidPickerSelection) ??
        BootArgsAccessor.getAlcid(configModel) ??
        1;
    replaceKexts(
      [ConfigKernel.AppleALC, ConfigKernel.VoodooHDA],
      soundDriverType == null || soundDriverType.bundlePath.isEmpty
          ? []
          : [soundDriverType],
    );
    BootArgsAccessor.removeWhere(
      configModel,
      (arg) => arg.startsWith('alcid='),
    );

    if (soundDriverType?.bundlePath == ConfigKernel.AppleALC.bundlePath) {
      configModel.alcidPickerSelection = alcidPickerSelection ?? ['', '', alcid];
      BootArgsAccessor.setAlcid(configModel, alcid);
      if (hpetPath.trim().isNotEmpty) {
        AcpiPatchAccessor.setHpetPatch(configModel, path: hpetPath.trim());
      } else {
        AcpiPatchAccessor.removeHpetPatch(configModel);
      }
    } else {
      configModel.alcidPickerSelection = null;
      AcpiPatchAccessor.removeHpetPatch(configModel);
    }
  }

  int? _alcidFromSelection(List<Object>? selection) {
    if (selection == null || selection.length < 3) {
      return null;
    }

    final value = selection[2];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  void updateUSBWiFiType(bool enabled) =>
      KextAccessor.setUsesUsbWifi(configModel, enabled);

  void updateWifiTypes(List<KernelKext> wifiTypes) {
    _syncWifiOclpSupport(
      wifiTypes,
      clearWhenNotRequired: true,
    );

    checkBluetoothNvramBootArgs(wifiTypes);
  }

  void updateBluetoothNvramOption(String? optionId) {
    if (optionId == null || optionId.isEmpty) {
      BluetoothNvramAccessor.removeOption(configModel);
      return;
    }
    final option = _configService.bluetoothInternalControllerInfoOptions
        .where((option) => option.id == optionId)
        .firstOrNull;
    if (option != null) {
      BluetoothNvramAccessor.setOption(configModel, option);
    }
  }

  BluetoothNvramOption? selectedBluetoothNvramOption([ConfigModel? model]) {
    return BluetoothNvramAccessor.selectedOption(
      model ?? configModel,
      _configService.bluetoothInternalControllerInfoOptions,
    );
  }

  void checkBluetoothNvramBootArgs(List<KernelKext> wifiTypes) {
    final hasWifi = _hasSelectedWifi(wifiTypes);
    final addList =
        configModel.nvram.nvramAdd.addList ??= ConfigNvram.createAddList();
    final entry =
        addList[ConfigNvram.UUID_7C436110_AB2A_4BBB_A880_FE41995C9F82] ??= [];

    if (hasWifi) {
      if (!entry.any(
        (e) => e.key == ConfigNvram.bluetoothExternalDongleFailed.key,
      )) {
        entry.add(ConfigNvram.bluetoothExternalDongleFailed);
      }
      if (!entry.any(
        (e) => e.key == ConfigNvram.bluetoothInternalControllerInfo.key,
      )) {
        entry.add(ConfigNvram.bluetoothInternalControllerInfo);
      }
      return;
    }

    entry.removeWhere(
      (e) => e.key == ConfigNvram.bluetoothExternalDongleFailed.key,
    );
    entry.removeWhere(
      (e) => e.key == ConfigNvram.bluetoothInternalControllerInfo.key,
    );
  }

  bool _hasSelectedWifi(List<KernelKext> wifiTypes) {
    final selectedBundlePaths =
        wifiTypes.map((kext) => kext.bundlePath).toSet();
    return _wifiSelectionKexts.any(
      (kext) => selectedBundlePaths.contains(kext.bundlePath),
    );
  }

  List<KernelKext> get _wifiSelectionKexts => [
        ConfigKernel.AirportItlwm_Sequoia,
        ConfigKernel.AirportItlwm_Sonoma_14_4,
        ConfigKernel.AirportItlwm_Sonoma,
        ConfigKernel.AirportItlwm_Ventura,
        ConfigKernel.AirportItlwm_Monterey,
        ConfigKernel.AirportItlwm_BigSur,
        ConfigKernel.AirportItlwm_Catalina,
        ConfigKernel.AirportItlwm_Mojave,
        ConfigKernel.AirportItlwm_HighSierra,
        ConfigKernel.itlwm,
        ...ConfigKextGroups.brcm943xx.kexts,
        ...ConfigKextGroups.brcm4331.kexts,
        ...ConfigKextGroups.brcm43224.kexts,
        ...ConfigKextGroups.atherosWifiModels.kexts,
      ];

  void syncWifiOclpSupportForCurrentSelection() {
    final wifiTypes =
        KextAccessor.selectedKextsIn(configModel, _wifiSelectionKexts);
    if (wifiTypes.isEmpty) return;

    _syncWifiOclpSupport(
      wifiTypes,
      clearWhenNotRequired: true,
    );
  }

  void _syncWifiOclpSupport(
    List<KernelKext> wifiTypes, {
    bool clearWhenNotRequired = false,
  }) {
    WifiOclpSupport.applyToModel(
      configModel,
      selectedKexts: wifiTypes,
      clearWhenNotRequired: clearWhenNotRequired,
    );
  }
}
