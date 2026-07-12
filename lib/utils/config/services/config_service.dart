import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:rapidefi/extension/string_extension.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_configs.dart';
import 'package:rapidefi/utils/config/build/config_rule_engine.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/services/config_session.dart';
import 'package:rapidefi/utils/config/models/device_properties/igpu_model.dart';
import 'package:rapidefi/utils/config/accessors/amd_settings_accessor.dart';
import 'package:rapidefi/utils/config/catalogs/bluetooth_nvram/bluetooth_nvram.dart';
import 'package:rapidefi/utils/config/catalogs/efi_drivers/efi_drivers.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/patches/kernel_patch.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_add_item.dart';
import 'package:rapidefi/pages/history/model/history_model.dart';
import 'package:rapidefi/pages/manual/model/platform_entity.dart';
import 'package:rapidefi/utils/constant.dart';
import 'package:rapidefi/utils/config/presets/sections/config_device_properties.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';
import 'package:rapidefi/utils/config/support/wifi_oclp_support.dart';
import 'package:sp_util/sp_util.dart';
import 'package:rapidefi/utils/config/services/xml_plist_editor.dart';
import 'package:rapidefi/utils/config/services/config_patch_builder.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/file_util.dart';

class ConfigService {
  
  ConfigService._() {
    _init();
  }

  Future<void> _init() async {
    if (ocVersion.isEmpty) {
      final cachedOCVersion = SpUtil.getString(Constant.openCoreVersionKey)??"";
      ocVersion = cachedOCVersion.isNotEmpty
          ? 'OpenCore-$cachedOCVersion'
          : await FileUtils.getOCVerion(addOpenCoreHeader: true);
    }
    if (outputDirectory.isEmpty) {
      outputDirectory = await FileUtils.getDefaultOutputDirectory();
    }
    await ensureEfiDriverCatalog();
    await ensureBluetoothNvramCatalog();
  }

  String _platformInfoAssetKey(
    CpuType cpuType,
    PlatformType platformType,
  ) {
    return '${cpuType.name.toLowerCase()}_${platformType.name.toLowerCase()}';
  }

  List<PlatformEntity> getCachedPlatformInfos({
    CpuType? cpuType,
    PlatformType? platformType,
  }) {
    final targetCpuType = cpuType ?? this.cpuType;

    final targetPlatformType = platformType ?? this.platformType;

    final key = _platformInfoAssetKey(
      targetCpuType,
      targetPlatformType,
    );

    return _platformInfoCache[key] ?? const <PlatformEntity>[];
  }

  Future<void> preloadAllPlatformInfos() async {
    final currentCpuType = cpuType;
    final currentPlatformType = platformType;

    final tasks = <Future<void>>[];

    for (final cpu in CpuType.values) {
      if (cpu == CpuType.unknown) {
        continue;
      }

      for (final platform in PlatformType.values) {
        tasks.add(
          getPlatformInfos(
            cpuType: cpu,
            platformType: platform,
          ).then((_) {}).catchError((_) {}),
        );
      }
    }

    await Future.wait(tasks);

    await getPlatformInfos(
      cpuType: currentCpuType,
      platformType: currentPlatformType,
    );
  }

  Future<List<PlatformEntity>> getPlatformInfos({
    CpuType? cpuType,
    PlatformType? platformType,
    bool forceReload = false,
  }) async {
    final targetCpuType = cpuType ?? this.cpuType;
    final targetPlatformType = platformType ?? this.platformType;
    final key = _platformInfoAssetKey(targetCpuType, targetPlatformType);

    if (!forceReload) {
      final cached = _platformInfoCache[key];
      if (cached != null) {
        platformEntites = cached;
        return platformEntites;
      }

      final loadingTask = _platformInfoLoadingTasks[key];
      if (loadingTask != null) {
        platformEntites = await loadingTask;
        return platformEntites;
      }
    }

    final task = _loadPlatformInfosByKey(key);
    _platformInfoLoadingTasks[key] = task;

    try {
      final result = await task;
      _platformInfoCache[key] = result;
      platformEntites = result;
      return platformEntites;
    } finally {
      _platformInfoLoadingTasks.remove(key);
    }
  }

