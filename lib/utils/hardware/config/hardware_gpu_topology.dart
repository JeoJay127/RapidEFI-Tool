import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/hardware/analysis/gpu_compatibility_data.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis.dart';
import 'package:rapidefi/utils/hardware/data/gpu_codename_data.dart';
import 'package:rapidefi/utils/hardware/data/hardware_device_data.dart';

/// 统一识别自动配置流程中的核显与独显拓扑。
class HardwareGpuTopology {
  const HardwareGpuTopology._();

  static bool hasSingleGraphicsDevice(Map<String, dynamic>? rawInfo) {
    return hardwareDevices(rawInfo?['GPU']).length == 1;
  }

  static bool shouldDisableDiscreteGpu(
    Map<String, dynamic>? rawInfo,
    String name,
    Map<String, dynamic> gpu, {
    CpuType? cpuType,
    PlatformType? platformType,
  }) {
    final data = rawInfo ?? const <String, dynamic>{};
    if (hasSingleGraphicsDevice(data) || !isDiscrete(name, gpu)) return false;

    return gpuEntryCompatibility(data, name, gpu).level ==
            CompatibilityLevel.unsupported ||
        (cpuType == CpuType.intel &&
            platformType == PlatformType.laptop &&
            _intelIgpuDrivesDisplay(data));
  }

  static bool shouldDefaultEnableNpci(Map<String, dynamic>? rawInfo) {
    if (rawInfo == null) return false;
    if (hardwareDevices(rawInfo['GPU']).isEmpty) return false;
    if (hasOnlyIntegratedGraphics(rawInfo)) return false;
    return safeMap(rawInfo['BIOS'])['Above 4G Decoding'] != true;
  }

  static bool hasOnlyIntegratedGraphics(Map<String, dynamic>? rawInfo) {
    final entries = hardwareDevices(rawInfo?['GPU']).toList();
    if (entries.isEmpty) return false;

    final hasIntegrated = entries.any(
      (entry) => isIntegrated(entry.key, safeMap(entry.value)),
    );
    final hasDiscrete = entries.any(
      (entry) => isDiscrete(entry.key, safeMap(entry.value)),
    );
    return hasIntegrated && !hasDiscrete;
  }

  static bool isIntegrated(String name, Map<String, dynamic> gpu) {
    if (GpuCodenameData.isKnownIntelIntegratedGpu(
      safeStr(gpu['Device ID']),
    )) {
      return true;
    }
    final type = safeStr(gpu['Device Type']).toLowerCase();
    if (type.contains('integrated') ||
        type.contains('核显') ||
        type.contains('核心')) {
      return true;
    }
    if (type.contains('discrete') || type.contains('独立')) return false;

    final text = _searchText(name, gpu);
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

  static bool isDiscrete(String name, Map<String, dynamic> gpu) {
    if (GpuCodenameData.isKnownIntelIntegratedGpu(
      safeStr(gpu['Device ID']),
    )) {
      return false;
    }
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

    final text = _searchText(name, gpu);
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

  static bool _intelIgpuDrivesDisplay(Map<String, dynamic> data) {
    final intelIntegratedGpus = hardwareDevices(data['GPU'])
        .where((entry) {
          final gpu = safeMap(entry.value);
          return isIntegrated(entry.key, gpu) &&
              (GpuCodenameData.isIntelGpu(safeStr(gpu['Device ID'])) ||
                  _searchText(entry.key, gpu).contains('intel'));
        })
        .toList();
    if (intelIntegratedGpus.isEmpty) return false;

    final monitors = hardwareDevices(data['Monitor']).toList();
    if (monitors.isEmpty) return false;

    for (final monitorEntry in monitors) {
      final monitor = safeMap(monitorEntry.value);
      final connectedGpu = safeStr(monitor['Connected GPU']).toLowerCase();
      if (connectedGpu.isEmpty) continue;
      if (intelIntegratedGpus.any(
        (entry) => gpuNameMatches(
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

  /// 默认只匹配名称；配置构建可额外使用设备 ID 和厂商名别名。
  static bool gpuNameMatches(
    String connectedGpu,
    String fallbackName,
    Map<String, dynamic> gpu, {
    bool includeDeviceMetadata = false,
  }) {
    final aliases = [
      fallbackName,
      safeStr(gpu['Name']),
      if (includeDeviceMetadata) safeStr(gpu['Device ID']),
      safeStr(gpu['DeviceDesc']),
      safeStr(gpu['Device Description']),
      safeStr(gpu['Description']),
      if (includeDeviceMetadata) safeStr(gpu['Manufacturer']),
    ]
        .map((value) => value.toLowerCase().trim())
        .where((value) => value.isNotEmpty);

    return aliases.any(
      (alias) => connectedGpu == alias ||
          connectedGpu.contains(alias) ||
          alias.contains(connectedGpu),
    );
  }

  static String _searchText(String name, Map<String, dynamic> gpu) {
    return [
      name,
      safeStr(gpu['Name']),
      safeStr(gpu['DeviceDesc']),
      safeStr(gpu['Device Description']),
      safeStr(gpu['Description']),
      safeStr(gpu['Manufacturer']),
    ].join(' ').toLowerCase();
  }
}
