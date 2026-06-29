import 'package:flutter/material.dart';
import 'package:rapidefi/widgets/link_button.dart';

class LinkButtonItem {
  const LinkButtonItem({
    required this.url,
    required this.buttonText,
    this.icon,
  });

  final String url;
  final String buttonText;
  final IconData? icon;
}

class LinkButtonRow extends StatelessWidget {
  const LinkButtonRow({
    super.key,
    required this.items,
    this.spacing = 10,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final List<LinkButtonItem> items;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) SizedBox(width: spacing),
            CustomLinkButton(
              url: items[index].url,
              buttonText: items[index].buttonText,
              icon: items[index].icon,
            ),
          ],
        ],
      ),
    );
  }
}