  Future<List<PlatformEntity>> _loadPlatformInfosByKey(String key) async {
    final data = await rootBundle.loadString('assets/data/$key.json');
    final jsonResult = jsonDecode(data);

    return (jsonResult as List)
        .map((jsonStr) => PlatformEntity.fromJson(jsonStr))
        .toList();
  }

  void clearPlatformInfosCache() {
    _platformInfoCache.clear();
    _platformInfoLoadingTasks.clear();
  }

  // 单例实例
  static final ConfigService _instance = ConfigService._();

  //
  List<HistoryModel>? historyModels;

  // 工厂方法获取单例实例
  factory ConfigService() => _instance;

  List<PlatformEntity> platformEntites = [];

  final Map<String, List<PlatformEntity>> _platformInfoCache = {};

  final Map<String, Future<List<PlatformEntity>>> _platformInfoLoadingTasks =
      {};

  List<KernelKext> _allKexts = [];
  List<EfiDriverOption> _efiDriverCatalog = [];
  Map<String, List<BluetoothNvramOption>> _bluetoothNvramCatalog = {};

  Future<void> ensureEfiDriverCatalog() async {
    if (_efiDriverCatalog.isEmpty) {
      _efiDriverCatalog = await EfiDriverCatalogLoader.load();
    }
  }

  List<EfiDriverOption> get efiDriverCatalog => _efiDriverCatalog;

  Future<void> ensureBluetoothNvramCatalog() async {
    if (_bluetoothNvramCatalog.isEmpty) {
      _bluetoothNvramCatalog = await BluetoothNvramCatalogLoader.load();
    }
  }

  List<BluetoothNvramOption> get bluetoothInternalControllerInfoOptions {
    return _bluetoothNvramCatalog[
            ConfigNvram.bluetoothInternalControllerInfo.key] ??
        [];
  }

  List<KernelKext> get allAddKexts {
    _allKexts = allKexts();
    _allKexts = sortAllKernelKexts(sortKexts: _allKexts);
    return _allKexts;
  }

  ConfigModelMode _configModelMode = ConfigModelMode.manual;
  final Map<ConfigModelMode, ConfigSession> _configSessions = {
    ConfigModelMode.auto: ConfigSession.from(ConfigModel()),
  };

  ConfigSession get _activeConfigSession {
    return _configSessions.putIfAbsent(
      _configModelMode,
      () => ConfigSession.from(ConfigModel()),
    );
  }

  ConfigModel get _configModel => _activeConfigSession.current;

  ConfigModel get _originConfigModel => _activeConfigSession.baseline;

  ConfigModel get originConfigModel => _originConfigModel;

  ConfigModelMode get configModelMode => _configModelMode;

  ConfigService setConfigModel(ConfigModel configModel) {
    final detachedModel = configModel.detached();
    _seedLegacyRuntimeFields(detachedModel);
    detachedModel.platformCode = PlatformCodeRegistry.resolveCode(
      detachedModel.cpuType,
      detachedModel.platformType,
      platformCode: detachedModel.platformCode,
    );
    detachedModel.kernel.kernelKexts =
        normalizeKernelKexts(detachedModel.kernel.kernelKexts);
    final mode = _configModelMode;
    _configSessions[mode] = ConfigSession.from(detachedModel);
    _configModelMode = mode;
    return this;
  }

  void updateConfigModel(bool auto) {
    setConfigModelMode(auto ? ConfigModelMode.auto : ConfigModelMode.manual);
  }

  void setConfigModelMode(ConfigModelMode mode) {
    _configModelMode = mode;
    _activeConfigSession;
  }

