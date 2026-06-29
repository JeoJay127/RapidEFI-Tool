import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/tabbed_title_card.dart';
import 'package:rapidefi/widgets/state_keep_container.dart';

class ChoiceListCategory<T> {
  const ChoiceListCategory({
    required this.name,
    required this.choices,
    required this.selectedChoices,
    required this.onChanged,
    this.tips,
    this.labelBuilder,
  });

  final String name;
  final List<T> choices;
  final List<T> selectedChoices;
  final ValueChanged<List<T>> onChanged;
  final List<String>? tips;
  final String Function(T choice)? labelBuilder;
}

class CategorizedChoiceListCard<T> extends StatelessWidget {
  const CategorizedChoiceListCard({
    super.key,
    required this.title,
    required this.controller,
    required this.categories,
    this.subTitle,
    this.height = 400,
    this.isMultipleSelection = true,
    this.allowToggle = true,
  });

  final String title;
  final String? subTitle;
  final TabController controller;
  final List<ChoiceListCategory<T>> categories;
  final double height;
  final bool isMultipleSelection;
  final bool allowToggle;

  @override
  Widget build(BuildContext context) {
    return TabbedTitleCard(
      title: title,
      subTitle: subTitle,
      controller: controller,
      height: height,
      tabs: categories.map((category) => Tab(text: category.name)).toList(),
      children: categories.map(_buildCategoryChoiceList).toList(),
    );
  }

  Widget _buildCategoryChoiceList(ChoiceListCategory<T> category) {
    return StateKeepContainer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: ChoiceList<T>(
          tips: category.tips,
          choices: category.choices,
          selectedChoices: category.selectedChoices,
          isMultipleSelection: isMultipleSelection,
          allowToggle: allowToggle,
          labelBuilder: category.labelBuilder,
          onChanged: category.onChanged,
        ),
      ),
    );
  }
}
