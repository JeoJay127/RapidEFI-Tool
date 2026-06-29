import 'package:rapidefi/pages/shared/widgets/markdown_tab_page.dart';
import 'package:flutter/material.dart';

class SSDTTabPage extends StatefulWidget {
  const SSDTTabPage({super.key});

  @override
  State<SSDTTabPage> createState() => _SSDTTabPageState();
}

class _SSDTTabPageState extends State<SSDTTabPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabItems = [
    MarkdownTabItem(title: '工具介绍', mdPath: 'assets/ssdt/SSDT-Guide.md'),
    MarkdownTabItem(title: '平台补丁', mdPath: 'assets/ssdt/平台补丁.md'),
    MarkdownTabItem(title: '声卡补丁', mdPath: 'assets/ssdt/声卡补丁.md'),
    MarkdownTabItem(title: '显卡仿冒', mdPath: 'assets/ssdt/显卡仿冒.md'),
    MarkdownTabItem(title: '屏蔽设备', mdPath: 'assets/ssdt/屏蔽设备.md'),
    MarkdownTabItem(title: '亮度补丁', mdPath: 'assets/ssdt/亮度补丁.md'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: _tabItems.length);
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownTabPage(
      items: _tabItems,
      tabController: _tabController,
      onLinkTap: (href) {
        final decoded = Uri.decodeFull(href);
        if (!decoded.endsWith('.md')) return false;
        final idx =
            _tabItems.indexWhere((item) => item.mdPath.endsWith(decoded));
        if (idx == -1) return false;
        _tabController.animateTo(idx);
        return true;
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
