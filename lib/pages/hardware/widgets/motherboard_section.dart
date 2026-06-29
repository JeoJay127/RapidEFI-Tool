import 'package:flutter/material.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_compatibility.dart';
import 'package:rapidefi/pages/hardware/models/hardware_models.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_utils.dart';
import 'package:rapidefi/pages/hardware/widgets/hardware_shared.dart';

class MotherboardSection extends StatelessWidget {
  final Map<String, dynamic> rawInfo;

  const MotherboardSection(this.rawInfo, {super.key});

  @override
  Widget build(BuildContext context) {
    final board = safeMap(rawInfo['Motherboard']);
    if (board.isEmpty) return const SizedBox.shrink();
    final mfr = safeStr(board['Manufacturer']);
    final brandCode = manufacturerBrandCode(mfr);
    final brandName = manufacturerBrandName(mfr);
    final brandText = brandName == null || brandName.toUpperCase() == brandCode
        ? brandCode
        : '$brandCode($brandName)';
    return HardwareSection(
        '主板',
        [
          HardwareLine([
            '品牌: $brandText',
            '型号: ${safeStr(board['Product'], fallback: safeStr(board['Model']))}',
            '设备ID: ${safeStr(board['Device ID'])}',
            '芯片组: ${chipsetName(board)}',
          ]),
        ],
        note: CompatibilityNote.supported('兼容'));
  }
}
