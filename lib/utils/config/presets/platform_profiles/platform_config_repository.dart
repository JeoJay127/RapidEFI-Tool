import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'platform_profile.dart';

typedef ConfigModelFactory = ConfigModel Function();

class ConfigsRepository {
  final Map<CpuType, Map<PlatformType, Map<String, ConfigModelFactory>>> _data =
      {};

  final Map<CpuType, Map<PlatformType, PlatformModel>> _platformModels = {};

  void registerAll({
    required CpuType cpuType,
    required PlatformType platformType,
    required Map<String, ConfigModelFactory> factories,
  }) {
    _data.putIfAbsent(cpuType, () => {});
    _data[cpuType]![platformType] = factories;
  }

  void registerPlatformModel(PlatformModel platformModel) {
    _platformModels.putIfAbsent(platformModel.cpuType, () => {});
    _platformModels[platformModel.cpuType]![platformModel.platformType] =
        platformModel;
  }

  PlatformModel? getPlatformModel(CpuType cpuType, PlatformType platformType) {
    return _platformModels[cpuType]?[platformType];
  }

  ConfigModel createWithPlatformCode({
    required CpuType cpuType,
    required PlatformType platformType,
    required String platformCode,
  }) {
    final resolvedCode = PlatformCodeRegistry.resolveCode(
      cpuType,
      platformType,
      platformCode: platformCode,
    );

    final factories = _data[cpuType]?[platformType];
    final factory = factories?[resolvedCode] ?? factories?.values.first;

    final model = factory?.call() ??
        ConfigModel(
          cpuType: cpuType,
          platformType: platformType,
          platformCode: resolvedCode,
        );

    model
      ..cpuType = cpuType
      ..platformType = platformType
      ..platformCode = resolvedCode;

    if (platformType == PlatformType.laptop) {
      KextAccessor.addKext(model, ConfigKernel.BrightnessKeys);
    }

    return model.detached();
  }

  ConfigModel createWithIndex({
    required CpuType cpuType,
    required PlatformType platformType,
    required int platformIndex,
  }) {
    return createWithPlatformCode(
      cpuType: cpuType,
      platformType: platformType,
      platformCode: PlatformCodeRegistry.codeAt(
        cpuType,
        platformType,
        platformIndex,
      ),
    );
  }
}
