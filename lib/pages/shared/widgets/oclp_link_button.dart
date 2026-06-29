import 'package:fluent_ui/fluent_ui.dart' show FluentIcons;
import 'package:flutter/material.dart';
import 'package:rapidefi/widgets/link_button.dart';

class OclpLinkButton extends StatelessWidget {
  const OclpLinkButton({
    super.key,
    this.buttonText = '获取修改版OCLP',
  });

  static const url = 'https://github.com/JeoJay127/OCLP-X/releases';

  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 15),
          CustomLinkButton(
            url: url,
            buttonText: buttonText,
            icon: FluentIcons.open_source,
          ),
        ],
      ),
    );
  }
}
