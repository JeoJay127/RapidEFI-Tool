import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DoubleClickBackExitApp extends StatefulWidget {
  const DoubleClickBackExitApp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2500),
    this.tips,
  });

  final Widget child;
  final Function()? tips;

  /// 两次点击返回按钮的时间间隔
  final Duration duration;

  @override
  State<DoubleClickBackExitApp> createState() => _DoubleClickBackExitAppState();
}

class _DoubleClickBackExitAppState extends State<DoubleClickBackExitApp> {
  DateTime? _lastTime;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handleBackPressed();
      },
      child: widget.child,
    );
  }

  Future<void> _handleBackPressed() async {
    final now = DateTime.now();
    final lastTime = _lastTime;
    if (lastTime == null || now.difference(lastTime) > widget.duration) {
      _lastTime = now;
      widget.tips?.call();
      return;
    }
    await SystemNavigator.pop();
  }
}
