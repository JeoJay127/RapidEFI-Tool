import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';

class PlatformCodeRegistry {
  PlatformCodeRegistry._();

  static const Map<CpuType, Map<PlatformType, List<String>>> codesByPlatform = {
    CpuType.intel: {
      PlatformType.desktop: [
        'penryn',
        'lynnfield',
        'sandy_bridge',
        'ivy_bridge',
        'haswell',
        'broadwell',
        'skylake',
        'kaby_lake',
        'coffee_lake_8th',
        'coffee_lake_9th',
        'comet_lake',
        'rocket_lake',
        'alder_lake',
        'raptor_lake',
        'raptor_lake_refresh',
        'arrow_lake',
      ],
      PlatformType.laptop: [
        'penryn',
        'clarksfield_arrandale',
        'sandy_bridge',
        'ivy_bridge',
        'haswell',
        'broadwell',
        'skylake',
        'kaby_lake',
        'coffee_lake_8th',
        'coffee_lake_9th',
        'comet_lake',
        'ice_lake',
        'tiger_lake',
        'alder_lake',
        'raptor_lake',
        'raptor_lake_refresh',
      ],
      PlatformType.nuc: [
        'penryn',
        'clarksfield_arrandale',
        'sandy_bridge',
        'ivy_bridge',
        'haswell',
        'broadwell',
        'skylake',
        'kaby_lake',
        'coffee_lake_8th',
        'coffee_lake_9th',
        'comet_lake',
        'ice_lake',
        'tiger_lake',
        'alder_lake',
        'raptor_lake',
        'raptor_lake_refresh',
      ],
      PlatformType.hedt: [
        'nehalem_westmere',
        'sandy_bridge_e',
        'ivy_bridge_e',
        'haswell_e',
        'broadwell_e',
        'skylake_x_w',
        'cascade_lake_x_w',
      ],
    },
    CpuType.amd: {
      PlatformType.desktop: [
        'bulldozer_jaguar',
        'ryzen_threadripper',
      ],
      PlatformType.laptop: [
        'bulldozer_jaguar',
        'ryzen',
      ],
      PlatformType.nuc: [
        'bulldozer_jaguar',
        'ryzen',
      ],
      PlatformType.hedt: [
        'ryzen_threadripper',
      ],
    },
  };

  static List<String> codes(CpuType cpuType, PlatformType platformType) {
    return codesByPlatform[cpuType]?[platformType] ?? const <String>[];
  }

  static String defaultCode(CpuType cpuType, PlatformType platformType) {
    return codeAt(cpuType, platformType, defaultIndex(cpuType, platformType));
  }

  static int defaultIndex(CpuType cpuType, PlatformType platformType) {
    if (cpuType == CpuType.intel) {
      if (platformType == PlatformType.hedt) {
        return 2;
      }
      return 3;
    }
    if (platformType != PlatformType.hedt) {
      return 1;
    }
    return 0;
  }

  static String codeAt(
    CpuType cpuType,
    PlatformType platformType,
    int index,
  ) {
    final codeList = codes(cpuType, platformType);
    if (index >= 0 && index < codeList.length) {
      return codeList[index];
    }
    return codeList.isNotEmpty ? codeList.first : '';
  }

  static int indexOf(
    CpuType cpuType,
    PlatformType platformType,
    String? code, {
    int fallback = 0,
  }) {
    final codeList = codes(cpuType, platformType);
    final index = code == null ? -1 : codeList.indexOf(code);
    if (index >= 0) {
      return index;
    }
    if (fallback >= 0 && fallback < codeList.length) {
      return fallback;
    }
    return 0;
  }

  static bool contains(
    CpuType cpuType,
    PlatformType platformType,
    String? code,
  ) {
    return code != null && codes(cpuType, platformType).contains(code);
  }

  static String resolveCode(
    CpuType cpuType,
    PlatformType platformType, {
    String? platformCode,
    int legacyIndex = 0,
  }) {
    if (contains(cpuType, platformType, platformCode)) {
      return platformCode!;
    }
    return codeAt(cpuType, platformType, legacyIndex);
  }
}

extension PlatformCodeConfigAccess on ConfigModel {
  int get platformRank {
    return PlatformCodeRegistry.indexOf(
      cpuType,
      platformType,
      platformCode,
    );
  }
}
