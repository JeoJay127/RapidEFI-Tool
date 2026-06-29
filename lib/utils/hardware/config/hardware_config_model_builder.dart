import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/enums/brand_enum.dart';
import 'package:rapidefi/utils/config/models/enums/cpu_type_enum.dart';
import 'package:rapidefi/utils/config/models/enums/motherboard_enum.dart';
import 'package:rapidefi/utils/config/models/enums/platform_type_enum.dart';
import 'package:rapidefi/utils/config/models/device_properties/device_property_item.dart';
import 'package:rapidefi/utils/config/models/device_properties/igpu_model.dart';
import 'package:rapidefi/utils/config/models/kernel/kext_group.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/sections/config_device_properties.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_configs.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/services/apple_alc_resolver.dart';
import 'package:rapidefi/utils/config/support/surface_support.dart';
import 'package:rapidefi/utils/config/support/wifi_oclp_support.dart';
import 'package:rapidefi/utils/hardware/analysis/gpu_compatibility_data.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis.dart';
import 'package:rapidefi/utils/hardware/config/hardware_config_build_context.dart';
import 'package:rapidefi/utils/hardware/config/hardware_config_kext_resolver.dart';
import 'package:rapidefi/utils/hardware/config/hardware_config_options.dart';
import 'package:rapidefi/utils/hardware/config/hardware_platform_resolver.dart';
import 'package:rapidefi/utils/hardware/data/hardware_device_data.dart';
import 'package:rapidefi/utils/hardware/model/allinfo.dart';

typedef HardwareConfigStageApplier = void Function(
  HardwareConfigBuildContext context,
  ConfigModel model,
);

class HardwareConfigStage {
  const HardwareConfigStage({
    required this.id,
    required this.apply,
  });

  final String id;
  final HardwareConfigStageApplier apply;
}

class HardwareConfigModelBuilder {
  const HardwareConfigModelBuilder({
    required this.hardwareInfo,
    required this.rawInfo,
  });

  final HardwareAllInfo hardwareInfo;
  final Map<String, dynamic>? rawInfo;
  static const _kextResolver = HardwareConfigKextResolver();

  Future<ConfigModel> buildAsync({
    HardwareConfigOptions options = const HardwareConfigOptions(),
  }) async {
    await GpuCompatibilityData.ensureLoaded();
    return build(options: options);
  }

  ConfigModel build({
    HardwareConfigOptions options = const HardwareConfigOptions(),
  }) {
    final context = HardwareConfigBuildContext(
      hardwareInfo: hardwareInfo,
      rawInfo: rawInfo,
      options: options,
    );

    final model = _resolveBaseModel(context);
    for (final stage in _stages) {
      stage.apply(context, model);
    }

    return model;
  }

  Iterable<HardwareConfigStage> get _stages => [
        HardwareConfigStage(
          id: 'personalized_options',
          apply: _applyPersonalizedOptions,
        ),
        HardwareConfigStage(id: 'cpu', apply: _applyCpuConfiguration),
        HardwareConfigStage(
          id: 'motherboard',
          apply: _applyMotherboardConfiguration,
        ),
        HardwareConfigStage(
          id: 'integrated_gpu',
          apply: _applyIntegratedGpuConfiguration,
        ),
        HardwareConfigStage(
          id: 'discrete_gpu',
          apply: _applyDiscreteGpuConfiguration,
        ),
        HardwareConfigStage(id: 'audio', apply: _applyAudioConfiguration),
        HardwareConfigStage(
          id: 'ethernet',
          apply: _applyEthernetConfiguration,
        ),
        HardwareConfigStage(id: 'wifi', apply: _applyWifiConfiguration),
        HardwareConfigStage(id: 'sd_card', apply: _applySdCardConfiguration),
        HardwareConfigStage(id: 'storage', apply: _applyStorageConfiguration),
        HardwareConfigStage(
          id: 'controller_kexts',
          apply: _applyControllerKextConfiguration,
        ),
        HardwareConfigStage(
          id: 'built_in_devices',
          apply: _applyBuiltInDeviceProperties,
        ),
        HardwareConfigStage(id: 'touchpad', apply: _applyTouchpadConfiguration),
        HardwareConfigStage(id: 'surface', apply: _applySurfaceConfiguration),
      ];

  ConfigModel _resolveBaseModel(HardwareConfigBuildContext context) {
    final selection = const HardwarePlatformResolver().resolve(context);
    return Configs().configsRepository.createWithPlatformCode(
          cpuType: selection.cpuType,
          platformType: selection.platformType,
          platformCode: selection.platformCode,
        );
  }