  void resetConfigScope(ConfigScope scope) {
    _activeConfigSession.reset(scope);
  }

  bool hasConfigPatch(ConfigScope scope) {
    return _activeConfigSession.patchRecords.any(
      (record) => record.scopes.contains(scope),
    );
  }

  void checkpointConfigScope(
    ConfigScope scope, {
    String label = 'manual',
  }) {
    _activeConfigSession.checkpoint(label, {scope});
  }

  ///版本列表
  final List<String> macOSVeriosnName = MacOSVersions.labels;
  static const String copyConfigName = 'config-after-post.plist';

  String ocVersion = '';
  //输出目录
  String outputDirectory = '';
  String? utbMapPath;

  ConfigModel get configModel => _configModel;

  List<String> amdCores = const [
    "2",
    "3",
    "4",
    "6",
    "8",
    "10",
    "12",
    "16",
    "24",
    "32",
    "48",
    "64"
  ];

  bool get showIGPU {
    if (configModel.cpuType != CpuType.intel || isHEDT) {
      return false;
    }
    List<List<IgpuPropertyModel>> gpuModels = Configs()
            .configsRepository
            .getPlatformModel(configModel.cpuType, configModel.platformType)!
            .platforms[configModel.platformCode]
            ?.igpuModes ??
        [];
    return gpuModels.isNotEmpty;
  }

  bool get showLaptopKext {
    return configModel.platformType == PlatformType.laptop;
  }

  bool get showMobileComet {
    return configModel.cpuType == CpuType.intel &&
        (configModel.platformType == PlatformType.laptop ||
            configModel.platformType == PlatformType.nuc) &&
        configModel.platformCode == 'comet_lake';
  }

  bool get resizeAppleGpuBarsToZero {
    return configModel.specialMotherboard == SpecialMotherboard.intelB460 ||
        configModel.specialMotherboard == SpecialMotherboard.intelZ490 ||
        configModel.specialMotherboard == SpecialMotherboard.intelZ590 ||
        isAMD ||
        (isIntel && isDesktop && configModel.platformRank >= 7) ||
        (isIntel && (isLaptop || isNuc) && configModel.platformRank >= 12);
  }

  CpuType get cpuType => configModel.cpuType;
  PlatformType get platformType => configModel.platformType;

  String get plantformInfo {
    final platformInfo = Configs()
            .configsRepository
            .getPlatformModel(configModel.cpuType, configModel.platformType)!
            .platforms[configModel.platformCode]
            ?.label ??
        '';
    return platformInfo;
  }

  bool get isIntel => cpuType == CpuType.intel;

  bool get isAMD => cpuType == CpuType.amd;

  bool get isRyzen => isAMD && plantformInfo.contains('Ryzen');

  bool get isDesktop => platformType == PlatformType.desktop;

  bool get isLaptop => platformType == PlatformType.laptop;

  bool get isNuc => platformType == PlatformType.nuc;

  bool get isHEDT => platformType == PlatformType.hedt;

  bool get mixedCPUWithMainboard {
    return mixedCPUWithIvyBridge || mixedCPUWithSandyBridge;
  }

  bool get mixedCPUWithIvyBridge {
    return !isHEDT &&
        cpuType == CpuType.intel &&
        (configModel.platformCode == 'ivy_bridge' &&
            configModel.specialMotherboard == SpecialMotherboard.intelS6);
  }

  bool get mixedCPUWithSandyBridge {
    return !isHEDT &&
        cpuType == CpuType.intel &&
        (configModel.platformCode == 'sandy_bridge' &&
            configModel.specialMotherboard == SpecialMotherboard.intelS7);
  }

  bool get useNootRXKext {
    return allAddKexts
        .any((e) => e.bundlePath == ConfigKernel.NootRX.bundlePath);
  }

  List<KernelKext> selectedKexts([ConfigModel? model]) {
    return KextAccessor.selectedKexts(model ?? configModel);
  }

