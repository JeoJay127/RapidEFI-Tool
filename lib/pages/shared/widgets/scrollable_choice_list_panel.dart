import 'package:flutter/material.dart';

class ScrollableChoiceListPanel extends StatelessWidget {
  const ScrollableChoiceListPanel({
    super.key,
    this.children = const [],
    this.child,
    this.padding = EdgeInsets.zero,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
    this.spacing = 0,
  }) : assert(
          child != null || children.length > 0,
          'child or children must be provided',
        );

  final List<Widget> children;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: child ??
          Column(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            spacing: spacing,
            children: children,
          ),
    );
  }
}