  void _applyCpuConfiguration(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    final rawInfo = context.rawInfoMap;
    final lacksAvx2 = !cpuHasAvx2(rawInfo);
    final requiresVenturaAvx2Workaround =
        lacksAvx2 && model.darwinMajorVersion > 21;

    model.pentiumOrCeleron = isEntryIntelCpu(rawInfo);

    if (!requiresVenturaAvx2Workaround) return;

    _addKexts(model, [ConfigKernel.CryptexFixup]);

    if (_hasDiscreteAmdVenturaLegacyGpu(rawInfo)) {
      BootArgsAccessor.add(model, ConfigNvram.amd_no_dgpu_accel.arg);
    }
  }

  void _applyMotherboardConfiguration(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    final boardText = _motherboardSearchText(context);

    model.brand = _resolveMotherboardBrand(boardText);
    model.specialMotherboard = _resolveSpecialMotherboard(
      boardText,
      cpuType: model.cpuType,
      platformCode: model.platformCode,
    );
  }

  void _applyIntegratedGpuConfiguration(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    final integratedGpus = _integratedGpuEntries(context).toList();
    if (integratedGpus.isEmpty) return;

    for (final entry in integratedGpus) {
      final gpu = safeMap(entry.value);
      final manufacturer = _gpuManufacturerForRules(gpu).toLowerCase();

      if (manufacturer.contains('amd') &&
          HardwareDeviceData.isNootedRedSupportedDeviceId(
            safeStr(gpu['Device ID']),
          )) {
        _addKexts(model, [ConfigKernel.NootedRed]);
        continue;
      }

      if (!manufacturer.contains('intel')) continue;
      if (model.cpuType != CpuType.intel ||
          model.platformType == PlatformType.hedt) {
        continue;
      }
      if (isEntryIntelCpu(context.rawInfoMap)) continue;

      final selected = _selectIntegratedIntelGpuMode(
        context,
        model,
        gpuName: entry.key,
      );
      if (selected.isEmpty) continue;

      _addKexts(model, [ConfigKernel.WhateverGreen]);
      _mergeDeviceProperties(
        model,
        selected,
        preferredPciPath: safeStr(gpu['PCI Path']),
        replaceExisting: _isComputeOnlyMode(selected),
      );
      _applyIntegratedGpuDisplayTweaks(context, model, entry.key, gpu);
    }
  }

  void _applyDiscreteGpuConfiguration(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    for (final entry in hardwareDevices(context.rawInfoMap['GPU'])) {
      final gpu = safeMap(entry.value);
      if (!_isDiscreteGpu(entry.key, gpu)) continue;

      final ruleText = _gpuRuleText(entry.key, gpu).toLowerCase();
      final name = _gpuDisplayNameForRules(entry.key, gpu).toLowerCase();

      if (ruleText.contains('gcn')) {
        BootArgsAccessor.add(model, ConfigNvram.radpg15.arg);
      }

      if (ruleText.contains('navi') || ruleText.contains('rdna')) {
        BootArgsAccessor.add(model, ConfigNvram.agdpmod_pikera.arg);
      }

      if (model.darwinMajorVersion >= 18 &&
          _isLegacyNvidiaCodename(ruleText)) {
        BootArgsAccessor.add(
          model,
          ConfigNvram.ngfxcompat_ngfxgl_nvda_drv_vrl.arg,
        );
      }

      if (name.contains('rx 6700')) {
        _addKexts(model, [ConfigKernel.NootRX]);
      }
    }
  }

  void _applyAudioConfiguration(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    final layout = context.audioLayout(
      preferredLayout: context.options.alcLayoutId,
    );
    if (layout == null) return;

    _addKexts(model, [ConfigKernel.AppleALC]);
    BootArgsAccessor.setAlcid(model, layout.selectedLayout);
    model.alcidPickerSelection =
        AppleALCResolver.selectionForModelLayout(
          layout.model,
          layout.selectedLayout,
        ) ??
        [
          '',
          layout.model,
          layout.selectedLayout,
        ];
  }

  void _applyEthernetConfiguration(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    final selected = <KernelKext>[];

    for (final entry in context.analyzedNetworkEntries) {
      if (entry.isWireless) continue;

      selected.addAll(
        _kextResolver.networkKexts(
          entry,
          darwinMajorVersion: model.darwinMajorVersion,
        ),
      );
      if (entry.requiresForceAquantiaEthernet) {
        model.kernel.kernelQuirks.forceAquantiaEthernet = true;
      }
    }

    _addKexts(model, selected);
  }