  List<KernelKext> selectedKextsIn(Iterable<KernelKext> candidates) {
    return KextAccessor.selectedKextsIn(configModel, candidates);
  }

  bool hasKext(KernelKext kext) {
    return KextAccessor.containsKext(configModel, kext);
  }

  void addKexts(Iterable<KernelKext> kexts) {
    KextAccessor.addKexts(configModel, kexts);
  }

  void removeKexts(Iterable<KernelKext> kexts) {
    KextAccessor.removeKexts(configModel, kexts);
  }

  void replaceKexts(
    Iterable<KernelKext> removableKexts,
    Iterable<KernelKext> selectedKexts,
  ) {
    KextAccessor.replaceKexts(configModel, removableKexts, selectedKexts);
  }

  List<AcpiAddItem> allSSDTs([ConfigModel? source]) {
    final baseModel = source ?? configModel;
    if (_configModelMode == ConfigModelMode.process) {
      return _dedupeByPath(
        baseModel.acpi.acpiAddItems.map((item) => item.copyWith()).toList(),
      );
    }

    final ruleEngine = ConfigRuleEngine(this);
    final managedPaths = ruleEngine.managedOtherSSDTPaths;
    final baseItems = baseModel.acpi.acpiAddItems
        .where((item) => !managedPaths.contains(item.path))
        .map((item) => item.copyWith());

    return _dedupeByPath([
      ...baseItems,
      ...ruleEngine.addOtherSSDTs(),
    ]);
  }

  List<KernelKext> allKexts() {
    var allKexts = <KernelKext>[];
    final baseKexts = _baseKextsForPatch(configModel.kernel.kernelKexts);
    allKexts.addAll(baseKexts.map((kext) => kext.copyWith()));
    final otherKexts = ConfigRuleEngine(this).addOtherKexts();
    allKexts.addAll(otherKexts);
    return normalizeKernelKexts(allKexts, sort: false);
  }

  List<IgpuPropertyModel> allDeviceProperties(ConfigModel source) {
    final generated = ConfigRuleEngine(this).addOtherDeviceProperties();
    final baseItems = source.deviceProperties.addList
            ?.where((item) => item.pciPath != ConfigDp.imei_pciPath)
            .map((item) => item.copyWith())
            .toList() ??
        [];

    return _dedupeDeviceProperties([
      ...baseItems,
      ...generated,
    ]);
  }

  List<KernelKext> normalizeKernelKexts(
    List<KernelKext> kexts, {
    bool sort = true,
  }) {
    final normalized = kexts.map((kext) => kext.copyWith()).toSet().toList();
    if (!sort) return normalized;
    return sortAllKernelKexts(sortKexts: normalized);
  }

  List<AcpiAddItem> _dedupeByPath(List<AcpiAddItem> items) {
    final seen = <String>{};
    final result = <AcpiAddItem>[];
    for (final item in items) {
      if (seen.add(item.path)) {
        result.add(item);
      }
    }
    return result;
  }

  List<IgpuPropertyModel> _dedupeDeviceProperties(
    List<IgpuPropertyModel> items,
  ) {
    final seen = <String>{};
    final result = <IgpuPropertyModel>[];
    for (final item in items) {
      if (seen.add(item.pciPath)) {
        result.add(item);
      }
    }
    return result;
  }

  List<KernelKext> _baseKextsForPatch(List<KernelKext> kexts) {
    final removeBundlePaths = [
      ...ConfigKextGroups.atherosWifiLegacySupport.kexts,
      ...ConfigKextGroups.atherosWifiModernSupport.kexts,
    ].map((kext) => kext.bundlePath).toSet();

    if (configModel.darwinMajorVersion > 20) {
      removeBundlePaths.addAll(
        ConfigKextGroups.atherosWifiModels.kexts.map(
          (kext) => kext.bundlePath,
        ),
      );
    }

    return kexts
        .where((kext) => !removeBundlePaths.contains(kext.bundlePath))
        .toList();
  }

