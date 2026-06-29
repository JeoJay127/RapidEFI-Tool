import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/formatters/kext_label.dart';
import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/title_card.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';

class KextChoiceList extends StatelessWidget {
  const KextChoiceList({
    super.key,
    required this.choices,
    this.selectedChoices = const [],
    this.onChanged,
    this.tips,
    this.tiplist = const [],
    this.showBundleNameTips = false,
    this.showTip = false,
    this.isMultipleSelection = false,
    this.allowToggle = true,
    this.title = '',
    this.subTitle = '',
    this.header = const SizedBox.shrink(),
    this.footer = const SizedBox.shrink(),
    this.width = double.infinity,
    this.initiallyExpanded = false,
    this.expandTitle,
    this.alwaysShowTitle = true,
    this.showBorder = false,
    this.labelBuilder = kextDescriptionLabel,
  });

  final List<KernelKext> choices;
  final List<KernelKext> selectedChoices;
  final ValueChanged<List<KernelKext>>? onChanged;
  final List<String>? tips;
  final List<String> tiplist;
  final bool showBundleNameTips;
  final bool showTip;
  final bool isMultipleSelection;
  final bool allowToggle;
  final String title;
  final String subTitle;
  final Widget header;
  final Widget footer;
  final double width;
  final bool initiallyExpanded;
  final String? expandTitle;
  final bool alwaysShowTitle;
  final bool showBorder;
  final String Function(KernelKext choice)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return ChoiceList<KernelKext>(
      tips: tips ??
          (showBundleNameTips
              ? choices.map(kextBundleNameLabel).toList()
              : null),
      choices: choices,
      selectedChoices: selectedChoices,
      isMultipleSelection: isMultipleSelection,
      allowToggle: allowToggle,
      showTip: showTip,
      tiplist: tiplist,
      title: title,
      subTitle: subTitle,
      header: header,
      footer: footer,
      width: width,
      initiallyExpanded: initiallyExpanded,
      expandTitle: expandTitle,
      alwaysShowTitle: alwaysShowTitle,
      showBorder: showBorder,
      labelBuilder: labelBuilder,
      onChanged: onChanged,
    );
  }
}

class KextChoiceListCard extends StatelessWidget {
  const KextChoiceListCard({
    super.key,
    required this.title,
    required this.choices,
    this.cardSubTitle,
    this.selectedChoices = const [],
    this.onChanged,
    this.tips,
    this.tiplist = const [],
    this.showBundleNameTips = false,
    this.showTip = false,
    this.isMultipleSelection = false,
    this.allowToggle = true,
    this.choiceTitle = '',
    this.choiceSubTitle = '',
    this.header = const SizedBox.shrink(),
    this.footer = const SizedBox.shrink(),
    this.width = double.infinity,
    this.initiallyExpandedChoiceList = false,
    this.expandTitle,
    this.alwaysShowTitle = true,
    this.showBorder = false,
    this.labelBuilder = kextDescriptionLabel,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? cardSubTitle;
  final List<KernelKext> choices;
  final List<KernelKext> selectedChoices;
  final ValueChanged<List<KernelKext>>? onChanged;
  final List<String>? tips;
  final List<String> tiplist;
  final bool showBundleNameTips;
  final bool showTip;
  final bool isMultipleSelection;
  final bool allowToggle;
  final String choiceTitle;
  final String choiceSubTitle;
  final Widget header;
  final Widget footer;
  final double width;
  final bool initiallyExpandedChoiceList;
  final String? expandTitle;
  final bool alwaysShowTitle;
  final bool showBorder;
  final String Function(KernelKext choice)? labelBuilder;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return TitleCard(
      title: title,
      subTitle: cardSubTitle,
      initiallyExpanded: initiallyExpanded,
      expander: KextChoiceList(
        choices: choices,
        selectedChoices: selectedChoices,
        onChanged: onChanged,
        tips: tips,
        tiplist: tiplist,
        showBundleNameTips: showBundleNameTips,
        showTip: showTip,
        isMultipleSelection: isMultipleSelection,
        allowToggle: allowToggle,
        title: choiceTitle,
        subTitle: choiceSubTitle,
        header: header,
        footer: footer,
        width: width,
        initiallyExpanded: initiallyExpandedChoiceList,
        expandTitle: expandTitle,
        alwaysShowTitle: alwaysShowTitle,
        showBorder: showBorder,
        labelBuilder: labelBuilder,
      ),
    );
  }
}
