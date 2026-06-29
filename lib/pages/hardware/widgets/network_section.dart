import 'package:flutter/material.dart';
import 'package:rapidefi/pages/hardware/models/hardware_models.dart';
import 'package:rapidefi/pages/hardware/widgets/hardware_shared.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis.dart';

class NetworkSection extends StatelessWidget {
  final Map<String, dynamic> rawInfo;
  final bool detailed;

  const NetworkSection(this.rawInfo, {super.key, this.detailed = false});

  @override
  Widget build(BuildContext context) {
    final lines = networkEntries(rawInfo).map((entry) {
      final color = entry.compatibility.level == CompatibilityLevel.supported
          ? null
          : entry.compatibility.color;
      return HardwareDeviceBlock([
        Wrap(
            spacing: 18,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SelectableText(
                joinNonEmpty(
                    [entry.name, '设备ID: ${entry.deviceId}', entry.displayType],
                    '    '),
                style: TextStyle(fontSize: 14, height: 1.25, color: color),
              ),
              if (entry.kext.isNotEmpty)
                SelectableText(entry.kext,
                    style: const TextStyle(
                        color: Color(0xFF4CAF50), fontSize: 13)),
            ]),
        if (detailed) HardwarePathLine(entry.rawDevice, color: color),
      ]);
    }).toList();
    if (lines.isEmpty) return const SizedBox.shrink();
    return HardwareSection('网卡', lines, note: networkCompatibility(rawInfo));
  }
}