  //设置默认选中平台信息
  int getDefaultPlatformInfoIndex(CpuType cpuType, PlatformType platformType) {
    if (cpuType == CpuType.intel) {
      if (platformType == PlatformType.desktop) {
        return 3;
      }
      if (platformType == PlatformType.laptop) {
        return 3;
      }
      if (platformType == PlatformType.nuc) {
        return 3;
      }
      if (platformType == PlatformType.hedt) {
        return 2;
      }
    } else {
      if (platformType == PlatformType.desktop ||
          platformType == PlatformType.laptop ||
          platformType == PlatformType.nuc) {
        return 1;
      }
    }
    return 0;
  }

  List<KernelKext> sortAllKernelKexts({
    required List<KernelKext> sortKexts,
    List<KernelKext>? referenceSortingKexts,
  }) {
    referenceSortingKexts =
        referenceSortingKexts ?? ConfigKernel.sortKernelKexts;

    final sortOrder = {
      for (var i = 0; i < referenceSortingKexts.length; i++)
        referenceSortingKexts[i]: i,
    };

    final originalOrder = {
      for (var i = 0; i < sortKexts.length; i++) sortKexts[i]: i,
    };

    sortKexts.sort((a, b) {
      final indexA = sortOrder[a] ?? -1;
      final indexB = sortOrder[b] ?? -1;

      if (indexA == -1 && indexB == -1) {
        return originalOrder[a]!.compareTo(originalOrder[b]!);
      } else if (indexA == -1) {
        return 1;
      } else if (indexB == -1) {
        return -1;
      } else {
        return indexA.compareTo(indexB);
      }
    });

    return sortKexts;
  }

  /// 应用配置模型的补丁
  Future<void> applyConfigPatchWithModel({
    required File file,
    required ConfigModel model,
  }) async {
    final editor = await XmlPlistEditor.fromFile(file.path);

    _patchAppNotes(editor);

    final patchOps = ConfigPatchBuilder(
      model: model,
    ).build();

    for (final op in patchOps) {
      editor.apply(op);
    }

    await editor.save(file.path);
  }

  void _patchAppNotes(XmlPlistEditor editor) {
    editor.setValue(
      ['#${Constant.appName}-v${SpUtil.getString(Constant.appVersionKey)}'],
      'An excellent one-click EFI configuration tool based on OpenCore',
    );

    editor.remove(['#WARNING - 1']);
    editor.remove(['#WARNING - 2']);
    editor.remove(['#WARNING - 3']);
    editor.remove(['#WARNING - 4']);
  }

  Future<void> _applyConfigPatch({
    required File file,
  }) async {
    await applyConfigPatchWithModel(
      file: file,
      model: buildPatchModel(configModel),
    );
  }

  ConfigModel buildPatchModel(ConfigModel source) {
    final model = source.detached();
    NvramSettingsAccessor.normalizeUiScale(model);

    model.acpi.acpiAddItems = allSSDTs(source);
    model.deviceProperties.addList = allDeviceProperties(source);
    model.kernel.kernelKexts = allAddKexts;

    _prepareKernelForPatchModel(model);
    _prepareNvramForPatchModel(model);

    return model;
  }

  ConfigModel buildPersistedConfigModel(ConfigModel source) {
    final model = source.detached();
    NvramSettingsAccessor.normalizeUiScale(model);
    model.deviceProperties.addList = source.deviceProperties.addList
            ?.where((item) => item.pciPath != ConfigDp.imei_pciPath)
            .map((item) => item.copyWith())
            .toList() ??
        [];
    model.kernel.kernelKexts = normalizeKernelKexts(model.kernel.kernelKexts);
    return model;
  }

  ConfigModel _buildCopyConfigPatchModel({
    required ConfigModel source,
    required List<KernelKext> kernelKexts,
  }) {
    final model = buildPatchModel(source);
    model.kernel.kernelKexts = kernelKexts;
    WifiOclpSupport.applyToModel(model);

    return model;
  }

