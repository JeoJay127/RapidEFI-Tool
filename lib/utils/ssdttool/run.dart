//  run.dart 
//  Created by JeoJay127 
//
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'permissions.dart';

class Run {
  
  /// 执行指定命令
  Future<List<String>> _executeCommand(Map<String, dynamic> comm) async {
    List<String> args = List<String>.from(comm['args'] ?? []);
    bool shell = comm['shell'] ?? false;
    bool sudo = comm['sudo'] ?? false;
    String? workingDir = comm['workingDirectory'];
    Map<String, String>? environment =
        (comm['environment'] as Map?)?.cast<String, String>() ?? {};
    var message = comm['message'];
    var show = comm['show'] ?? false;

    if (args.isEmpty) return ['No command', '', '1'];

    if (message != null) debugPrint('$message');
    if (show) debugPrint('执行命令: ${args.join(' ')}');

    await ExecutablePermissionManager.instance.ensureExecutable(args.first);

    if (sudo && !Platform.isWindows && !shell) {
      final whichSudo = await Process.run('which', ['sudo']);
      if (whichSudo.exitCode == 0) {
        args = ['sudo', ...args];
      }
    }

    final executable = shell ? (Platform.isWindows ? 'cmd' : 'sh') : args.first;
    final execArgs = shell
        ? [Platform.isWindows ? '/c' : '-c', args.join(' ')]
        : args.sublist(1);

    try {
      final process = await Process.start(
        executable,
        execArgs,
        workingDirectory: workingDir,
        environment: environment,
        runInShell: false,
        mode: ProcessStartMode.normal,
      );

      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      final stdoutSub = process.stdout
          .transform(utf8.decoder)
          .listen(stdoutBuffer.write);
      final stderrSub = process.stderr
          .transform(utf8.decoder)
          .listen(stderrBuffer.write);

      final exitCode = await process.exitCode;

      await stdoutSub.cancel();
      await stderrSub.cancel();

      return [
        stdoutBuffer.toString().trim(),
        stderrBuffer.toString().trim(),
        exitCode.toString(),
      ];
    } catch (e) {
      debugPrint('命令执行失败: $e');
      return ['', 'Error: $e', '1'];
    }
  }

  /// 并发执行多个命令
  Future<List<String>> run(List<Map<String, dynamic>> commandList) async {
    final futures = <Future<List<String>>>[];
    for (var command in commandList) {
      futures.add(_executeCommand(command));
    }
    final results = await Future.wait(futures);

    if (results.isEmpty) {
      return ['', '', '1'];
    }
    return results.first;
  }
}
