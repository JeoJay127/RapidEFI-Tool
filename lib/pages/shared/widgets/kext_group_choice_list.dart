import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/formatters/kext_label.dart';
import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/models/kernel/kext_group.dart';

class KextGroupChoiceList extends StatelessWidget {
  const KextGroupChoiceList({
    super.key,
    required this.choices,
    required this.selectedKexts,
    this.onChanged,
    this.subTitle = '',
    this.isMultipleSelection = false,
    this.allowToggle = true,
    this.labelBuilder = kextGroupTitleDescriptionLabel,
  });

  final List<KextGroup> choices;
  final List<KernelKext> selectedKexts;
  final ValueChanged<List<KernelKext>>? onChanged;
  final String subTitle;
  final bool isMultipleSelection;
  final bool allowToggle;
  final String Function(KextGroup group)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final removableKexts = KextGroup.expand(choices);
    return ChoiceList<KextGroup>(
      choices: choices,
      selectedChoices: KextGroup.selectedByExactCoveredSet(
        groups: choices,
        selectedKexts: selectedKexts,
        removableKexts: removableKexts,
      ),
      isMultipleSelection: isMultipleSelection,
      allowToggle: allowToggle,
      subTitle: subTitle,
      labelBuilder: labelBuilder,
      onChanged: (value) {
        onChanged?.call(KextGroup.expand(value));
      },
    );
  }
}
