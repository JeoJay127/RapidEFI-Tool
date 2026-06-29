import 'package:flutter/material.dart';
import 'package:rapidefi/pages/hardware/models/hardware_models.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_utils.dart';
import 'package:rapidefi/pages/hardware/widgets/gpu_display_name.dart';
import 'package:rapidefi/pages/hardware/widgets/hardware_shared.dart';

class MonitorSection extends StatelessWidget {
  final Map<String, dynamic> rawInfo;

  const MonitorSection(this.rawInfo, {super.key});

  @override
  Widget build(BuildContext context) {
    final lines = safeMap(rawInfo['Monitor']).entries.expand((entry) {
      final m = safeMap(entry.value);
      final connectedGpu = safeStr(m['Connected GPU']);
      final connectedGpuDisplayName =
          hardwareConnectedGpuDisplayName(rawInfo, connectedGpu);
      return [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HardwareLine([
            '型号: ${entry.key}',
            '接口: ${safeStr(m['Connector Type'])}',
            '分辨率: ${safeStr(m['Resolution'])} @ ${safeStr(m['CurrentRefreshRate'])} Hz',
            safeStr(m['Size']).isEmpty ? '' : '(${safeStr(m['Size'])}英寸)',
          ]),
          Wrap(
              spacing: 12,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SelectableText('连接显卡: $connectedGpuDisplayName',
                    style: const TextStyle(fontSize: 14, height: 1.25)),
                HardwareCopy('EDID:', safeStr(m['EDID']), max: 28),
              ]),
        ]),
      ];
    }).toList();
    if (lines.isEmpty) return const SizedBox.shrink();
    return HardwareSection(
      '显示器',
      lines,
      note: CompatibilityNote.supported('兼容'),
    );
  }
}