  void _applyWifiConfiguration(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    final selected = <KernelKext>[];

    for (final entry in context.analyzedNetworkEntries) {
      if (!entry.isWireless) continue;

      selected.addAll(
        _kextResolver.networkKexts(
          entry,
          darwinMajorVersion: model.darwinMajorVersion,
        ),
      );
    }

    _addKexts(model, selected);
    _applyWifiNvramRequirements(model, selected);
  }

  void _applySdCardConfiguration(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    final selected = <KernelKext>[];

    for (final entry in context.analyzedSdCardEntries) {
      if (entry.compatibility.level != CompatibilityLevel.supported) continue;

      selected.addAll(_kextResolver.sdCardKexts(entry));
    }

    _addKexts(model, selected);
  }

  void _applyStorageConfiguration(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    // 默认不添加 NVMeFix 驱动
    // final hasNvme = context.analyzedStorageControllerEntries.any(
    //   (entry) => entry.isNvme,
    // );

    // if (hasNvme) {
    //   _addKexts(model, [ConfigKernel.NVMeFix]);
    // }
  }

  void _applyControllerKextConfiguration(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    final unsupportedUsbIds = HardwareDeviceData.usbControllersNeedingLegacyXhci
        .map((id) => id.toUpperCase())
        .toSet();
    final unsupportedSataIds =
        HardwareDeviceData.sataControllersNeedingPortDriver
        .map((id) => id.toUpperCase())
        .toSet();

    final hasUnsupportedUsb = context.usbControllers.any(
      (controller) => unsupportedUsbIds.contains(
        _normalizeDeviceId(controller.deviceID),
      ),
    );
    if (hasUnsupportedUsb) {
      _addKexts(model, [ConfigKernel.XHCIUnsupported]);
    }

    final hasUnsupportedSata = context.storageControllers.any((controller) {
      final id = _normalizeDeviceId(controller.deviceID);
      if (!unsupportedSataIds.contains(id)) return false;

      final text = [
        controller.busType,
        controller.deviceID,
      ].whereType<String>().join(' ').toLowerCase();
      return !text.contains('nvme');
    });
    if (!hasUnsupportedSata) return;

    _addKexts(
      model,
      [
        model.darwinMajorVersion >= 20
            ? ConfigKernel.CtlnaAHCIPort
            : ConfigKernel.SATAUnsupported,
      ],
    );
  }

  void _applyBuiltInDeviceProperties(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    for (final entry in context.networkAdapterEntries) {
      _markBuiltInDevice(model, entry.key, entry.value.pciPath);
    }

    for (final entry in context.bluetoothDeviceEntries) {
      _markBuiltInDevice(model, entry.key, entry.value.pciPath);
    }

    for (final entry in context.storageControllerDeviceEntries) {
      _markBuiltInDevice(model, entry.key, entry.value.pciPath);
    }
  }

  void _applyTouchpadConfiguration(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    if (model.platformType != PlatformType.laptop) return;

    final deviceTypes = context.inputDeviceTypes;
    if (deviceTypes.isEmpty) return;

    final hasI2c = deviceTypes.any((type) => type.contains('i2c'));
    final hasRmi = deviceTypes.any((type) => type.contains('rmi'));
    final hasPs2 = deviceTypes.any((type) => type.contains('ps/2'));

    if (hasI2c) {
      _addKexts(model, ConfigKextGroups.voodooPs2ControllerWithI2c.kexts);
      return;
    }

    if (hasRmi) {
      _addKexts(model, ConfigKextGroups.voodooPs2ControllerWithRmi.kexts);
      return;
    }

    if (hasPs2) {
      final group = model.platformRank <= 2
          ? ConfigKextGroups.applePs2SmartTouchPad
          : ConfigKextGroups.voodooPs2Controller;
      _addKexts(model, group.kexts);
    }
  }

  void _applySurfaceConfiguration(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    if (!SurfaceSupport.matchesText(_motherboardSearchText(context))) return;
    SurfaceSupport.apply(model, includeBrightnessKeys: true);
  }

