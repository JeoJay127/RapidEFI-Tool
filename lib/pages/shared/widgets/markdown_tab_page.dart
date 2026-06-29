import 'package:rapidefi/pages/shared/widgets/markdown_page.dart';
import 'package:rapidefi/pages/shared/widgets/categorized_tab_view.dart';
import 'package:rapidefi/widgets/state_keep_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MarkdownTabItem {
  final String title;
  final String mdPath;

  const MarkdownTabItem({required this.title, required this.mdPath});
}

class MarkdownTabPage extends StatefulWidget {
  final List<MarkdownTabItem> items;
  final bool Function(String href)? onLinkTap;
  final TabController? tabController;

  const MarkdownTabPage({
    super.key,
    required this.items,
    this.onLinkTap,
    this.tabController,
  });

  @override
  State<MarkdownTabPage> createState() => _MarkdownTabPageState();
}

class _MarkdownTabPageState extends State<MarkdownTabPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = widget.tabController ??
        TabController(vsync: this, length: widget.items.length);
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.items
        .map((e) => StateKeepContainer(
              child: MarkdownPage(
                mdPath: e.mdPath,
                loadMarkdown: rootBundle.loadString,
                onLinkTap: widget.onLinkTap,
              ),
            ))
        .toList();

    return Scaffold(
      body: CategorizedTabView(
        controller: _tabController,
        tabs: widget.items.map((item) => Tab(text: item.title)).toList(),
        crossAxisAlignment: CrossAxisAlignment.center,
        isScrollable: false,
        labelPadding: const EdgeInsets.only(left: 10, right: 10),
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelStyle: const TextStyle(fontSize: 16),
        tabBarTheme: const TabBarThemeData(
          dividerColor: Colors.transparent,
        ),
        children: children,
      ),
    );
  }

  @override
  void dispose() {
    if (widget.tabController == null) {
      _tabController.dispose();
    }
    super.dispose();
  }
}
