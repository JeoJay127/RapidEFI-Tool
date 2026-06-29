import 'package:flutter/material.dart';
import 'package:rapidefi/utils/file_util.dart';
import 'package:rapidefi/utils/log/logwidet.dart';

class EfiBuildProgressHandle {
  EfiBuildProgressHandle._(this._context);

  final BuildContext _context;
  final ValueNotifier<List<String>> _manualLines =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<_EfiBuildProgressResult?> _result =
      ValueNotifier<_EfiBuildProgressResult?>(null);
  bool _closed = false;

  void addLine(String message) {
    if (_closed) return;
    _manualLines.value = [..._manualLines.value, message];
  }

  void complete({
    required bool success,
    required String outputPath,
    String? message,
  }) {
    if (_closed) return;
    _result.value = _EfiBuildProgressResult(
      success: success,
      outputPath: outputPath,
      message: message,
    );
  }

  void close() {
    _closed = true;
    if (Navigator.of(_context, rootNavigator: true).canPop()) {
      Navigator.of(_context, rootNavigator: true).pop();
    }
  }
}

class _EfiBuildProgressResult {
  const _EfiBuildProgressResult({
    required this.success,
    required this.outputPath,
    this.message,
  });

  final bool success;
  final String outputPath;
  final String? message;
}

class EfiBuildProgressDialog extends StatefulWidget {
  const EfiBuildProgressDialog({super.key, required this.handle});

  final EfiBuildProgressHandle handle;

  static EfiBuildProgressHandle show(BuildContext context) {
    final handle = EfiBuildProgressHandle._(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EfiBuildProgressDialog(handle: handle),
    );
    return handle;
  }

  @override
  State<EfiBuildProgressDialog> createState() => _EfiBuildProgressDialogState();
}

class _EfiBuildProgressDialogState extends State<EfiBuildProgressDialog> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = colorScheme.brightness == Brightness.dark;
    final dialogBackground =
        darkMode ? const Color(0xFF3A3A3A) : colorScheme.surface;
    final logBackground = darkMode
        ? const Color(0xFF303030)
        : colorScheme.surfaceContainerHighest;
    return ValueListenableBuilder<_EfiBuildProgressResult?>(
      valueListenable: widget.handle._result,
      builder: (context, result, _) {
        final running = result == null;
        final success = result?.success == true;
        final statusText = running
            ? '正在生成 EFI 与定制 SSDT，请稍后...'
            : result.message ??
                (success ? 'EFI 配置完成。' : 'EFI 配置失败，请检查输出路径或日志。');

        return AlertDialog(
          backgroundColor: dialogBackground,
          title: Text(
            running ? '正在配置 EFI' : (success ? '配置 EFI 成功' : '配置 EFI 失败'),
          ),
          content: SizedBox(
            width: 620,
            height: 390,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: running
                          ? const CircularProgressIndicator(strokeWidth: 2.5)
                          : Icon(
                              success
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              color: success ? Colors.green : colorScheme.error,
                              size: 22,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (result != null && result.outputPath.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SelectableText(
                    '输出目录: ${result.outputPath}',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Expanded(
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: logBackground,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child:
                          LogWidget(showChannelTag: false, allChannel: true)),
                ),
              ],
            ),
          ),
          actions: [
            if (success && result != null && result.outputPath.isNotEmpty)
              TextButton(
                onPressed: () {
                  final outputPath = result.outputPath;
                  widget.handle.close();
                  FileUtils.revealInFileExplorer(outputPath);
                },
                child: const Text('打开EFI目录'),
              ),
            TextButton(
              onPressed: widget.handle.close,
              child: Text(running ? '取消' : '关闭'),
            ),
          ],
        );
      },
    );
  }
}