  void _prepareKernelForPatchModel(ConfigModel model) {
    final modelIsAMD = model.cpuType == CpuType.amd;
    final modelIsDesktop = model.platformType == PlatformType.desktop;
    final modelIsLaptop = model.platformType == PlatformType.laptop;
    final modelIsNuc = model.platformType == PlatformType.nuc;
    WifiOclpSupport.applyToModel(model);

    if ([
      ConfigKernel.AirportItlwm_Catalina,
      ConfigKernel.AirportItlwm_Mojave,
      ConfigKernel.AirportItlwm_HighSierra,
    ].any((kext) => KextAccessor.containsKext(model, kext))) {
      model.kernel.kernelForceItems = [KernelPatch.forceIO80211FamilyToLoad];
    } else {
      model.kernel.kernelForceItems =
          _originConfigModel.kernel.kernelForceItems;
    }

    if (modelIsAMD) {
      if (!AmdSettingsAccessor.hasAmdKernelPatches(model)) {
        AmdSettingsAccessor.setAmdCore(
            model, AmdSettingsAccessor.getAmdCore(model));
      }
      return;
    }

    if (model.pentiumOrCeleron) {
      model.kernel.kernelEmulate =
          ConfigKernel.kernelEmulateList_Desktop[model.platformRank].copyWith(
        dummyPowerManagement: model.kernel.kernelEmulate.dummyPowerManagement,
      );
      return;
    }

    if (modelIsLaptop || modelIsNuc) {
      if (model.isCometLakeU62) {
        model.kernel.kernelEmulate =
            ConfigKernel.kernelEmulate_CometLake_U62.copyWith(
          dummyPowerManagement: model.kernel.kernelEmulate.dummyPowerManagement,
        );
      } else if (model.platformRank < 12) {
        model.kernel.kernelEmulate =
            _originConfigModel.kernel.kernelEmulate.copyWith(
          cpuid1Data: ''.toBytes(),
          cpuid1Mask: ''.toBytes(),
          dummyPowerManagement: model.kernel.kernelEmulate.dummyPowerManagement,
        );
      }
    } else if (model.platformRank <= 10 && modelIsDesktop) {
      model.kernel.kernelEmulate =
          _originConfigModel.kernel.kernelEmulate.copyWith(
        cpuid1Data: ''.toBytes(),
        cpuid1Mask: ''.toBytes(),
        dummyPowerManagement: model.kernel.kernelEmulate.dummyPowerManagement,
      );
    }
  }

  void _prepareNvramForPatchModel(ConfigModel model) {
    model.nvram.nvramAdd.addList
        ?.forEach((String key, List<NvramAddItem>? items) {
      if (key == ConfigNvram.UUID_4D1FDA02_38C7_4A6A_9CC6_4BCCA8B30102) {
        final customCpuName = NvramSettingsAccessor.getCustomCpuName(model);
        items?.removeWhere((e) => e.key == ConfigNvram.revcpu.key);
        items?.removeWhere((e) => e.key == ConfigNvram.revcpuname.key);
        if (model.processorType != ProcessorType.none) {
          items?.add(ConfigNvram.revcpu);
        }
        if (customCpuName.isNotEmpty) {
          items?.add(ConfigNvram.revcpuname.copyWith(
            value: customCpuName,
          ));
        }
      }
    });
  }

  int checkMacOSVersion() {
    return _macOSMajorVersion(configModel);
  }

  int checkDarwinMajorVersion() {
    return configModel.darwinMajorVersion;
  }

  int _macOSMajorVersion(ConfigModel model) {
    return MacOSVersions.productMajorFromDarwinMajor(
      model.darwinMajorVersion,
    );
  }

