import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownViewer extends StatefulWidget {
  final String data;
  final String? basePath;
  final bool Function(String href)? onLinkTap;

  /// Markdown 正文字号
  final double fontSize;

  /// 代码字号
  final double codeFontSize;

  const MarkdownViewer({
    super.key,
    required this.data,
    this.basePath,
    this.onLinkTap,
    this.fontSize = 14,
    this.codeFontSize = 13,
  });

  @override
  State createState() => _MarkdownViewerState();
}

class _MarkdownViewerState extends State<MarkdownViewer> {
  final ScrollController _controller = ScrollController();

  String _resolveImagePath(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    final base = widget.basePath;
    if (base != null && !imagePath.startsWith('assets/')) {
      return '$base$imagePath';
    }
    return imagePath;
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.textTheme.bodyMedium?.color;

    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: TextStyle(
        fontSize: widget.fontSize,
        height: 1.55,
        color: baseColor,
      ),
      h1: TextStyle(
        fontSize: widget.fontSize + 10,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      h2: TextStyle(
        fontSize: widget.fontSize + 7,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      h3: TextStyle(
        fontSize: widget.fontSize + 4,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      h4: TextStyle(
        fontSize: widget.fontSize + 2,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      h5: TextStyle(
        fontSize: widget.fontSize,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      h6: TextStyle(
        fontSize: widget.fontSize,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      a: TextStyle(
        fontSize: widget.fontSize,
        height: 1.55,
        color: theme.colorScheme.primary,
      ),
      listBullet: TextStyle(
        fontSize: widget.fontSize,
        height: 1.55,
        color: baseColor,
      ),
      blockquote: TextStyle(
        fontSize: widget.fontSize,
        height: 1.55,
        color: baseColor?.withAlpha(210),
      ),
      code: TextStyle(
        fontSize: widget.codeFontSize,
        height: 1.45,
        fontFamily: 'monospace',
        color: baseColor,
      ),
      tableHead: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      tableBody: TextStyle(
        fontSize: widget.fontSize,
        color: baseColor,
      ),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String modified = widget.data.replaceAllMapped(
      RegExp(r'!\[([^\]]*)\]\(([^)]+)\)'),
      (match) {
        final alt = match.group(1)!;
        final rawPath = match.group(2)!;
        final resolved = _resolveImagePath(rawPath.trim());
        return '![$alt]($resolved)';
      },
    );

    modified = modified.replaceAllMapped(
      RegExp(r'<img\s+[^>]*src="([^"]+)"[^>]*/?\s*>', caseSensitive: false),
      (match) {
        final rawPath = match.group(1)!;
        final resolved = _resolveImagePath(rawPath.trim());
        return '![]($resolved)';
      },
    );

    final String modifiedMarkdownData = modified;

    return Markdown(
      data: modifiedMarkdownData,
      controller: _controller,
      sizedImageBuilder: customImageBuilder,
      styleSheet: _buildMarkdownStyleSheet(context),
      onTapLink: (text, href, title) {
        if (href == null) return;
        if (href.startsWith('#')) {
        } else if (widget.onLinkTap?.call(href) == true) {
        } else {
          launchURL(href);
        }
      },
    );
  }

  Widget customImageBuilder(MarkdownImageConfig config) {
    final uri = config.uri.toString();
    final isNetwork =
        config.uri.scheme == 'http' || config.uri.scheme == 'https';

    final imageWidget = isNetwork
        ? Image.network(uri,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) =>
                const Text('Failed to load image'))
        : Image.asset(uri,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) =>
                const Text('Failed to load image'));

    return GestureDetector(
      onTap: () => _showImageDialog(uri, isNetwork),
      child: imageWidget,
    );
  }

  void _showImageDialog(String url, bool isNetwork) {
    final ImageProvider provider;
    if (isNetwork) {
      provider = NetworkImage(url);
    } else {
      provider = AssetImage(url);
    }
    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: PhotoView(
          imageProvider: provider,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3.0,
          filterQuality: FilterQuality.high,
          backgroundDecoration: BoxDecoration(
            color: Colors.black.withAlpha(220),
          ),
        ),
      ),
    );
  }

  void launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}
