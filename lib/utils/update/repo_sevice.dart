//  repo_sevice.dart
//  Created by JeoJay127
//

import 'repo_checker.dart';
import 'repo_config.dart';
import 'repo_context.dart';

class RepoService {
  RepoService._({
    required this.checker,
    Duration minInterval = const Duration(seconds: 10),
  }) : _minInterval = minInterval;

  static RepoService? _instance;

  static RepoService get instance =>
      _instance ??= RepoService._(checker: RepoChecker());

  final RepoChecker checker;
  final Duration _minInterval;

  bool _isChecking = false;
  DateTime? _lastCheckTime;
  bool _lastResultHadUpdate = false;

  Future<void> checkLatestRelease({
    required String currentVersion,
    RepoConfig config = RepoConfig.defaultConfig,
    bool silent = true,
    void Function(RepoContext ctx, String info)? onUpdateFound,
    void Function(String info)? onInfo,
    void Function(String error)? onError,
  }) async {
    final now = DateTime.now();
    if (_isChecking) {
      if (!silent) {
        onInfo?.call('正在检查更新，请稍后...');
      }
      return;
    }

    if (_lastCheckTime != null &&
        !_lastResultHadUpdate &&
        now.difference(_lastCheckTime!) < _minInterval) {
      if (!silent) {
        onInfo?.call('刚刚已检查过更新，请稍后再试');
      }
      return;
    }

    _isChecking = true;

    try {
      final release = await checker.checkLatestRelease(
        config: config,
        currentVersion: currentVersion,
      );

      _lastCheckTime = now;
      _lastResultHadUpdate = release != null;

      if (release == null) {
        if (!silent) {
          onInfo?.call('当前 $currentVersion 已是最新版本');
        }
        return;
      }

      final ctx = RepoContext(repoConfig: config, release: release);

      onUpdateFound?.call(ctx, '发现新版本：${release.tag}');
      return;
    } catch (e) {
      if (!silent) {
        onError?.call('检查更新失败，请稍后重试');
      }
      rethrow;
    } finally {
      _isChecking = false;
    }
  }

  Future<void> checkReleases({
    RepoConfig config = RepoConfig.defaultConfig,
    bool silent = true,
    void Function(List? releases)? onReleaseFound,
    void Function(String info)? onInfo,
    void Function(String error)? onError,
  }) async {
    try {
      final releaseList = await checker.checkReleases(config: config);
      if (releaseList == null) {
        if (!silent) {
          onError?.call('获取发布版本列表失败，请稍后重试');
        }
        return;
      }
      if (releaseList.isEmpty) {
        if (!silent) {
          onInfo?.call('发布版本列表为空');
        }
        return;
      }
      onReleaseFound?.call(releaseList);
    } catch (e) {
      if (!silent) {
        onError?.call('发生错误：$e');
      }
      rethrow;
    }
  }
}
