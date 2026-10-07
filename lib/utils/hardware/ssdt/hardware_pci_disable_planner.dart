import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/hardware/analysis/gpu_compatibility_data.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis.dart';
import 'package:rapidefi/utils/hardware/config/hardware_gpu_topology.dart';
import 'package:rapidefi/utils/log/log.dart';
import 'package:rapidefi/utils/ssdttool/table.dart';

class AcpiDeviceBlockPlan {
  const AcpiDeviceBlockPlan({
    required this.name,
    required this.acpiPath,
    required this.type,
    required this.deviceId,
  });

  final String name;
  final String acpiPath;
  final String type;
  final String deviceId;

  String amlName(String disableMethod) => 'SSDT-$type-DISABLE-$disableMethod';

  Map<String, dynamic> action(String disableMethod) => {
        'name': ACPITable.ssdtPCIDISABLE.name,
        'remark': '$name $type disable via $disableMethod',
        'extra': {
          'acpiPath': acpiPath,
          'disableMethod': disableMethod,
          'type': type,
        },
        'prebuilt': false,
      };
}

class AcpiDeviceBlockPlanner {
  const AcpiDeviceBlockPlanner();

  List<AcpiDeviceBlockPlan> targets(
    Map<String, dynamic>? rawInfo, {
    CpuType? cpuType,
    PlatformType? platformType,
  }) {
    final data = rawInfo ?? const <String, dynamic>{};
    final targets = <AcpiDeviceBlockPlan>[];
    final seen = <String>{};

    void add(AcpiDeviceBlockPlan target) {
      if (!_isValidAcpiPath(target.acpiPath)) {
        Log.warning(
          '设备屏蔽跳过: '
          '${target.type} ${target.name} ${target.deviceId} '
          '缺少有效 ACPI Path',
        );
        return;
      }

      final key = '${target.type}:${target.acpiPath}';
      if (!seen.add(key)) return;
      targets.add(target);
    }

    final unsupportedGpuTargets = <AcpiDeviceBlockPlan>[];
    final otherGpuTargets = <AcpiDeviceBlockPlan>[];
    for (final entry in hardwareDevices(data['GPU'])) {
      final gpu = safeMap(entry.value);
      if (!HardwareGpuTopology.shouldDisableDiscreteGpu(
        data,
        entry.key,
        gpu,
        cpuType: cpuType,
        platformType: platformType,
      )) {
        continue;
      }
      final gpuTargets =
          gpuEntryCompatibility(data, entry.key, gpu).level ==
                  CompatibilityLevel.unsupported
              ? unsupportedGpuTargets
              : otherGpuTargets;
      gpuTargets.add(
        AcpiDeviceBlockPlan(
          name: deviceDisplayName(entry.key, gpu),
          acpiPath: safeStr(gpu['ACPI Path']),
          type: 'GPU',
          deviceId: _normalizeDeviceId(gpu['Device ID']),
        ),
      );
    }
    for (final target in [...unsupportedGpuTargets, ...otherGpuTargets]) {
      add(target);
    }

    for (final entry in storageControllerEntries(data)) {
      if (!entry.isNvme ||
          entry.compatibility.level != CompatibilityLevel.unsupported) {
        continue;
      }
      add(
        AcpiDeviceBlockPlan(
          name: entry.name,
          acpiPath: safeStr(entry.rawDevice['ACPI Path']),
          type: 'NVME',
          deviceId: _normalizeDeviceId(entry.deviceId),
        ),
      );
    }

    for (final entry in networkEntries(data)) {
      if (entry.compatibility.level != CompatibilityLevel.unsupported) {
        continue;
      }
      add(
        AcpiDeviceBlockPlan(
          name: entry.name,
          acpiPath: safeStr(entry.rawDevice['ACPI Path']),
          type: 'PCI',
          deviceId: _normalizeDeviceId(entry.deviceId),
        ),
      );
    }

    for (final entry in sdCardEntries(data)) {
      if (entry.compatibility.level != CompatibilityLevel.unsupported) {
        continue;
      }
      add(
        AcpiDeviceBlockPlan(
          name: entry.name,
          acpiPath: safeStr(entry.rawDevice['ACPI Path']),
          type: 'PCI',
          deviceId: _normalizeDeviceId(entry.deviceId),
        ),
      );
    }

    return targets;
  }

  List<String> disableMethods(PlatformType platformType) {
    return platformType == PlatformType.laptop
        ? const ['OFF', 'PS3', 'IOName']
        : const ['IOName'];
  }

  String _normalizeDeviceId(Object? value) {
    return GpuCompatibilityData.normalizeFullDeviceId(value?.toString())
        .toUpperCase();
  }

  bool _isValidAcpiPath(String value) {
    final path = value.trim();
    if (path.isEmpty) return false;
    return RegExp(r'^\\?_SB_?(?:\.[A-Z0-9_]{1,4})*$').hasMatch(path);
  }
}
