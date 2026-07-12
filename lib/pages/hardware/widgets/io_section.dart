import 'package:flutter/material.dart';
import 'package:rapidefi/pages/hardware/models/hardware_models.dart';
import 'package:rapidefi/pages/hardware/widgets/hardware_shared.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis.dart';

class IOSection extends StatelessWidget {
  final Map<String, dynamic> rawInfo;
  final bool detailed;

  const IOSection(this.rawInfo, {super.key, this.detailed = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _sdSection(),
      if (detailed) ...[
        const SizedBox(height: 6),
        _inputSection(),
      ],
    ]);
  }

  Widget _inputSection() {
    final lines = hardwareDevices(rawInfo['Input']).where((entry) {
      final device = safeMap(entry.value);
      final deviceId = safeStr(device['Device ID']);
      final deviceValue = safeStr(device['Device']);
      final acpiPath = safeStr(device['ACPI Path']);
      final pciPath = safeStr(device['PCI Path']);
      if (isBtSvcInput(device, deviceId, deviceValue, acpiPath, pciPath)) {
        return false;
      }
      return deviceValue.isNotEmpty ||
          acpiPath.isNotEmpty ||
          pciPath.isNotEmpty;
    }).map((entry) {
      final device = safeMap(entry.value);
      final deviceText =
          safeStr(device['Device'], fallback: safeStr(device['Device ID']));
      return HardwareDeviceBlock([
        HardwareLine([
          deviceDisplayName(entry.key, device),
          if (deviceText.isNotEmpty) '设备: $deviceText',
          if (safeStr(device['Device Type']).isNotEmpty)
            '类型: ${safeStr(device['Device Type'])}',
        ]),
        if (detailed) HardwarePathLine(device),
      ]);
    }).toList();
    if (lines.isEmpty) return const SizedBox.shrink();
    return HardwareSection('输入', lines);
  }

  Widget _sdSection() {
    final lines = sdCardEntries(rawInfo).map((entry) {
      final color = entry.compatibility.level == CompatibilityLevel.supported
          ? null
          : entry.compatibility.color;
      return HardwareDeviceBlock([
        HardwareLine([
          entry.name,
          entry.manufacturer,
          if (entry.deviceId.isNotEmpty) '设备ID: ${entry.deviceId}',
          if (entry.device.isNotEmpty) '设备: ${entry.device}',
          if (entry.readerName.isNotEmpty) '型号: ${entry.readerName}',
          if (entry.builtIn.isNotEmpty) '内建: ${entry.builtIn}',
        ], color: color),
        if (entry.serialNumber.isNotEmpty)
          HardwareLine(['序列号: ${entry.serialNumber}'], color: color),
        if (detailed) HardwarePathLine(entry.rawDevice, color: color),
      ]);
    }).toList();
    if (lines.isEmpty) return const SizedBox.shrink();
    return HardwareSection('SD卡', lines, note: sdCompatibility(rawInfo));
  }
}