  void _applyPersonalizedOptions(
    HardwareConfigBuildContext context,
    ConfigModel model,
  ) {
    final options = context.options;

    final macOSVersion = options.macOSVersion;
    if (macOSVersion != null && macOSVersion.trim().isNotEmpty) {
      model.macOSVersion = macOSVersion;
    }

    final platformInfoGeneric = options.platformInfoGeneric;
    if (platformInfoGeneric != null) {
      model.platformInfo.generic = platformInfoGeneric;
    }

    if (options.enableNpci == true) {
      BootArgsAccessor.add(model, ConfigNvram.npci2000.arg);
    }
  }

  void _applyWifiNvramRequirements(
    ConfigModel model,
    Iterable<KernelKext> selected,
  ) {
    WifiOclpSupport.applyToModel(model, selectedKexts: selected);
    _ensureBluetoothNvramDefaults(model);
  }

  void _ensureBluetoothNvramDefaults(ConfigModel model) {
    final guid = ConfigNvram.UUID_7C436110_AB2A_4BBB_A880_FE41995C9F82;
    final addList = model.nvram.nvramAdd.addList ??= {};
    final items = addList[guid] ??= [];

    if (!items.any(
        (item) => item.key == ConfigNvram.bluetoothExternalDongleFailed.key)) {
      items.add(ConfigNvram.bluetoothExternalDongleFailed);
    }
    if (!items.any((item) =>
        item.key == ConfigNvram.bluetoothInternalControllerInfo.key)) {
      items.add(ConfigNvram.bluetoothInternalControllerInfo);
    }
  }

  void _addKexts(ConfigModel model, Iterable<KernelKext> kexts) {
    KextAccessor.addKexts(model, KextGroup.uniqueKexts(kexts));
  }

  Iterable<MapEntry<String, dynamic>> _integratedGpuEntries(
    HardwareConfigBuildContext context,
  ) {
    return hardwareDevices(context.rawInfoMap['GPU']).where((entry) {
      return _isIntegratedGpu(entry.key, safeMap(entry.value));
    });
  }

  bool _isIntegratedGpu(String name, Map<String, dynamic> gpu) {
    final type = safeStr(gpu['Device Type']).toLowerCase();
    if (type.contains('integrated') || type.contains('核心')) return true;
    if (type.contains('discrete') || type.contains('独立')) return false;

    final text = [
      name,
      safeStr(gpu['Name']),
      safeStr(gpu['DeviceDesc']),
      safeStr(gpu['Device Description']),
      safeStr(gpu['Description']),
      safeStr(gpu['Manufacturer']),
    ].join(' ').toLowerCase();

    final isIntelIgpu = text.contains('intel') &&
        (text.contains('hd graphics') ||
            text.contains('uhd graphics') ||
            text.contains('iris') ||
            text.contains('intel graphics') ||
            text.contains('intel(r) graphics'));
    final isAmdApu = text.contains('amd') &&
        (text.contains('radeon vega') ||
            text.contains('radeon rx vega') ||
            text.contains('radeon(tm) graphics') ||
            text.contains('radeon graphics'));

    return isIntelIgpu || isAmdApu;
  }

  List<IgpuPropertyModel> _selectIntegratedIntelGpuMode(
    HardwareConfigBuildContext context,
    ConfigModel model, {
    required String gpuName,
  }) {
    final platformModel = Configs().configsRepository.getPlatformModel(
          model.cpuType,
          model.platformType,
        );
    final modes = platformModel?.platforms[model.platformCode]?.igpuModes;
    if (modes == null || modes.isEmpty) return const [];

    final hasDiscreteGpu = _hasDiscreteGpu(context);
    final drivesDisplay = _integratedGpuDrivesDisplay(context, gpuName);
    final useComputeOnly = model.platformType != PlatformType.laptop &&
        _hasDrivableDiscreteGpu(context) &&
        _discreteGpuDrivesDisplay(context) &&
        !drivesDisplay;

    if (useComputeOnly) {
      return _firstModeWhere(modes, _isComputeOnlyMode) ??
          _firstModeWhere(modes, _isHeadlessOrDisabledMode) ??
          const [];
    }

    if (hasDiscreteGpu && !drivesDisplay) {
      return _firstModeWhere(modes, _isHeadlessOrDisabledMode) ?? modes.last;
    }

    return _firstModeWhere(modes, _modeHasDisplayOutput) ?? modes.first;
  }

  List<IgpuPropertyModel>? _firstModeWhere(
    List<List<IgpuPropertyModel>> modes,
    bool Function(List<IgpuPropertyModel> mode) test,
  ) {
    for (final mode in modes) {
      if (test(mode)) return mode;
    }
    return null;
  }

