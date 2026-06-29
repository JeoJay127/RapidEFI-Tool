import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:rapidefi/pages/hardware/models/hardware_models.dart';

class HardwareStatusBar extends StatelessWidget {
  static const double _statusWidth = 112;
  static const double _elapsedWidth = 82;

  final String status;
  final bool isLoading;
  final double progress;
  final int elapsedMs;
  final String importedHardwarePath;
  final String importedAcpiTablesPath;
  final bool showProgressDetails;

  const HardwareStatusBar({
    super.key,
    required this.status,
    required this.isLoading,
    required this.progress,
    required this.elapsedMs,
    this.importedHardwarePath = '',
    this.importedAcpiTablesPath = '',
    this.showProgressDetails = false,
  });

  String get _elapsedSecs => (elapsedMs / 1000).toStringAsFixed(1);

  String get _statusText {
    if (importedHardwarePath.isEmpty) return status;
    final reportName = path.basename(importedHardwarePath);
    final acpiName = importedAcpiTablesPath.isEmpty
        ? '未导入 ACPI'
        : path.basename(importedAcpiTablesPath);
    return '硬件信息: $reportName / $acpiName';
  }

  @override
  Widget build(BuildContext context) {
    final colors = hardwareThemeColors(context);
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.transparent,
      child: Row(children: [
        if (showProgressDetails || isLoading) ...[
          SizedBox(
            width: _statusWidth,
            child: Text(_statusText,
                style: TextStyle(fontSize: 11, color: colors.textColor),
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.right),
          ),
          const SizedBox(width: 6),
          SizedBox(
              width: 108,
              height: 4,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(2), child: _bar(colors))),
          const SizedBox(width: 6),
          SizedBox(
            width: _elapsedWidth,
            child: Text('耗时 $_elapsedSecs 秒',
                style: TextStyle(fontSize: 11, color: colors.textColor)),
          ),
        ] else ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              _statusText,
              style: TextStyle(fontSize: 11, color: colors.textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const SizedBox(width: 18),
        const Expanded(child: _Legend()),
      ]),
    );
  }

  Widget _bar(HardwareThemeColors colors) {
    final value = isLoading ? progress : (progress == 0 ? 0.0 : 1.0);
    return Stack(fit: StackFit.expand, children: [
      ColoredBox(color: colors.progressTrack),
      FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: const DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF25C7B1), Color(0xFF2A91FF)])),
        ),
      ),
    ]);
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: TextStyle(fontSize: 11), children: [
        TextSpan(
            text: '绿色: 支持最新系统(macOS Tahoe 26)',
            style: TextStyle(color: Color(0xFF4CAF50))),
        TextSpan(text: '   '),
        TextSpan(text: '黄色：支持部分系统', style: TextStyle(color: Color(0xFFFFB627))),
        TextSpan(text: '   '),
        TextSpan(text: '红色：完全不兼容', style: TextStyle(color: Color(0xFFD94B4B))),
      ]),
    );
  }
}
