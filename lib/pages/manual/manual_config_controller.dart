import 'package:flutter/foundation.dart';
import 'package:rapidefi/utils/config/build/efi_build_options.dart';
import 'package:rapidefi/utils/config/build/efi_build_pipeline.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_configs.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_profile.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi_generic.dart';
import 'package:rapidefi/utils/config/services/apple_alc_resolver.dart';
import 'package:rapidefi/utils/config/services/config_model_editor.dart';
import 'package:rapidefi/utils/config/services/config_service.dart';
import 'package:rapidefi/utils/config/services/config_session.dart';
import 'package:rapidefi/utils/config/support/smbios_compatibility.dart';
import 'package:rapidefi/utils/device_util.dart';
import 'package:rapidefi/utils/file_util.dart';

class ManualConfigController extends ChangeNotifier {
  ManualConfigController();

  final ConfigService _configService = ConfigService();
  late final ConfigModelEditor _editor = ConfigModelEditor(_configService);
  ConfigModelMode _mode = ConfigModelMode.manual;

  bool _isLoading = true;

  int _platformBaseRevision = 0;
  int _smbiosRevision = 0;
  int _connectivityRevision = 0;
  int _igpuRevision = 0;
  int _sipRevision = 0;
  int _uefiSupportRevision = 0;
  int _normalRevision = 0;

  PlatformModel? _cachedPlatformModel;
  CpuType? _cachedPlatformCpuType;
  PlatformType? _cachedPlatformType;

  bool get isLoading => _isLoading;

  int get platformBaseRevision => _platformBaseRevision;
  int get smbiosRevision => _smbiosRevision;
  int get connectivityRevision => _connectivityRevision;
  int get igpuRevision => _igpuRevision;
  int get sipRevision => _sipRevision;
  int get uefiSupportRevision => _uefiSupportRevision;
  int get normalRevision => _normalRevision;

  ConfigService get configService => _configService;
  ConfigModelEditor get editor => _editor;
  ConfigModel get model {
    activateSession();
    return _configService.configModel;
  }

  PlatformModel get platformModel {
    activateSession();
    final current = _configService.configModel;

    if (_cachedPlatformModel != null &&
        _cachedPlatformCpuType == current.cpuType &&
        _cachedPlatformType == current.platformType) {
      return _cachedPlatformModel!;
    }

    _cachedPlatformCpuType = current.cpuType;
    _cachedPlatformType = current.platformType;
    _cachedPlatformModel = Configs().configsRepository.getPlatformModel(
          current.cpuType,
          current.platformType,
        )!;

    return _cachedPlatformModel!;
  }

  Future<void> initialize(
    ConfigModel? initialModel, {
    ConfigModelMode mode = ConfigModelMode.manual,
  }) async {
    _setLoading(true);

    try {
      _mode = mode;
      activateSession();
      if (initialModel != null) {
        _editor.setConfigModel(initialModel);
      } else {
        _editor.setConfigModel(_defaultConfigModel());
      }
      _configService.normalizeRuntimeConfigModel();
      // 初始化平台数据。
      await _configService.preloadAllPlatformInfos();
      await _configService.ensureBluetoothNvramCatalog();
      await _configService.ensureEfiDriverCatalog();

      await AppleALCResolver.initialize();
      _bumpAllVisible(notify: false);
    } finally {
      _setLoading(false);
    }
  }

  void activateSession() {
    if (_configService.configModelMode != _mode) {
      _configService.setConfigModelMode(_mode);
    }
  }

  void selectCpuType(CpuType cpuType) {
    activateSession();
    final current = _configService.configModel;

    if (current.cpuType == cpuType) {
      return;
    }

    final platformType = current.platformType;
    final defaultIndex = _configService.getDefaultPlatformInfoIndex(
      cpuType,
      platformType,
    );

    _replacePlatformConfig(
      cpuType: cpuType,
      platformType: platformType,
      platformIndex: defaultIndex,
    );
  }

  void selectPlatformType(PlatformType platformType) {
    activateSession();
    final current = _configService.configModel;

    if (current.platformType == platformType) {
      return;
    }

    final cpuType = current.cpuType;
    final defaultIndex = _configService.getDefaultPlatformInfoIndex(
      cpuType,
      platformType,
    );

    _replacePlatformConfig(
      cpuType: cpuType,
      platformType: platformType,
      platformIndex: defaultIndex,
    );
  }

  void selectPlatformInfo(int index) {
    activateSession();
    final current = _configService.configModel;
    final platformCode = Configs()
        .configsRepository
        .getPlatformModel(current.cpuType, current.platformType)!
        .codeAt(index);

    if (current.platformCode == platformCode) {
      return;
    }

    _replacePlatformConfig(
      cpuType: current.cpuType,
      platformType: current.platformType,
      platformIndex: index,
    );
  }

