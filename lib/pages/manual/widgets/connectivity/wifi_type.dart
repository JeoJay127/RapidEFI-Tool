import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/formatters/kext_label.dart';
import 'package:rapidefi/pages/shared/widgets/kext_choice_list.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';

class WifiTypeWidget extends StatefulWidget {
  const WifiTypeWidget({
    super.key,
    required this.choices,
    required this.selectedChoices,
    this.onChanged,
    this.expandTitle,
    this.isMultipleSelection = false,
    this.allowToggle = true,
    this.initiallyExpanded = false,
  });

  final List<KernelKext> choices;
  final List<KernelKext> selectedChoices;
  final String? expandTitle;
  final bool isMultipleSelection;
  final bool allowToggle;
  final bool initiallyExpanded;
  final ValueChanged<List<KernelKext>>? onChanged;

  @override
  State<WifiTypeWidget> createState() => _WifiTypeWidgetState();
}

class _WifiTypeWidgetState extends State<WifiTypeWidget> {
  late List<KernelKext> selectedChoices = List.of(widget.selectedChoices);

  @override
  void didUpdateWidget(covariant WifiTypeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChoices != widget.selectedChoices) {
      selectedChoices = List.of(widget.selectedChoices);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KextChoiceList(
      choices: widget.choices,
      selectedChoices: selectedChoices,
      isMultipleSelection: widget.isMultipleSelection,
      allowToggle: widget.allowToggle,
      expandTitle: widget.expandTitle,
      initiallyExpanded: widget.initiallyExpanded,
      labelBuilder: kextDescriptionLabel,
      header: const SizedBox(height: 10),
      onChanged: (List<KernelKext> value) {
        setState(() {
          selectedChoices = List.of(value);
        });
        widget.onChanged?.call(value);
      },
    );
  }
}
