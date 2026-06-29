import 'package:rapidefi/utils/hardware/analysis/gpu_compatibility_data.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_utils.dart';

String hardwareGpuDisplayName(
  String fallbackName,
  Map<String, dynamic> gpu, {
  GpuCompatibilityRecord? record,
}) {
  final isIntegratedGpu = gpu['Device Type'] == '核心显卡';
  final compatibilityRecord =
      record ?? GpuCompatibilityData.findSync(safeStr(gpu['Device ID']));

  if (isIntegratedGpu &&
      compatibilityRecord != null &&
      compatibilityRecord.name.isNotEmpty) {
    return compatibilityRecord.name;
  }

  return fallbackName;
}

String hardwareConnectedGpuDisplayName(
  Map<String, dynamic> rawInfo,
  String connectedGpuName,
) {
  final normalizedConnectedGpuName =
      normalizeHardwareGpuDisplayName(connectedGpuName);
  if (normalizedConnectedGpuName.isEmpty) return connectedGpuName;

  for (final entry in hardwareDevices(rawInfo['GPU'])) {
    final gpu = safeMap(entry.value);
    final aliases = <String>{
      entry.key,
      safeStr(gpu['Name']),
      safeStr(gpu['DeviceDesc']),
    }.map(normalizeHardwareGpuDisplayName).where((name) => name.isNotEmpty);

    if (!aliases.contains(normalizedConnectedGpuName)) {
      continue;
    }

    final record = GpuCompatibilityData.findSync(safeStr(gpu['Device ID']));
    return hardwareGpuDisplayName(entry.key, gpu, record: record);
  }

  return connectedGpuName;
}

String normalizeHardwareGpuDisplayName(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\((tm|r)\)|\b(tm|r)\b'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
