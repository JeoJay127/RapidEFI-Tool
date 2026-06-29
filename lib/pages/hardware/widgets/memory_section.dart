import 'package:flutter/material.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_utils.dart';
import 'package:rapidefi/pages/hardware/widgets/hardware_shared.dart';
import 'package:rapidefi/pages/hardware/models/hardware_models.dart';

class MemorySection extends StatelessWidget {
  final Map<String, dynamic> rawInfo;

  const MemorySection(this.rawInfo, {super.key});

  @override
  Widget build(BuildContext context) {
    final lines = safeList(rawInfo['Memory']).map((item) {
      final m = safeMap(item);
      return HardwareLine([
        fmtMem(m['Capacity']),
        memType(m['SMBIOSMemoryType']),
        '${safeStr(m['Speed'], fallback: safeStr(m['ConfiguredClockSpeed']))}MHz',
        safeStr(m['Manufacturer']),
        safeStr(m['DeviceLocator']),
      ], spacing: 10);
    }).toList();
    if (lines.isEmpty) return const SizedBox.shrink();
    return HardwareSection('内存', lines,
        note: CompatibilityNote.supported('兼容'));
  }
}
