import 'package:flutter/material.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_compatibility.dart';

import 'package:rapidefi/utils/hardware/analysis/hardware_utils.dart';
import 'package:rapidefi/pages/hardware/widgets/hardware_shared.dart';

class CpuSection extends StatelessWidget {
  final Map<String, dynamic> rawInfo;
  final bool detailed;

  const CpuSection(this.rawInfo, {super.key, this.detailed = false});

  @override
  Widget build(BuildContext context) {
    final data = rawInfo;
    return Column(children: [
      HardwareHeaderCard([_systemLine(data)]),
      const SizedBox(height: 6),
      HardwareSection('CPU', _cpuLines(data), note: cpuCompatibility(data)),
    ]);
  }

  String _systemLine(Map<String, dynamic> d) {
    final system = safeMap(d['System']);
    final board = safeMap(d['Motherboard']);
    final platform = safeStr(board['Platform'], fallback: 'Desktop');
    return joinNonEmpty([
      platform,
      safeStr(system['Caption']),
      '${safeStr(system['OSArchitecture'])} 位',
    ], '    ');
  }

  List<Widget> _cpuLines(Map<String, dynamic> d) {
    final cpus = safeList(d['CPU']);
    if (cpus.isEmpty) return [];
    final cpu = safeMap(cpus.first);
    final name = safeStr(cpu['Name']);
    final manufacturer = safeStr(cpu['Manufacturer']);
    final threads = safeStr(cpu['NumberOfLogicalProcessors']);
    String cores = '';

    if (name.toLowerCase().contains('amd') ||
        manufacturer.toLowerCase().contains('amd')) {
      cores = safeStr(cpu['NumberOfEnabledCore']);
    } else {
      cores = safeStr(cpu['NumberOfCores']);
    }

    final vt = isTruthy(cpu['VirtualizationFirmwareEnabled'])
        ? '虚拟化: 已启用'
        : '虚拟化: 未启用';
    return [
      HardwareLine([name, cpuCodename(cpu), '$cores核心$threads线程']),
      if (detailed) HardwareLine(['指令集: ${safeStr(cpu['SIMD Features'])}', vt]),
    ];
  }
}
