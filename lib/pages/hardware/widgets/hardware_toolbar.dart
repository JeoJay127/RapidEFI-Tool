import 'package:flutter/material.dart';
import 'package:rapidefi/pages/hardware/models/hardware_models.dart';

class HardwareToolbar extends StatelessWidget {
  final bool isLoading;
  final bool detailed;
  final VoidCallback onRefresh;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onExportAcpi;
  final VoidCallback onOutputEfi;
  final VoidCallback onPersonalizedEfi;
  final ValueChanged<bool> onDetailedChanged;
  final String importedHardwarePath;
  final String importedAcpiTablesPath;
  final bool showHardwareActions;
  final bool showAcpiExportAction;

  const HardwareToolbar({
    super.key,
    required this.isLoading,
    required this.detailed,
    required this.onRefresh,
    required this.onImport,
    required this.onExport,
    required this.onExportAcpi,
    required this.onOutputEfi,
    required this.onPersonalizedEfi,
    required this.onDetailedChanged,
    this.importedHardwarePath = '',
    this.importedAcpiTablesPath = '',
    this.showHardwareActions = true,
    this.showAcpiExportAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (showHardwareActions) ...[
              _btn('刷新硬件信息', () => onRefresh(), isLoading),
              const SizedBox(width: 8),
            ],
            _btn('导入硬件资料', onImport, false),
            const SizedBox(width: 8),
            if (showHardwareActions) ...[
              _btn('导出硬件报告', onExport, false),
              const SizedBox(width: 8),
            ],
            if (showAcpiExportAction) ...[
              _btn('导出 ACPI 表', onExportAcpi, false),
              const SizedBox(width: 8),
            ],
            _btn('EFI设置', onPersonalizedEfi, false),
            const SizedBox(width: 8),
            _btn('输出EFI', onOutputEfi, false),
            const Spacer(),
            _segmentedSwitch(context),
          ]),
        ],
      ),
    );
  }

  Widget _btn(String text, VoidCallback onTap, bool disabled) {
    return SizedBox(
      width: 100,
      height: 30,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontSize: 13),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _segmentedSwitch(BuildContext context) {
    final colors = hardwareThemeColors(context);
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: colors.buttonColor,
        border: Border.all(color: colors.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _segment(context, '简要', !detailed, () => onDetailedChanged(false)),
        _segment(context, '详细', detailed, () => onDetailedChanged(true)),
      ]),
    );
  }

  Widget _segment(
      BuildContext context, String text, bool selected, VoidCallback onTap) {
    final colors = hardwareThemeColors(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.highlightColor : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : colors.textColor,
          ),
        ),
      ),
    );
  }
}