  void normalizeRuntimeConfigModel() {
    if (_configModelMode == ConfigModelMode.auto) {
      _ensureDefaultDebugBootArgs(configModel);
    }
    _normalizeIntelBacklightBootArg(configModel);
    configModel.platformCode = PlatformCodeRegistry.resolveCode(
      configModel.cpuType,
      configModel.platformType,
      platformCode: configModel.platformCode,
    );
    configModel.kernel.kernelKexts =
        normalizeKernelKexts(configModel.kernel.kernelKexts);
  }

  void _normalizeIntelBacklightBootArg(ConfigModel model) {
    final hasBacklightArg =
        BootArgsAccessor.contains(model, ConfigNvram.igfxblr.arg) ||
            BootArgsAccessor.contains(model, ConfigNvram.igfxblt.arg);
    if (!hasBacklightArg) return;

    BootArgsAccessor.remove(model, ConfigNvram.igfxblr.arg);
    BootArgsAccessor.remove(model, ConfigNvram.igfxblt.arg);
    BootArgsAccessor.add(
      model,
      model.darwinMajorVersion >= 22
          ? ConfigNvram.igfxblt.arg
          : ConfigNvram.igfxblr.arg,
    );
  }

  void _seedLegacyRuntimeFields(ConfigModel model) {
    if (hasConfigPatch(ConfigScope.bootArgs)) {
      return;
    }

    if (BootArgsAccessor.getBootArgList(model).isNotEmpty) {
      return;
    }

    _ensureDefaultDebugBootArgs(model);
  }

  void _ensureDefaultDebugBootArgs(ConfigModel model) {
    for (final bootArg in [
      ConfigNvram.verbose,
      ConfigNvram.keepsyms1,
      ConfigNvram.debug100,
    ]) {
      BootArgsAccessor.add(model, bootArg.arg);
    }
  }

  Future<bool> executePostConfig(String filePath,
      {ConfigModel? patchModel}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return false;
    }

    if (patchModel == null) {
      await _applyConfigPatch(file: file);
    } else {
      await applyConfigPatchWithModel(file: file, model: patchModel);
    }

    if (needCopyConfig) {
      if (!await editCopyConfig(file, sourceModel: patchModel)) {
        return false;
      }
    }

    return true;
  }

  bool get needCopyConfig {
    bool need = false;
    bool needAmdNoDgpuAccel = BootArgsAccessor.contains(
        configModel, ConfigNvram.amd_no_dgpu_accel.arg);
    need = (isIntel && configModel.platformRank <= 3) && needAmdNoDgpuAccel;
    need = need ||
        AmdSettingsAccessor.usesRyzenGpu(configModel) ||
        (configModel.pentiumOrCeleron && needAmdNoDgpuAccel);
    return need;
  }

  Future<File> copyConfigFile(File sourceFile) async {
    String newFileName = copyConfigName;
    String currentDirectory = sourceFile.parent.path;
    // 构建目标文件路径
    String destinationPath = '$currentDirectory/$newFileName';
    // 复制文件
    return await sourceFile.copy(destinationPath);
  }

  Future<bool> editCopyConfig(File sourceFile,
      {ConfigModel? sourceModel}) async {
    final file = await copyConfigFile(sourceFile);
    final model = sourceModel ?? configModel;
    final adjustKexts = allAddKexts.map((e) => e.copyWith()).toList();
    for (final e in adjustKexts) {
      if (AmdSettingsAccessor.usesRyzenGpu(model)) {
        if (e.bundlePath == ConfigKernel.WhateverGreen.bundlePath) {
          e.enabled = false;
        }
        if (e.bundlePath == ConfigKernel.NootedRed.bundlePath) {
          e.enabled = true;
        }
      }
    }
    final copyModel = _buildCopyConfigPatchModel(
      source: model,
      kernelKexts: adjustKexts,
    );
    BootArgsAccessor.remove(copyModel, ConfigNvram.amd_no_dgpu_accel.arg);

    await applyConfigPatchWithModel(
      file: file,
      model: copyModel,
    );

    return true;
  }
}
