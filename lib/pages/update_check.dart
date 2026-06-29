//  update_check.dart
//  Created by JeoJay127
//
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:rapidefi/pages/shared/widgets/link_button_row.dart';
import 'package:rapidefi/pages/shared/widgets/markdown_viewer.dart';
import 'package:rapidefi/utils/app_info.dart';
import 'package:rapidefi/utils/log/log.dart';
import 'package:rapidefi/utils/update/repo_config.dart';
import 'package:rapidefi/utils/update/repo_context.dart';
import 'package:rapidefi/utils/update/repo_sevice.dart';
import 'package:rapidefi/widgets/inkwell_widget.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog._(this._ctx);
  final RepoContext _ctx;

  static Future<void> checkLatestRelease(
    BuildContext context, {
    bool silent = true,
    RepoConfig? config,
  }) async {
    final currentVersion = await AppInfo.version;
    await RepoService.instance.checkLatestRelease(
      currentVersion: currentVersion,
      config: config ?? RepoConfig.defaultConfig,
      silent: silent,
      onUpdateFound: (ctx, info) {
        if (!context.mounted) return;
        Log.info(info);
        _show(context, ctx);
      },
      onInfo: (info) {
        Log.info(info);
        if (!silent) showToast(info);
      },
      onError: (error) {
        Log.error(error);
        if (!silent) showToast(error);
      },
    );
  }

  static void _show(BuildContext context, RepoContext ctx) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => UpdateDialog._(ctx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final release = _ctx.release;
    final asset = release.assetForCurrentPlatform();
    final colorScheme = Theme.of(context).colorScheme;
    final bool darkMode = colorScheme.brightness == Brightness.dark;
    final backgroundColor = darkMode
        ? const Color.fromARGB(255, 63, 60, 60)
        : colorScheme.surfaceContainerHighest;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: backgroundColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  '${_ctx.repoConfig.repo}发现新版本',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 6),
              Text('版本号：${release.tag}'),
              Text('发布时间：${release.publishedAt}'),
              const Divider(height: 18, thickness: 0.2),
              Expanded(
                  child: MarkdownViewer(
                data: release.body,
                fontSize: 12,
                codeFontSize: 11,
              )),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  LinkButtonRow(
                    spacing: 8,
                    items: [
                      LinkButtonItem(
                        url: _ctx.repoConfig.releasesUrl,
                        buttonText: '访问 GitHub',
                      ),
                      if (asset != null)
                        LinkButtonItem(
                          url: asset.downloadUrl,
                          buttonText: '立即下载',
                        ),
                    ],
                  ),
                  InkWellWidget(
                    width: 60,
                    height: 32,
                    radius: 6,
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