  bool _modeHasDisplayOutput(List<IgpuPropertyModel> mode) {
    return mode.any(
      (propertyModel) => propertyModel.propertyItems.any(
        (item) => item.display,
      ),
    );
  }

  bool _isComputeOnlyMode(List<IgpuPropertyModel> mode) {
    final igpuProperties = _igpuPropertyItems(mode);
    if (igpuProperties.isEmpty) return false;

    return igpuProperties.any((item) {
      final key = (item.key ?? '').toLowerCase();
      final value = (item.value ?? '').toLowerCase();
      if (!item.display &&
          value != '11223344' &&
          (key == 'aapl,ig-platform-id' ||
              key == 'aapl,snb-platform-id')) {
        return true;
      }

      return false;
    });
  }

  bool _isHeadlessOrDisabledMode(List<IgpuPropertyModel> mode) {
    final igpuProperties = _igpuPropertyItems(mode);
    if (igpuProperties.isEmpty) return false;

    return igpuProperties.every((item) => !item.display);
  }

  List<DevicePropertyItem> _igpuPropertyItems(List<IgpuPropertyModel> mode) {
    return mode
        .where((propertyModel) => propertyModel.pciPath == ConfigDp.pciPath)
        .expand((propertyModel) => propertyModel.propertyItems)
        .toList();
  }

  bool _hasDiscreteGpu(HardwareConfigBuildContext context) {
    return hardwareDevices(context.rawInfoMap['GPU']).any((entry) {
      return _isDiscreteGpu(entry.key, safeMap(entry.value));
    });
  }

  bool _hasDrivableDiscreteGpu(HardwareConfigBuildContext context) {
    return hardwareDevices(context.rawInfoMap['GPU']).any((entry) {
      final gpu = safeMap(entry.value);
      if (!_isDiscreteGpu(entry.key, gpu)) return false;
      final compatibility =
          gpuEntryCompatibility(context.rawInfoMap, entry.key, gpu);
      return compatibility.level != CompatibilityLevel.unsupported;
    });
  }

  bool _discreteGpuDrivesDisplay(HardwareConfigBuildContext context) {
    final monitors = hardwareDevices(context.rawInfoMap['Monitor']).toList();
    if (monitors.isEmpty) return false;

    final discreteGpus = hardwareDevices(context.rawInfoMap['GPU'])
        .where((entry) => _isDiscreteGpu(entry.key, safeMap(entry.value)))
        .toList();
    if (discreteGpus.isEmpty) return false;

    for (final entry in monitors) {
      final monitor = safeMap(entry.value);
      final connectedGpu = safeStr(monitor['Connected GPU']).toLowerCase();
      if (connectedGpu.isEmpty) continue;
      if (discreteGpus.any(
        (entry) => _gpuNameMatches(
          connectedGpu,
          entry.key,
          safeMap(entry.value),
        ),
      )) {
        return true;
      }
    }

    return false;
  }

  bool _integratedGpuDrivesDisplay(
    HardwareConfigBuildContext context,
    String gpuName,
  ) {
    final monitors = hardwareDevices(context.rawInfoMap['Monitor']).toList();
    if (monitors.isEmpty) return !_hasDiscreteGpu(context);

    for (final entry in monitors) {
      final monitor = safeMap(entry.value);
      final connectedGpu = safeStr(monitor['Connected GPU']).toLowerCase();
      if (connectedGpu.isEmpty) continue;
      if (_gpuNameMatches(
        connectedGpu,
        gpuName,
        safeMap(context.rawInfoMap['GPU']?[gpuName]),
      )) {
        return true;
      }
    }

    return false;
  }

  bool _gpuNameMatches(
    String connectedGpu,
    String fallbackName,
    Map<String, dynamic> gpu,
  ) {
    final aliases = [
      fallbackName,
      safeStr(gpu['Name']),
      safeStr(gpu['Device ID']),
      safeStr(gpu['DeviceDesc']),
      safeStr(gpu['Device Description']),
      safeStr(gpu['Description']),
      safeStr(gpu['Manufacturer']),
    ]
        .map((value) => value.toLowerCase().trim())
        .where((value) => value.isNotEmpty);

    return aliases.any(
      (alias) => connectedGpu == alias ||
          connectedGpu.contains(alias) ||
          alias.contains(connectedGpu),
    );
  }

