import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/title_card.dart';

class SettingsChoiceCard<T> extends StatelessWidget {
  const SettingsChoiceCard({
    super.key,
    required this.title,
    required this.choices,
    required this.selectedChoices,
    this.onChanged,
    this.isMultipleSelection = false,
    this.allowToggle = false,
    this.snippet,
  });

  final String title;
  final List<T> choices;
  final List<T> selectedChoices;
  final ValueChanged<List<T>>? onChanged;
  final bool isMultipleSelection;
  final bool allowToggle;
  final String? snippet;

  @override
  Widget build(BuildContext context) {
    return TitleCard(
      title: title,
      snippet: snippet,
      content: ChoiceList<T>(
        choices: choices,
        selectedChoices: selectedChoices,
        isMultipleSelection: isMultipleSelection,
        allowToggle: allowToggle,
        onChanged: onChanged,
      ),
    );
  }
}
