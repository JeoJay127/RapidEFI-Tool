//  logwidet.dart 
//  Created by JeoJay127 
//
import 'dart:async';
import 'package:flutter/material.dart';
import 'log.dart';

class LogWidget extends StatefulWidget {
  final List<String>? channels;
  final LogConfig? config;
  final bool allChannel;
  final bool showChannelTag;
  final Map<String, Color>? channelColors;

  const LogWidget({
    super.key,
    this.channels,
    this.config,
    this.allChannel = false,
    this.showChannelTag = false,
    this.channelColors,
  });

  @override
  State<LogWidget> createState() => _LogWidgetState();
}

class _LogWidgetState extends State<LogWidget> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<List<String>> _logs = ValueNotifier([]);
  final List<StreamSubscription<String>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    if (widget.allChannel) {
      _subscriptions.add(Log.logStreamAll.listen(_onNewLogLine));
    } else {
      final targetChannels = widget.channels ?? [Log.defaultChannel];
      for (final c in targetChannels) {
        _subscriptions.add(
          Log.width(channel: c).logStream.listen(_onNewLogLine),
        );
      }
    }
  }

  void _onNewLogLine(String line) {
    final maxLines =
        widget.config?.maxLines ??
        Log.channels[Log.defaultChannel]!.config.maxLines;

    final updated = List<String>.from(_logs.value);
    if (line.contains('[CLEARED]')) {
      updated.clear();
    } else {
      if (updated.length >= maxLines) updated.removeAt(0);
      updated.add(line);
    }
    _logs.value = updated;

    // 滚动到底部（节流可选）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.linearToEaseOut,
      );
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _scrollController.dispose();
    _logs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: _logs,
      builder: (_, logs, __) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(6),
          ),
          constraints: const BoxConstraints(
            minHeight: 200,
            minWidth: double.infinity,
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SelectableText.rich(
              TextSpan(
                children: logs
                    .map(
                      (log) => LogTextFormatter.format(
                        log,
                        config: widget.config,
                        channelColors: widget.channelColors,
                        showChannelTag: widget.showChannelTag,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LogTextFormatter {
  static const _timestampBase =
      r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?';
  static final _fullPattern = RegExp('$_timestampBase \\[.*?\\]');
  static final _timestampPattern = RegExp(_timestampBase);
  static final _levelPattern = RegExp('(?<=$_timestampBase) \\[.*?\\]');
  static final _levelExtractor = RegExp(r'\[(INFO|DEBUG|WARNING|ERROR)\]');

  static TextSpan format(
    String logText, {
    LogConfig? config,
    Map<String, Color>? channelColors,
    bool showChannelTag = false,
    double textSize = 11,
  }) {
    final channelName =
        RegExp(r'^\[([^\]]+)\]').firstMatch(logText)?.group(1) ??
        Log.defaultChannel;

    final channelColor =
        channelColors?[channelName] ?? _getChannelColor(channelName);
    final levelColor = _getLevelColor(logText);

    final logConfig =
        config ??
        Log.channels[channelName]?.config ??
        Log.channels[Log.defaultChannel]!.config;

    // 去掉 channel
    String processedText = logText.replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '');

    // 按配置裁剪
    if (!logConfig.includeLogTimestampForUI &&
        !logConfig.includeLogLevelForUI) {
      processedText = processedText.replaceFirst(_fullPattern, '');
    } else if (!logConfig.includeLogTimestampForUI) {
      processedText = processedText.replaceFirst(_timestampPattern, '');
    } else if (!logConfig.includeLogLevelForUI) {
      processedText = processedText.replaceFirst(_levelPattern, '');
    }

    return TextSpan(
      children: [
        if (showChannelTag)
          TextSpan(
            text: '[$channelName] ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: channelColor,
              fontSize: textSize,
            ),
          ),
        TextSpan(
          text: '$processedText\n',
          style: TextStyle(fontSize: textSize, color: levelColor),
        ),
      ],
    );
  }

  static Color _getChannelColor(String channel) {
    final hash = channel.hashCode % 360;
    return HSLColor.fromAHSL(1, hash.toDouble(), 0.7, 0.6).toColor();
  }

  static Color? _getLevelColor(String logText) {
    final match = _levelExtractor.firstMatch(logText);
    switch (match?.group(1)) {
      case 'DEBUG':
        return Colors.blue;
      case 'WARNING':
        return Colors.orange;
      case 'ERROR':
        return Colors.red;
      default:
        return null;
    }
  }
}
