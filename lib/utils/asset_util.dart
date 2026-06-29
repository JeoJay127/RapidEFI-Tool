import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import 'log/log.dart';

typedef ProgressCallback = void Function(double progress);

class AssetCopyOptions {
  const AssetCopyOptions({
    this.rename,
    this.replaceExisting = false,
    this.verifyIntegrity = false,
  });

  final String? rename;
  final bool replaceExisting;
  final bool verifyIntegrity;
}

class AssetUtils {
  const AssetUtils._();

  static Future<String> loadAssetAsString(String assetPath) {
    return rootBundle.loadString(assetPath);
  }

  static Future<Uint8List> loadAssetAsBytes(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  static Future<bool> copyAssetsToDirectory(
    String assetPath,
    String destinationDirectory, {
    ProgressCallback? onProgress,
    String? rename,
    bool replaceExisting = false,
    bool verifyIntegrity = false,
  }) {
    return _AssetCopyTask(
      assetPath: assetPath,
      destinationDirectory: destinationDirectory,
      options: AssetCopyOptions(
        rename: rename,
        replaceExisting: replaceExisting,
        verifyIntegrity: verifyIntegrity,
      ),
      onProgress: onProgress,
    ).run();
  }

  static Future<bool> copyMultipleAssetsToDirectory(
    List<String> assetPaths,
    String destinationDirectory, {
    ProgressCallback? onProgress,
    bool replaceExisting = false,
    bool verifyIntegrity = false,
  }) async {
    if (assetPaths.isEmpty) {
      onProgress?.call(1);
      return true;
    }

    for (var i = 0; i < assetPaths.length; i++) {
      final copied = await copyAssetsToDirectory(
        assetPaths[i],
        destinationDirectory,
        replaceExisting: replaceExisting,
        verifyIntegrity: verifyIntegrity,
        onProgress: (progress) {
          final completed = i / assetPaths.length;
          onProgress?.call(completed + progress / assetPaths.length);
        },
      );
      if (!copied) return false;
    }

    onProgress?.call(1);
    return true;
  }
}

class _AssetCopyTask {
  const _AssetCopyTask({
    required this.assetPath,
    required this.destinationDirectory,
    required this.options,
    this.onProgress,
  });

  static const int _chunkSize = 10 * 1024;

  final String assetPath;
  final String destinationDirectory;
  final AssetCopyOptions options;
  final ProgressCallback? onProgress;

  Future<bool> run() async {
    try {
      final bytes = await AssetUtils.loadAssetAsBytes(assetPath);
      final outputFile = _outputFile();
      await outputFile.parent.create(recursive: true);

      if (await _canReuseExisting(outputFile, bytes)) {
        onProgress?.call(1);
        return true;
      }

      await _writeBytes(outputFile, bytes);
      return true;
    } catch (error, stackTrace) {
      Log('复制资源失败: $assetPath -> $destinationDirectory, $error');
      Log(stackTrace.toString());
      return false;
    }
  }

  File _outputFile() {
    final fileName = options.rename ?? path.basename(assetPath);
    return File(path.join(destinationDirectory, fileName));
  }

  Future<bool> _canReuseExisting(File file, Uint8List assetBytes) async {
    if (!await file.exists()) return false;

    if (options.verifyIntegrity) {
      final existingBytes = await file.readAsBytes();
      if (_sameBytes(existingBytes, assetBytes)) {
        Log('${file.path} 已存在且内容一致，跳过复制');
        return true;
      }
      await file.delete();
      return false;
    }

    if (!options.replaceExisting) {
      Log('${file.path} 已存在，跳过复制');
      return true;
    }

    await file.delete();
    return false;
  }

  Future<void> _writeBytes(File file, Uint8List bytes) async {
    final sink = file.openWrite();
    var copiedBytes = 0;

    for (var offset = 0; offset < bytes.length; offset += _chunkSize) {
      final end = (offset + _chunkSize).clamp(0, bytes.length);
      sink.add(bytes.sublist(offset, end));
      copiedBytes += end - offset;
      onProgress?.call(bytes.isEmpty ? 1 : copiedBytes / bytes.length);
    }

    await sink.close();
    onProgress?.call(1);
  }

  bool _sameBytes(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }
}