  void _mergeDeviceProperties(
    ConfigModel model,
    Iterable<IgpuPropertyModel> propertyModels, {
    required String preferredPciPath,
    bool replaceExisting = false,
  }) {
    final igpuPath = preferredPciPath.trim().isEmpty
        ? ConfigDp.pciPath
        : preferredPciPath.trim();

    if (replaceExisting) {
      DevicePropertiesAccessor.getModel(model, ConfigDp.pciPath)
          ?.propertyItems
          .clear();
      DevicePropertiesAccessor.removeModelIfEmpty(model, ConfigDp.pciPath);
      if (igpuPath != ConfigDp.pciPath) {
        DevicePropertiesAccessor.getModel(model, igpuPath)
            ?.propertyItems
            .clear();
        DevicePropertiesAccessor.removeModelIfEmpty(model, igpuPath);
      }
    }

    for (final propertyModel in propertyModels) {
      final pciPath = propertyModel.pciPath == ConfigDp.pciPath
          ? igpuPath
          : propertyModel.pciPath;
      if (pciPath.trim().isEmpty) continue;

      for (final item in propertyModel.propertyItems) {
        DevicePropertiesAccessor.setProperty(model, pciPath, item.copyWith());
      }
    }
  }

  void _applyIntegratedGpuDisplayTweaks(
    HardwareConfigBuildContext context,
    ConfigModel model,
    String gpuName,
    Map<String, dynamic> gpu,
  ) {
    if (!_isIntel500SeriesDesktop(model, context)) return;

    final hdmiMonitors = _integratedGpuHdmiMonitors(context, gpuName, gpu);
    if (hdmiMonitors.isEmpty) return;

    final edid = hdmiMonitors.map(_monitorEdid).firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => '',
        );
    if (edid.isEmpty) return;

