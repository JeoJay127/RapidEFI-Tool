import 'package:rapidefi/pages/shared/widgets/markdown_tab_page.dart';
import 'package:flutter/material.dart';

class OCLPTabPage extends StatelessWidget {
  const OCLPTabPage({super.key});

  static const _tabItems = [
    MarkdownTabItem(title: '工具介绍', mdPath: 'assets/oclp/introduction.md'),
    MarkdownTabItem(title: '显卡补丁', mdPath: 'assets/oclp/gpu.md'),
    MarkdownTabItem(title: 'WiFi补丁', mdPath: 'assets/oclp/wifi.md'),
  ];

  @override
  Widget build(BuildContext context) {
    return const MarkdownTabPage(items: _tabItems);
  }
}
