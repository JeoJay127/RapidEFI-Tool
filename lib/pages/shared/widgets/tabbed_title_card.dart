import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/widgets/categorized_tab_view.dart';
import 'package:rapidefi/pages/shared/widgets/title_card.dart';

class TabbedTitleCard extends StatelessWidget {
  const TabbedTitleCard({
    super.key,
    required this.title,
    required this.controller,
    required this.tabs,
    required this.children,
    this.subTitle,
    this.content,
    this.height = 400,
    this.initiallyExpanded = false,
    this.onTap,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String title;
  final String? subTitle;
  final Widget? content;
  final TabController controller;
  final List<Widget> tabs;
  final List<Widget> children;
  final double height;
  final bool initiallyExpanded;
  final void Function(int)? onTap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return TitleCard(
      title: title,
      subTitle: subTitle,
      content: content,
      initiallyExpanded: initiallyExpanded,
      expander: SizedBox(
        height: height,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CategorizedTabView(
            controller: controller,
            tabs: tabs,
            onTap: onTap,
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          ),
        ),
      ),
    );
  }
}
