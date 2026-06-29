import 'package:flutter/material.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_patch_item.dart';
import 'package:rapidefi/utils/config/presets/patches/acpi_patch.dart';
import 'package:rapidefi/utils/config/presets/sections/config_acpi.dart';

import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/scrollable_choice_list_panel.dart';

class AcpiSsdtWidget extends StatefulWidget {
  const AcpiSsdtWidget(
      {super.key, required this.acpi, required this.onChanged});
  final Acpi acpi;
  final ValueChanged onChanged;
  @override
  State<AcpiSsdtWidget> createState() => _AcpiSsdtWidgetState();
}

class _AcpiSsdtWidgetState extends State<AcpiSsdtWidget> {
  late List<String> choices;
  late List<String> selectedSsdtChoices;
  late List<AcpiPatchItem> selectedPatchChoices;

  @override
  void initState() {
    super.initState();
    initializeChoices();
  }

  @override
  void didUpdateWidget(covariant AcpiSsdtWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    initializeChoices();
  }

  void initializeChoices() {
    choices = ConfigAcpi.fixSSDTs.map((e) => e.note).toList();
    final pathToNoteMap = {for (var e in ConfigAcpi.fixSSDTs) e.path: e.note};

    selectedSsdtChoices = widget.acpi.acpiAddItems.map((e) {
      return (e.note.isNotEmpty) ? e.note : pathToNoteMap[e.path] ?? '';
    }).toList();
    selectedPatchChoices = AcpiPatch.patchChoicesList
        .where(
          (choice) => widget.acpi.acpiPatchItems.any(
            (selected) => _samePatch(choice, selected),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollableChoiceListPanel(
      children: [
        _buildSSDTChoiceList(),
        _buildPatchChoiceList(),
      ],
    );
  }

  Widget _buildPatchChoiceList() {
    return ChoiceList<AcpiPatchItem>(
      showTip: true,
      choices: AcpiPatch.patchChoicesList,
      selectedChoices: selectedPatchChoices,
      isMultipleSelection: true,
      allowToggle: true,
      subTitle: 'ACPI - Patch补丁',
      labelBuilder: (patch) => patch.note,
      onChanged: (value) {
        widget.onChanged.call(value.map((patch) => patch.copyWith()).toList());
      },
    );
  }

  Widget _buildSSDTChoiceList() {
    return ChoiceList(
      showTip: true,
      choices: choices,
      selectedChoices: selectedSsdtChoices,
      isMultipleSelection: true,
      allowToggle: true,
      subTitle: 'ACPI - SSDT补丁',
      onChanged: (value) {
        final fixAcpiItems =
            ConfigAcpi.fixSSDTs.where((e) => value.contains(e.note)).toList();
        widget.onChanged.call(fixAcpiItems);
      },
    );
  }

  bool _samePatch(AcpiPatchItem left, AcpiPatchItem right) {
    return _bytesEqual(left.find, right.find) &&
        _bytesEqual(left.replace, right.replace);
  }

  bool _bytesEqual(List<int>? left, List<int>? right) {
    if (identical(left, right)) return true;
    if (left == null || right == null || left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
