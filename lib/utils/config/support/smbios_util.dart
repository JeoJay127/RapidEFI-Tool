import 'dart:io';

import 'package:flutter/services.dart';
import 'package:rapidefi/extension/string_extension.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi_generic.dart';
import 'package:rapidefi/utils/device_util.dart';
import 'package:rapidefi/utils/file_util.dart';
import 'package:rapidefi/utils/log/log.dart';
import 'package:uuid/uuid.dart';

class SMBIOSUtils {
  const SMBIOSUtils._();

  static Future<PlatformInfoGeneric> generate(
    PlatformInfoGeneric platformInfoGeneric,
  ) async {
    final result = platformInfoGeneric.copyWith();
    final executablePath = _macserialAssetPath();
    if (executablePath.isEmpty) {
      Log.error('Unsupported platform for macserial');
      result.systemUUID = const Uuid().v4().toUpperCase();
      return result;
    }

    final localExecutablePath = await _copyExecutable(executablePath);
    await _ensureExecutablePermission(localExecutablePath);
    await _fillSerials(result, localExecutablePath);
    result.systemUUID = await generateUUID();
    result.systemUUID = result.systemUUID.toUpperCase();
    return result;
  }

  static Future<String> generateUUID() async {
    if (Device.isWindows) {
      return const Uuid().v4();
    }

    try {
      final result = await Process.run('uuidgen', []);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
      Log.error('genUUID_stderr = ${result.stderr}');
    } catch (e) {
      Log.error('genUUID_Error: $e');
    }
    return const Uuid().v4();
  }

  static String _macserialAssetPath() {
    if (Device.isMacOS || Device.isIOS) {
      return 'assets/OpenCore/Utilities/macserial/macserial';
    }
    if (Device.isWindows) {
      return 'assets/OpenCore/Utilities/macserial/macserial.exe';
    }
    if (Device.isLinux || Device.isAndroid) {
      return 'assets/OpenCore/Utilities/macserial/macserial.linux';
    }
    return '';
  }

  static Future<String> _copyExecutable(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final executableBytes = data.buffer.asUint8List();
    return FileUtils.saveExecutableToApplicationSupportDirectory(
      executableBytes,
      assetPath.lastPathComponent,
    );
  }

  static Future<void> _ensureExecutablePermission(String executablePath) async {
    if (Device.isMacOS || Device.isLinux || Device.isAndroid) {
      await Process.run('chmod', ['+x', executablePath]);
    }
  }

  static Future<void> _fillSerials(
    PlatformInfoGeneric model,
    String executablePath,
  ) async {
    try {
      final result = await Process.run(
        executablePath,
        ['-m', model.systemProductName, '-n', '1'],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        Log('SMBIOS result = ${result.stderr}');
        return;
      }

      final values = result.stdout
          .toString()
          .replaceAll(' ', '')
          .split('|')
          .where((value) => value.isNotEmpty)
          .toList();
      if (values.length < 2) {
        Log('SMBIOS parse failed = ${result.stdout}');
        return;
      }

      model.systemSerialNumber = values.first;
      model.mlb = values.last.trim();
    } catch (e) {
      Log('SMBIOS Error: $e');
    }
  }
}
