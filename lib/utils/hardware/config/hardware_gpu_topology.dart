import 'package:rapidefi/utils/hardware/analysis/gpu_compatibility_data.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis.dart';
import 'package:rapidefi/utils/hardware/data/gpu_codename_data.dart';
import 'package:rapidefi/utils/hardware/data/hardware_device_data.dart';

/// 统一识别自动配置流程中的核显与独显拓扑。
class HardwareGpuTopology {
  const HardwareGpuTopology._();

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