    DevicePropertiesAccessor.setEdidOverrides(model, edid);
  }

  bool _isIntel500SeriesDesktop(
    ConfigModel model,
    HardwareConfigBuildContext context,
  ) {
    if (model.cpuType != CpuType.intel ||
        model.platformType != PlatformType.desktop) {
      return false;
    }

    return _containsChipset(
      _motherboardSearchText(context),
      const ['h510', 'b560', 'h570', 'q570', 'z590', 'w580'],
    );
  }

  List<Map<String, dynamic>> _integratedGpuHdmiMonitors(
    HardwareConfigBuildContext context,
    String gpuName,
    Map<String, dynamic> gpu,
  ) {
    final monitors = <Map<String, dynamic>>[];
    for (final entry in hardwareDevices(context.rawInfoMap['Monitor'])) {
      final monitor = safeMap(entry.value);
      final connectorType = safeStr(monitor['Connector Type']).toLowerCase();
      if (!connectorType.contains('hdmi')) continue;

      final connectedGpu = safeStr(monitor['Connected GPU']).toLowerCase();
      if (connectedGpu.isNotEmpty &&
          !_gpuNameMatches(connectedGpu, gpuName, gpu)) {
        continue;
      }

      if (connectedGpu.isEmpty && _hasDiscreteGpu(context)) {
        continue;
      }

      monitors.add(monitor);
    }
    return monitors;
  }

  String _monitorEdid(Map<String, dynamic> monitor) {
    final edid = safeStr(monitor['EDID']).replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(edid)) return '';
    if (edid.length % 256 != 0) return '';
    return edid.toUpperCase();
  }

  void _markBuiltInDevice(
    ConfigModel model,
    String displayName,
    String? pciPath,
  ) {
    DevicePropertiesAccessor.markBuiltInDevice(
      model,
      pciPath: pciPath,
      displayName: displayName,
    );
  }

  bool _hasDiscreteAmdVenturaLegacyGpu(Map<String, dynamic> rawInfo) {
    for (final entry in hardwareDevices(rawInfo['GPU'])) {
      final gpu = safeMap(entry.value);
      if (!_isDiscreteGpu(entry.key, gpu)) continue;
      if (_isNaviOrPolarisCodename(_gpuRuleText(entry.key, gpu))) return true;
    }

    return false;
  }

  bool _isDiscreteGpu(String name, Map<String, dynamic> gpu) {
    final deviceId = GpuCompatibilityData.normalizeFullDeviceId(
      safeStr(gpu['Device ID']),
    ).toUpperCase();
    final type = safeStr(gpu['Device Type']).toLowerCase();
    if (type == 'integrated' ||
        type.contains('integrated') ||
        type.contains('核显') ||
        type.contains('核心')) {
      return false;
    }
    if (type == 'discrete' || type.contains('独立')) return true;

    final text = [
      name,
      safeStr(gpu['Name']),
      safeStr(gpu['DeviceDesc']),
      safeStr(gpu['Device Description']),
      safeStr(gpu['Description']),
      safeStr(gpu['Manufacturer']),
    ].join(' ').toLowerCase();

    if (deviceId.startsWith('1002-')) {
      final isAmdApu = HardwareDeviceData.isNootedRedSupportedDeviceId(
            deviceId,
          ) ||
          text.contains('radeon graphics') ||
          text.contains('radeon(tm) graphics') ||
          text.contains('radeon vega');
      return !isAmdApu;
    }
    if (deviceId.startsWith('10DE-')) return true;

    return text.contains('radeon rx') ||
        text.contains('radeon hd') ||
        text.contains('radeon r9') ||
        text.contains('radeon r7') ||
        text.contains('radeon pro') ||
        text.contains('firepro') ||
        text.contains('geforce') ||
        text.contains('quadro');
  }

  bool _isNaviOrPolarisCodename(String codename) {
    final normalized = codename.toLowerCase();
    return normalized.contains('navi') ||
        normalized.contains('baffin') ||
        normalized.contains('ellesmere') ||
        normalized.contains('polaris') ||
        normalized.contains('lexa') ||
        normalized.contains('vega');
  }

  bool _isLegacyNvidiaCodename(String codename) {
    final normalized = codename.toLowerCase();
    return normalized.contains('fermi') ||
        normalized.contains('maxwell') ||
        normalized.contains('pascal') ||
        RegExp(r'^gf\d').hasMatch(normalized) ||
        RegExp(r'^gm\d').hasMatch(normalized) ||
        RegExp(r'^gp\d').hasMatch(normalized);
  }

  String _gpuCodenameForCpuRules(Map<String, dynamic> gpu) {
    final codename = safeStr(gpu['Codename']);
    if (codename.isNotEmpty || !GpuCompatibilityData.isLoaded) {
      return codename;
    }

    return gpuCodename(gpu);
  }

  String _gpuRuleText(String fallbackName, Map<String, dynamic> gpu) {
    final deviceId = safeStr(gpu['Device ID']);
    final record = GpuCompatibilityData.findSync(deviceId);
    return [
      record?.groupName,
      record?.codename,
      record?.name,
      _gpuCodenameForCpuRules(gpu),
      _gpuDisplayNameForRules(fallbackName, gpu),
      _gpuManufacturerForRules(gpu),
      deviceId,
    ].whereType<String>().join(' ');
  }

  String _gpuManufacturerForRules(Map<String, dynamic> gpu) {
    final manufacturer = safeStr(gpu['Manufacturer']);
    if (GpuCompatibilityData.isLoaded) {
      return gpuManufacturer(gpu);
    }

    if (manufacturer.isNotEmpty) {
      return manufacturer;
    }

    final id = GpuCompatibilityData.normalizeFullDeviceId(
      safeStr(gpu['Device ID']),
    ).toUpperCase();
    if (id.startsWith('8086-')) return 'Intel';
    if (id.startsWith('1002-') || id.startsWith('1022-')) return 'AMD';
    if (id.startsWith('10DE-')) return 'NVIDIA';

    return '';
  }

  String _gpuDisplayNameForRules(
      String fallbackName, Map<String, dynamic> gpu) {
    final name = [
      fallbackName,
      safeStr(gpu['Name']),
      safeStr(gpu['DeviceDesc']),
      safeStr(gpu['Device Description']),
      safeStr(gpu['Description']),
    ].where((value) => value.trim().isNotEmpty).join(' ');

    if (name.isNotEmpty || !GpuCompatibilityData.isLoaded) {
      return name;
    }

    return gpuDisplayName(fallbackName, gpu);
  }

  String _motherboardSearchText(HardwareConfigBuildContext context) {
    final board = context.hardwareInfo.motherBoard;
    final rawBoard = safeMap(context.rawInfoMap['Motherboard']);

    return [
      board?.manufacturer,
      board?.model,
      board?.name,
      board?.product,
      board?.chipset,
      board?.deviceID,
      board?.platform,
      safeStr(rawBoard['Manufacturer']),
      safeStr(rawBoard['Model']),
      safeStr(rawBoard['Name']),
      safeStr(rawBoard['Product']),
      safeStr(rawBoard['Chipset']),
      safeStr(rawBoard['Device ID']),
      safeStr(rawBoard['Platform']),
    ].whereType<String>().join(' ').toLowerCase();
  }

  Brand _resolveMotherboardBrand(String text) {
    if (text.isEmpty) return Brand.none;

    if (_containsAny(text, const ['asustek', 'asus', '华硕'])) {
      return Brand.asus;
    }
    if (_containsAny(text, const ['gigabyte', '技嘉'])) {
      return Brand.gigabyte;
    }
    if (_containsAny(text, const ['asrock', 'as rock', '华擎'])) {
      return Brand.asrock;
    }
    if (_containsAny(text, const ['micro-star', 'micro star', 'msi', '微星'])) {
      return Brand.msi;
    }
    if (_containsAny(text, const ['dell', 'alienware', '戴尔'])) {
      return Brand.dell;
    }
    if (_containsAny(text, const ['vaio', 'sony', '索尼'])) {
      return Brand.vaio;
    }
    if (_containsAny(
        text, const ['hewlett-packard', 'hewlett packard', 'hp ', '惠普'])) {
      return Brand.hp;
    }
    if (_containsAny(text, const ['chromebook', 'google', '谷歌'])) {
      return Brand.chrome;
    }
    if (_containsAny(text, const ['microsoft', 'surface', '微软'])) {
      return Brand.microsoft;
    }

    return Brand.none;
  }

  SpecialMotherboard _resolveSpecialMotherboard(
    String text, {
    required CpuType cpuType,
    required String platformCode,
  }) {
    if (text.isEmpty) {
      return cpuType == CpuType.amd
          ? SpecialMotherboard.amdNormal
          : SpecialMotherboard.none;
    }

    if (cpuType == CpuType.amd) {
      return _resolveAmdSpecialMotherboard(text);
    }

    if (cpuType == CpuType.intel) {
      return _resolveIntelSpecialMotherboard(text, platformCode);
    }

    return SpecialMotherboard.none;
  }

  SpecialMotherboard _resolveAmdSpecialMotherboard(String text) {
    if (_containsChipset(text, const ['trx40'])) {
      return SpecialMotherboard.amdTrx40;
    }
    if (_containsChipset(text, const ['x570'])) {
      return SpecialMotherboard.amdX570;
    }
    if (_containsChipset(text, const ['x470', 'b450'])) {
      return SpecialMotherboard.amdX470B450;
    }
    if (_containsChipset(text, const ['b850', 'b650', 'b550', 'a520']) ||
        text.contains('550 series')) {
      return SpecialMotherboard.amdB550A520;
    }

    return SpecialMotherboard.amdNormal;
  }

  SpecialMotherboard _resolveIntelSpecialMotherboard(
    String text,
    String platformCode,
  ) {
    if (_containsChipset(text, const ['z590'])) {
      return SpecialMotherboard.intelZ590;
    }
    if (_containsChipset(text, const ['z490'])) {
      return SpecialMotherboard.intelZ490;
    }
    if (_containsChipset(text, const ['b460'])) {
      return SpecialMotherboard.intelB460;
    }
    if (_containsChipset(text, const ['z390'])) {
      return SpecialMotherboard.intelZ390;
    }
    if (_containsChipset(text, const ['h110', 'b150', 'b250', 'q270'])) {
      return SpecialMotherboard.intelOem;
    }
    if (platformCode == 'ivy_bridge' &&
        _containsChipset(text, const ['h61','h67', 'hm65', 'p67', 'z68', 'q65'])) {
      return SpecialMotherboard.intelS6;
    }
    if (platformCode == 'sandy_bridge' &&
        _containsChipset(text, const ['b75', 'hm76','hm77', 'z77', 'h77', 'q77'])) {
      return SpecialMotherboard.intelS7;
    }

    return SpecialMotherboard.none;
  }

  bool _containsAny(String text, Iterable<String> values) {
    return values.any(text.contains);
  }

  bool _containsChipset(String text, Iterable<String> chipsets) {
    return chipsets.any(
      (chipset) => RegExp(
        r'(^|[^a-z0-9])' + RegExp.escape(chipset) + r'([^a-z0-9]|$)',
      ).hasMatch(text),
    );
  }

  String _normalizeDeviceId(String? value) {
    return GpuCompatibilityData.normalizeFullDeviceId(value).toUpperCase();
  }
}
