import 'package:flutter/material.dart';

class CategorizedTabView extends StatelessWidget {
  const CategorizedTabView({
    super.key,
    required this.controller,
    required this.tabs,
    required this.children,
    this.onTap,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.height = 40,
    this.indicatorSize = TabBarIndicatorSize.tab,
    this.indicatorWeight = 2,
    this.dividerHeight = 0,
    this.isScrollable = true,
    this.tabAlignment = TabAlignment.start,
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 15),
    this.labelStyle,
    this.unselectedLabelStyle,
    this.labelColor,
    this.unselectedLabelColor,
    this.tabBarTheme,
  });

  final TabController controller;
  final List<Widget> tabs;
  final List<Widget> children;
  final void Function(int)? onTap;
  final CrossAxisAlignment crossAxisAlignment;
  final double height;
  final TabBarIndicatorSize indicatorSize;
  final double indicatorWeight;
  final double? dividerHeight;
  final bool isScrollable;
  final TabAlignment? tabAlignment;
  final EdgeInsetsGeometry labelPadding;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final TabBarThemeData? tabBarTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Theme(
          data: tabBarTheme == null
              ? Theme.of(context)
              : Theme.of(context).copyWith(tabBarTheme: tabBarTheme),
          child: SizedBox(
            height: height,
            child: TabBar(
              controller: controller,
              indicatorSize: indicatorSize,
              indicatorWeight: indicatorWeight,
              dividerHeight: dividerHeight,
              isScrollable: isScrollable,
              tabAlignment: isScrollable ? tabAlignment : null,
              labelPadding: labelPadding,
              labelStyle: labelStyle,
              unselectedLabelStyle: unselectedLabelStyle,
              labelColor: labelColor,
              unselectedLabelColor: unselectedLabelColor,
              tabs: tabs,
              onTap: onTap,
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: children,
          ),
        ),
      ],
    );
  }
}