  void _replacePlatformConfig({
    required CpuType cpuType,
    required PlatformType platformType,
    required int platformIndex,
  }) {
    final previousGeneric = _configService.configModel.platformInfo.generic;
    _editor.setConfigModel(
      _configFor(
        cpuType,
        platformType,
        platformIndex,
      ),
    );
    _applyPlatformContextDefaults(previousGeneric);

    _clearPlatformModelCache();
    _configService.normalizeRuntimeConfigModel();

    // 只刷新明确联动的板块：

    _bumpPlatformLinkedSections();
  }

  void _applyPlatformContextDefaults(PlatformInfoGeneric? previousGeneric) {
    final current = _configService.configModel;
    final platformEntry = Configs()
        .configsRepository
        .getPlatformModel(current.cpuType, current.platformType)
        ?.platforms[current.platformCode];

    final recommended = SMBIOSCompatibility.recommendForDarwinMajor(
      platformEntry?.smbiosOptions ?? const [],
      current.darwinMajorVersion,
      current: previousGeneric,
    );

    if (recommended != null) {
      current.platformInfo.generic = recommended.copyWith(
        processorType: current.platformInfo.generic?.processorType ?? 0,
      );
    }
    KextAccessor.applyCpuFriendRecommendation(current);
  }

  void update(void Function(ConfigModelEditor editor) action) {
    activateSession();
    action(_editor);
    _configService.normalizeRuntimeConfigModel();
    _bumpNormal();
  }

  void updateIgpu(void Function(ConfigModelEditor editor) action) {
    activateSession();
    action(_editor);
    _configService.normalizeRuntimeConfigModel();
    _igpuRevision++;
    notifyListeners();
  }

  void updatePlatformBase(void Function(ConfigModelEditor editor) action) {
    activateSession();
    action(_editor);
    _editor.syncWifiOclpSupportForCurrentSelection();
    _configService.normalizeRuntimeConfigModel();
    _platformBaseRevision++;
    _smbiosRevision++;
    _igpuRevision++;
    _sipRevision++;
    _uefiSupportRevision++;
    notifyListeners();
  }

  void notifyConfigChanged() {
    activateSession();
    _configService.normalizeRuntimeConfigModel();
    _bumpNormal();
  }

  void updateConnectivity(void Function(ConfigModelEditor editor) action) {
    activateSession();
    action(_editor);
    _configService.normalizeRuntimeConfigModel();
    _connectivityRevision++;
    _normalRevision++;
    notifyListeners();
  }

  void notifyConnectivityChanged() {
    activateSession();
    _configService.normalizeRuntimeConfigModel();
    _connectivityRevision++;
    _normalRevision++;
    notifyListeners();
  }

  void notifySmbiosChanged() {
    _smbiosRevision++;
    notifyListeners();
  }

  void notifyIgpuChanged() {
    _igpuRevision++;
    notifyListeners();
  }

  void notifySipChanged() {
    _sipRevision++;
    notifyListeners();
  }

  void notifyUefiSupportChanged() {
    _uefiSupportRevision++;
    notifyListeners();
  }

  Future<String> pickOutputDirectory(String currentDirectory) {
    if (Device.isWeb) return Future.value('');
    return FileUtils.openFileExplorer(currentDirectory);
  }

  Future<bool> exportEfi({
    EfiBuildOptions options = const EfiBuildOptions(),
  }) {
    activateSession();
    return EfiBuildPipeline(_configService).build(
      configModel: model,
      mode: _mode,
      options: options,
    );
  }

  ConfigModel _defaultConfigModel() {
    return _configFor(
      CpuType.intel,
      PlatformType.desktop,
      _configService.getDefaultPlatformInfoIndex(
        CpuType.intel,
        PlatformType.desktop,
      ),
    );
  }

  ConfigModel _configFor(
    CpuType cpuType,
    PlatformType platformType,
    int platformIndex,
  ) {
    final model = Configs().configsRepository.createWithIndex(
          cpuType: cpuType,
          platformType: platformType,
          platformIndex: platformIndex,
        );
    return model;
  }

  void _bumpPlatformLinkedSections() {
    _platformBaseRevision++;
    _smbiosRevision++;
    _igpuRevision++;
    _sipRevision++;
    _uefiSupportRevision++;
    notifyListeners();
  }

  void _bumpNormal() {
    _normalRevision++;
    notifyListeners();
  }

  void _bumpAllVisible({bool notify = true}) {
    _platformBaseRevision++;
    _smbiosRevision++;
    _connectivityRevision++;
    _igpuRevision++;
    _sipRevision++;
    _uefiSupportRevision++;
    _normalRevision++;

    if (notify) {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  void _clearPlatformModelCache() {
    _cachedPlatformModel = null;
    _cachedPlatformCpuType = null;
    _cachedPlatformType = null;
  }
}
