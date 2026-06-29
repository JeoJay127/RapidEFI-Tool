import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/utils/config/models/booter/booter.dart';
import 'package:rapidefi/utils/config/models/booter/booter_quirk_type.dart';
import 'package:rapidefi/utils/config/models/booter/booter_quirks.dart';
import 'package:rapidefi/widgets/radio_option_group.dart';
import 'package:rapidefi/pages/shared/widgets/scrollable_choice_list_panel.dart';

class BooterWidget extends StatefulWidget {
  const BooterWidget({
    super.key,
    required this.booterQuirkTypes,
    required this.booter,
    required this.onChanged,
  });

  final List<BooterQuirkType> booterQuirkTypes;
  final Booter booter;
  final ValueChanged onChanged;

  @override
  State<BooterWidget> createState() => _BooterWidgetState();
}

class _BooterWidgetState extends State<BooterWidget> {
  static const String _schemeDefault = '方案一';
  static const String _schemeInverse = '方案二';
  static const String _schemeInverseWithVirtualMap = '方案三';
  static const String _schemeAllEnabled = '方案四';

  late List<String> choices;
  late List<String> selectedChoices;
  late BooterQuirks _defaultQuirks;
  String _selectedScheme = _schemeDefault;

  @override
  void initState() {
    super.initState();
    _defaultQuirks = widget.booter.booterQuirks.copyWith();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant BooterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.booter != widget.booter ||
        oldWidget.booterQuirkTypes != widget.booterQuirkTypes) {
      _defaultQuirks = widget.booter.booterQuirks.copyWith();
      _selectedScheme = _schemeDefault;
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    choices = widget.booterQuirkTypes.map((e) => e.comment).toList();
    selectedChoices = _selectedChoicesFromQuirks(widget.booter.booterQuirks);
  }

  void _applyScheme(String scheme) {
    final booterQuirks = switch (scheme) {
      _schemeInverse => _defaultQuirks.copyWith(
          enableWriteUnprotector: !_defaultQuirks.enableWriteUnprotector,
          rebuildAppleMemoryMap: !_defaultQuirks.rebuildAppleMemoryMap,
          syncRuntimePermissions: !_defaultQuirks.rebuildAppleMemoryMap,
        ),
      _schemeInverseWithVirtualMap => _defaultQuirks.copyWith(
          setupVirtualMap: !_defaultQuirks.setupVirtualMap,
        ),
      _schemeAllEnabled => _defaultQuirks.copyWith(
          enableWriteUnprotector: true,
          rebuildAppleMemoryMap: true,
          setupVirtualMap: true,
          syncRuntimePermissions: true,
        ),
      _ => _defaultQuirks.copyWith(),
    };

    setState(() {
      _selectedScheme = scheme;
      selectedChoices = _selectedChoicesFromQuirks(booterQuirks);
    });
    widget.onChanged.call(booterQuirks);
  }

  List<String> _selectedChoicesFromQuirks(BooterQuirks quirks) {
    final quirksMap = quirks.toQuirksMap();
    return widget.booterQuirkTypes
        .where((e) => quirksMap[e.name] == true)
        .map((e) => e.comment)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollableChoiceListPanel(
      child: ChoiceList(
        showTip: true,
        choices: choices,
        selectedChoices: selectedChoices,
        isMultipleSelection: true,
        allowToggle: true,
        header: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8.0,
            children: [
              const Text('卡EB修复(可选项 - 通常默认即可):'),
              RadioOptionGroup(
                groupValue: _selectedScheme,
                options: const [
                  RadioOptionData(value: _schemeDefault, label: _schemeDefault),
                  RadioOptionData(value: _schemeInverse, label: _schemeInverse),
                  RadioOptionData(
                    value: _schemeInverseWithVirtualMap,
                    label: _schemeInverseWithVirtualMap,
                  ),
                  RadioOptionData(
                    value: _schemeAllEnabled,
                    label: _schemeAllEnabled,
                  ),
                ],
                onChanged: _applyScheme,
              ),
            ],
          ),
        ),
        onChanged: (value) {
          final selectedQuirkTypes = widget.booterQuirkTypes
              .where((e) => value.contains(e.comment))
              .toList();

          final list = selectedQuirkTypes.map((e) => e.name).toList();

          final propertiesMap = {
            for (final property in list) property: true,
          };

          final booterQuirks = BooterQuirks.fromJson(propertiesMap);

          setState(() {
            selectedChoices = List<String>.from(value);
          });

          widget.onChanged.call(booterQuirks);
        },
      ),
    );
  }
}
