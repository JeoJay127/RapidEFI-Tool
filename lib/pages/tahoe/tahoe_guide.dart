import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rapidefi/pages/shared/widgets/markdown_page.dart';

class TahoeGuide extends StatefulWidget {
  const TahoeGuide({super.key});

  @override
  State<TahoeGuide> createState() => _TahoeGuideState();
}

class _TahoeGuideState extends State<TahoeGuide> {
  @override
  Widget build(BuildContext context) {
    return MarkdownPage(
        showAppBar: true,
        title: "macOS Tahoe 26 指南",
        loadMarkdown: rootBundle.loadString,
        mdPath: 'assets/tahoe/tahoe.md');
  }
}
