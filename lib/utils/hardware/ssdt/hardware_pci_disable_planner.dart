import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/hardware/analysis/gpu_compatibility_data.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis.dart';
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

    for (final entry in hardwareDevices(data['GPU'])) {
      final gpu = safeMap(entry.value);
      if (!_isDiscreteGpu(entry.key, gpu)) continue;
      if (gpuEntryCompatibility(data, entry.key, gpu).level !=
          CompatibilityLevel.unsupported) {
        continue;
      }
      add(
        AcpiDeviceBlockPlan(
          name: deviceDisplayName(entry.key, gpu),
          acpiPath: safeStr(gpu['ACPI Path']),
          type: 'GPU',
          deviceId: _normalizeDeviceId(gpu['Device ID']),
        ),
      );
    }

    if (cpuType == CpuType.intel &&
        platformType == PlatformType.laptop &&
        _intelIgpuDrivesDisplay(data)) {
      for (final entry in hardwareDevices(data['GPU'])) {
        final gpu = safeMap(entry.value);
        if (!_isDiscreteGpu(entry.key, gpu)) continue;
        add(
          AcpiDeviceBlockPlan(
            name: deviceDisplayName(entry.key, gpu),
            acpiPath: safeStr(gpu['ACPI Path']),
            type: 'GPU',
            deviceId: _normalizeDeviceId(gpu['Device ID']),
          ),
        );
      }
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

  bool _isDiscreteGpu(String name, Map<String, dynamic> gpu) {
    final id = _normalizeDeviceId(gpu['Device ID']);
    final type = safeStr(gpu['Device Type']).toLowerCase();
    if (type == 'integrated' ||
        type.contains('integrated') ||
        type.contains('核显') ||
        type.contains('核心')) {
      return false;
    }
    if (type == 'discrete' || type.contains('独立')) return true;
    if (type == 'integrated' || type.contains('核显')) return false;

    final text = [
      name,
      safeStr(gpu['Name']),
      safeStr(gpu['DeviceDesc']),
      safeStr(gpu['Device Description']),
      safeStr(gpu['Description']),
      safeStr(gpu['Manufacturer']),
    ].join(' ').toLowerCase();

    if (id.startsWith('1002-')) {
      return !text.contains('radeon graphics') &&
          !text.contains('radeon(tm) graphics') &&
          !text.contains('radeon vega');
    }
    if (id.startsWith('10DE-')) return true;

    return text.contains('radeon rx') ||
        text.contains('radeon hd') ||
        text.contains('radeon r9') ||
        text.contains('radeon r7') ||
        text.contains('radeon pro') ||
        text.contains('firepro') ||
        text.contains('geforce') ||
        text.contains('quadro');
  }

  bool _intelIgpuDrivesDisplay(Map<String, dynamic> data) {
    final intelIntegratedGpus = hardwareDevices(data['GPU'])
        .where((entry) {
          final gpu = safeMap(entry.value);
          return _isIntegratedIntelGpu(entry.key, gpu);
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

  bool _isIntegratedIntelGpu(String name, Map<String, dynamic> gpu) {
    final id = _normalizeDeviceId(gpu['Device ID']);
    final manufacturer = safeStr(gpu['Manufacturer']).toLowerCase();
    final type = safeStr(gpu['Device Type']).toLowerCase();
    final text = [
      name,
      safeStr(gpu['Name']),
      safeStr(gpu['DeviceDesc']),
      safeStr(gpu['Device Description']),
      safeStr(gpu['Description']),
      manufacturer,
    ].join(' ').toLowerCase();

    final intel = id.startsWith('8086-') ||
        manufacturer.contains('intel') ||
        text.contains('intel');
    if (!intel) return false;
    if (type.contains('discrete') || type.contains('独立')) {
      return false;
    }
    if (type.contains('integrated') || type.contains('核显')) {
      return true;
    }
    return text.contains('uhd graphics') ||
        text.contains('iris') ||
        text.contains('hd graphics');
  }

  bool _gpuNameMatches(
    String connectedGpu,
    String fallbackName,
    Map<String, dynamic> gpu,
  ) {
    final aliases = [
      fallbackName,
      safeStr(gpu['Name']),
      safeStr(gpu['DeviceDesc']),
      safeStr(gpu['Device Description']),
      safeStr(gpu['Description']),
    ]
        .map((value) => value.toLowerCase().trim())
        .where((value) => value.isNotEmpty);

    return aliases.any(
      (alias) => connectedGpu == alias ||
          connectedGpu.contains(alias) ||
          alias.contains(connectedGpu),
    );
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
