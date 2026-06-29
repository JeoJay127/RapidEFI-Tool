//  permissions.dart
//  Created by JeoJay127
//
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 执行权限位
class ExecBits {
  static const int user = 0x40; // 0o100
  static const int group = 0x08; // 0o010
  static const int other = 0x01; // 0o001

  static const int any = user | group | other;
}

/// 文件状态指纹
@immutable
class _FileFingerprint {
  final int mtimeMs;
  final int size;
  final int mode;

  const _FileFingerprint({
    required this.mtimeMs,
    required this.size,
    required this.mode,
  });

  factory _FileFingerprint.fromStat(FileStat stat) {
    return _FileFingerprint(
      mtimeMs: stat.modified.millisecondsSinceEpoch,
      size: stat.size,
      mode: stat.mode,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _FileFingerprint &&
      other.mtimeMs == mtimeMs &&
      other.size == size &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(mtimeMs, size, mode);
}

/// 可执行权限管理器
class ExecutablePermissionManager {
  ExecutablePermissionManager._internal();

  static final ExecutablePermissionManager instance =
      ExecutablePermissionManager._internal();

  /// 路径,文件指纹
  final Map<String, _FileFingerprint> _processed = {};

  /// 路径锁,防止并发 chmod
  final Map<String, Completer<void>> _locks = {};

  /// 确保文件可执行
  Future<void> ensureExecutable(
    String filePath, {
    int execBits = ExecBits.user,

    /// 强制重新设置
    bool force = false,

    /// 只打日志不执行
    bool dryRun = false,

    Function(String)? onError,
    Function(String)? onLog,
  }) async {
    if (Platform.isWindows) return;

    final absPath = File(filePath).absolute.path;

    // 并发锁
    if (_locks.containsKey(absPath)) {
      await _locks[absPath]!.future;
      return;
    }

    final completer = Completer<void>();
    _locks[absPath] = completer;

    try {
      await _doEnsure(
        absPath,
        execBits: execBits,
        force: force,
        dryRun: dryRun,
        onError: onError,
        onLog: onLog,
      );
    } finally {
      _locks.remove(absPath);
      completer.complete();
    }
  }

  Future<void> _doEnsure(
    String absPath, {
    required int execBits,
    required bool force,
    required bool dryRun,
    Function(String)? onError,
    Function(String)? onLog,
  }) async {
    final file = File(absPath);

    if (!await file.exists()) {
      _log('文件不存在: $absPath', onError);
      return;
    }

    FileStat stat;
    try {
      stat = await file.stat();
    } catch (e) {
      _log('stat 失败: $e', onError);
      return;
    }

    final current = _FileFingerprint.fromStat(stat);

    final cached = _processed[absPath];

    final needProcess =
        force ||
        cached == null ||
        cached != current ||
        _permissionLost(stat.mode, execBits);

    if (!needProcess) {
      _log('未变化，跳过: $absPath', onLog);
      return;
    }

    final chmodArg = _bitsToChmod(execBits);

    _log('chmod $chmodArg $absPath', onLog);

    if (dryRun) {
      _processed[absPath] = current;
      return;
    }

    final result = await Process.run('chmod', [chmodArg, absPath]);

    if (result.exitCode != 0) {
      _log('chmod 失败(${result.exitCode}): ${result.stderr}', onError);
      return;
    }

    final newStat = await file.stat();

    if (_permissionLost(newStat.mode, execBits)) {
      _log('chmod 后权限仍不满足: $absPath', onError);
      return;
    }

    _processed[absPath] = _FileFingerprint.fromStat(newStat);

    _log('已设置可执行权限: $absPath', onLog);
  }

  bool _permissionLost(int mode, int execBits) {
    return (mode & execBits) != execBits;
  }

  String _bitsToChmod(int bits) {
    if (bits == ExecBits.any) return 'a+x';

    final parts = <String>[];

    if ((bits & ExecBits.user) != 0) parts.add('u+x');
    if ((bits & ExecBits.group) != 0) parts.add('g+x');
    if ((bits & ExecBits.other) != 0) parts.add('o+x');

    return parts.join(',');
  }

  void _log(String msg, Function(String)? fn) {
    debugPrint(msg);
    fn?.call(msg);
  }

  void clearCache() => _processed.clear();
}
