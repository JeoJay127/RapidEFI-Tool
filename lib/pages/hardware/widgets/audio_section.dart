import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:rapidefi/pages/hardware/models/hardware_models.dart';
import 'package:rapidefi/pages/hardware/widgets/hardware_shared.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis.dart';

class AudioSection extends StatefulWidget {
  final Map<String, dynamic> rawInfo;
  final bool detailed;
  final int? selectedAlcLayout;
  final ValueChanged<int>? onAlcLayoutChanged;

  const AudioSection(
    this.rawInfo, {
    super.key,
    this.detailed = false,
    this.selectedAlcLayout,
    this.onAlcLayoutChanged,
  });

  @override
  State<AudioSection> createState() => _AudioSectionState();
}

class _AudioSectionState extends State<AudioSection> {
  List<int> _alcLayouts = [];
  int? _selectedLayout;

  @override
  void initState() {
    super.initState();
    _parseAlc();
  }

  @override
  void didUpdateWidget(AudioSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rawInfo != oldWidget.rawInfo) {
      _parseAlc();
      setState(() {});
      return;
    }
    if (widget.selectedAlcLayout != oldWidget.selectedAlcLayout &&
        widget.selectedAlcLayout != null) {
      setState(() => _selectedLayout = widget.selectedAlcLayout);
    }
  }

  void _parseAlc() {
    final analysis = audioLayoutAnalysis(
      widget.rawInfo,
      preferredLayout: widget.selectedAlcLayout,
    );
    if (analysis == null) {
      _alcLayouts = [];
      _selectedLayout = null;
    } else if (widget.selectedAlcLayout == null) {
      _alcLayouts = analysis.layouts;
      _selectedLayout = analysis.selectedLayout;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAlcLayoutChanged?.call(analysis.layouts.first);
      });
    } else {
      _alcLayouts = analysis.layouts;
      _selectedLayout = analysis.selectedLayout;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = audioEntries(widget.rawInfo).where((entry) {
      return entry.deviceId.isNotEmpty;
    }).map((entry) {
      final compat = audioEntryCompatibility(entry);
      final color =
          compat.level == CompatibilityLevel.supported ? null : compat.color;
      return HardwareDeviceBlock([
        HardwareLine([
          entry.name,
          if (entry.deviceId.isNotEmpty) '设备ID: ${entry.deviceId}',
          if (entry.codecDeviceId.isNotEmpty)
            'Codec ID: ${entry.codecDeviceId}',
          if (entry.model.isNotEmpty) '型号: ${entry.model}',
        ], color: color),
        if (widget.detailed)
          HardwarePathLine({
            'ACPI Path': entry.acpiPath,
            'PCI Path': entry.pciPath,
          }, color: color),
      ]);
    }).toList();
    if (lines.isEmpty) return const SizedBox.shrink();

    final hasAlc = _alcLayouts.isNotEmpty;
    return HardwareSection(
      '声卡',
      lines,
      note: audioCompatibility(widget.rawInfo),
      trailing: hasAlc
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                  Text('布局ID:',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 5),
                  fluent.ComboBox<String>(
                    isExpanded: false,
                    value: _selectedLayout?.toString() ??
                        _alcLayouts.first.toString(),
                    items: _alcLayouts
                        .map((e) => fluent.ComboBoxItem(
                            value: e.toString(),
                            child: Text(e.toString(),
                                style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (v) {
                      final id = int.tryParse(v!);
                      setState(() => _selectedLayout = id);
                      widget.onAlcLayoutChanged?.call(id!);
                    },
                  ),
                ])
          : null,
    );
  }
}
