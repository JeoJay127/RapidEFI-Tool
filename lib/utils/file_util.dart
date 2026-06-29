import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rapidefi/utils/asset_util.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/device_util.dart';

import 'log/log.dart';

typedef ProgressCallback = void Function(double progress);

class FileUtils {
  const FileUtils._();

  static const String androidOutPutPath = '/storage/emulated/0';
  static const String androidOutPutFolderName = 'RapidEFI';
  static const String historyConfig = 'history_config';
  static Future<String>? _ocVersionTask;

  static bool exists(String filePath) => File(filePath).existsSync();

  static Future<String> getHistoryDirectory() => _PlatformPaths.history();

  static Future<String> getOCVerion({bool addOpenCoreHeader = false}) {
    return getOCVersion(addOpenCoreHeader: addOpenCoreHeader);
  }

  static Future<String> getOCVersion({bool addOpenCoreHeader = false}) async {
    final version = await (_ocVersionTask ??= _loadOCVersion());
    return addOpenCoreHeader ? 'OpenCore-$version' : version;
  }

  static Future<String> _loadOCVersion() async {
    final changelog =
        await rootBundle.loadString('assets/OpenCore/Docs/Changelog.md');
    final match = RegExp(
      r'####\s+(v\d+\.\d+\.\d+)\s+([\s\S]*?)(?=\n####|\Z)',
    ).firstMatch(changelog);
    final version = match?.group(1) ?? '';
    Log('当前OC版本: $version');
    return version;
  }

  static Future<void> copyAssetsAndUnzip(
    List<String> assetPaths,
    String destinationDirectory, {
    bool verifyIntegrity = false,
  }) async {
    final temporaryDirectory = await getTemporaryDirectory();
    for (final assetPath in assetPaths) {
      final copied = await AssetUtils.copyAssetsToDirectory(
        assetPath,
        temporaryDirectory.path,
        verifyIntegrity: verifyIntegrity,
        replaceExisting: verifyIntegrity,
      );
      if (!copied) continue;

      final zipFilePath = path.join(
        temporaryDirectory.path,
        path.basename(assetPath),
      );
      await unzipArchive(
        zipFilePath,
        destinationDirectory,
        deleteOriginalZip: true,
      );
    }
  }

  static Future<void> unzipArchive(
    String zipFilePath,
    String destinationDirectory, {
    ProgressCallback? onProgress,
    bool deleteOriginalZip = false,
  }) {
    return _ArchiveOps.unzip(
      zipFilePath,
      destinationDirectory,
      onProgress: onProgress,
      deleteOriginalZip: deleteOriginalZip,
    );
  }

  static Future<void> unzipArchives(
    List<String> zipFilePaths,
    String destinationDirectory, {
    ProgressCallback? onProgress,
    bool deleteOriginalZip = false,
  }) async {
    if (zipFilePaths.isEmpty) {
      onProgress?.call(1);
      return;
    }

    for (var i = 0; i < zipFilePaths.length; i++) {
      await unzipArchive(
        zipFilePaths[i],
        destinationDirectory,
        deleteOriginalZip: deleteOriginalZip,
        onProgress: (progress) {
          final completed = i / zipFilePaths.length;
          onProgress?.call(completed + progress / zipFilePaths.length);
        },
      );
    }
    onProgress?.call(1);
  }

  static Future<bool> compressFileOrFolder(
    String sourcePath, {
    String? outputPath,
    ProgressCallback? onProgress,
  }) {
    return _ArchiveOps.compress(
      sourcePath,
      outputPath: outputPath,
      onProgress: onProgress,
    );
  }

  static Future<void> deleteFile(String filePath) {
    return _FileSystemOps.delete(filePath);
  }

  static Future<void> deleteFilesAndDirectories(String entityPath) {
    return _FileSystemOps.delete(entityPath);
  }

  static Future<String> saveExecutableToApplicationSupportDirectory(
    Uint8List executableBytes,
    String executableName,
  ) async {
    final directory = await getApplicationSupportDirectory();
    final executablePath = path.join(directory.path, executableName);
    final executableFile = File(executablePath);
    await executableFile.parent.create(recursive: true);
    await executableFile.writeAsBytes(executableBytes, flush: true);
    return executablePath;
  }

  static Future<bool> copyFileToDirectory(
    String sourceFilePath,
    String outDirectory, {
    String? rename,
  }) {
    return _FileCopyOps.copyFileToDirectory(
      sourceFilePath,
      outDirectory,
      rename: rename,
    );
  }

  static Future<void> copyDirectory(
    Directory source,
    Directory destination,
  ) {
    return _FileCopyOps.copyDirectory(source, destination);
  }

  static Future<void> copyKext(
    String sourcePath,
    String destinationPath,
  ) {
    return _FileCopyOps.copyDirectoryByName(
      Directory(sourcePath),
      Directory(destinationPath),
      successMessage: 'Kext 复制成功',
    );
  }

  static Future<String> createDirectory(
    String directory,
    String folderName,
  ) {
    return _PlatformPaths.createDirectory(directory, folderName);
  }

  static Future<bool> requestManageExternalStoragePermission() {
    return _PlatformPaths.requestManageExternalStoragePermission();
  }

  static Future<String> getDefaultOutputDirectory() {
    return _PlatformPaths.defaultOutput();
  }

  static Future<String> openFileExplorer(String initialDirectory) {
    return _PickerOps.pickDirectory(initialDirectory);
  }

  static Future<bool> revealInFileExplorer(String targetPath) {
    return _PlatformPaths.reveal(targetPath);
  }

  static Future<String> openFile(
    String initialDirectory, {
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) {
    return _PickerOps.pickFile(
      initialDirectory,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
    );
  }

  static Future<bool> copyMultipleFilesToDirectory(
    List<String> filePaths,
    String destinationDirectory, {
    ProgressCallback? onProgress,
  }) {
    return _FileCopyOps.copyFilesToDirectory(
      filePaths,
      destinationDirectory,
      onProgress: onProgress,
    );
  }

  static Future<void> saveToFile({
    required String content,
    required String fileName,
    String? directoryPath,
  }) {
    return _ConfigFileOps.saveText(
      content: content,
      fileName: fileName,
      directoryPath: directoryPath,
    );
  }

  static Future<ConfigModel> readFromFile({
    required String directoryPath,
  }) {
    return _ConfigFileOps.readConfigModel(directoryPath);
  }
}

class _ArchiveOps {
  static Future<void> unzip(
    String zipFilePath,
    String destinationDirectory, {
    ProgressCallback? onProgress,
    bool deleteOriginalZip = false,
  }) async {
    final zipFile = File(zipFilePath);
    if (!await zipFile.exists()) {
      Log('ZIP文件不存在: $zipFilePath');
      return;
    }

    try {
      final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
      final entries = archive.where((entry) => !_isMacMetadata(entry.name));
      final total = entries.isEmpty ? 1 : entries.length;
      var processed = 0;

      for (final entry in entries) {
        final outputPath = _safeOutputPath(destinationDirectory, entry.name);
        if (outputPath == null) {
          processed++;
          continue;
        }

        if (entry.isFile) {
          final file = File(outputPath);
          await file.parent.create(recursive: true);
          await file
              .writeAsBytes(Uint8List.fromList(entry.content as List<int>));
        } else {
          await Directory(outputPath).create(recursive: true);
        }

        processed++;
        onProgress?.call((processed / total).clamp(0, 1));
      }

      if (deleteOriginalZip) {
        await zipFile.delete();
      }
      onProgress?.call(1);
      Log('$zipFilePath 文件成功解压');
    } catch (error) {
      Log('解压 $zipFilePath 文件时出错: $error');
    }
  }

  static Future<bool> compress(
    String sourcePath, {
    String? outputPath,
    ProgressCallback? onProgress,
  }) async {
    final sourceFile = File(sourcePath);
    final sourceDirectory = Directory(sourcePath);
    final sourceIsFile = await sourceFile.exists();
    final sourceIsDirectory = await sourceDirectory.exists();
    if (!sourceIsFile && !sourceIsDirectory) {
      Log('文件或目录不存在: $sourcePath');
      return false;
    }

    try {
      final archive = Archive();
      if (sourceIsFile) {
        await _addFile(archive, sourceFile, path.basename(sourcePath));
      } else {
        final files = await sourceDirectory
            .list(recursive: true, followLinks: false)
            .where((entity) => entity is File)
            .cast<File>()
            .toList();

        for (var i = 0; i < files.length; i++) {
          final relativePath = path.relative(files[i].path, from: sourcePath);
          await _addFile(archive, files[i], relativePath);
          onProgress?.call(files.isEmpty ? 1 : (i + 1) / files.length);
        }
      }

      final zipData = ZipEncoder().encode(archive);

      final outputDirectory = outputPath ?? path.dirname(sourcePath);
      final zipFileName = path.join(
        outputDirectory,
        '${path.basename(sourcePath)}.zip',
      );
      final zipFile = File(zipFileName);
      await zipFile.parent.create(recursive: true);
      await zipFile.writeAsBytes(zipData);
      onProgress?.call(1);
      Log('压缩完成: $zipFileName');
      return true;
    } catch (error) {
      Log('压缩出错: $error');
      return false;
    }
  }

  static Future<void> _addFile(
    Archive archive,
    File file,
    String archivePath,
  ) async {
    final bytes = await file.readAsBytes();
    archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
  }

  static bool _isMacMetadata(String name) {
    return name == '__MACOSX' || name.startsWith('__MACOSX/');
  }

  static String? _safeOutputPath(
      String destinationDirectory, String entryName) {
    if (path.isAbsolute(entryName)) return null;
    final normalized = path.normalize(entryName);
    if (normalized == '..' || normalized.startsWith('../')) return null;
    return path.join(destinationDirectory, normalized);
  }
}

class _FileSystemOps {
  static Future<void> delete(String entityPath) async {
    final type = await FileSystemEntity.type(entityPath);
    if (type == FileSystemEntityType.notFound) return;

    try {
      if (type == FileSystemEntityType.directory) {
        await Directory(entityPath).delete(recursive: true);
        Log('删除目录: $entityPath');
      } else {
        await File(entityPath).delete();
        Log('删除文件: $entityPath');
      }
    } catch (error) {
      Log('删除失败: $entityPath, $error');
    }
  }
}

class _FileCopyOps {
  static const int _chunkSize = 10 * 1024;

  static Future<bool> copyFileToDirectory(
    String sourceFilePath,
    String outDirectory, {
    String? rename,
  }) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        Log.error('源文件不存在: $sourceFilePath');
        return false;
      }

      final fileName = rename ?? path.basename(sourceFilePath);
      final outputPath = path.join(outDirectory, fileName);
      await Directory(outDirectory).create(recursive: true);
      await sourceFile.copy(outputPath);
      Log('文件已成功保存到: $outputPath');
      return true;
    } catch (error) {
      Log.error('保存文件时出错: $error');
      return false;
    }
  }

  static Future<void> copyDirectory(
    Directory source,
    Directory destination,
  ) async {
    if (!await source.exists()) {
      Log('源目录不存在: ${source.path}');
      return;
    }

    await destination.create(recursive: true);
    await for (final entity
        in source.list(recursive: true, followLinks: false)) {
      final relativePath = path.relative(entity.path, from: source.path);
      final targetPath = path.join(destination.path, relativePath);
      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      } else if (entity is File) {
        await File(targetPath).parent.create(recursive: true);
        await entity.copy(targetPath);
      }
    }
  }

  static Future<void> copyDirectoryByName(
    Directory source,
    Directory destinationParent, {
    String? successMessage,
  }) async {
    final target = Directory(
      path.join(destinationParent.path, path.basename(source.path)),
    );
    await copyDirectory(source, target);
    if (successMessage != null) {
      Log(successMessage);
    }
  }

  static Future<bool> copyFilesToDirectory(
    List<String> filePaths,
    String destinationDirectory, {
    ProgressCallback? onProgress,
  }) async {
    if (filePaths.isEmpty) {
      onProgress?.call(1);
      return true;
    }

    await Directory(destinationDirectory).create(recursive: true);
    for (var i = 0; i < filePaths.length; i++) {
      final source = File(filePaths[i]);
      if (!await source.exists()) return false;

      final target = File(
        path.join(destinationDirectory, path.basename(filePaths[i])),
      );
      await _copyWithProgress(
        source,
        target,
        onProgress: (progress) {
          final completed = i / filePaths.length;
          onProgress?.call(completed + progress / filePaths.length);
        },
      );
    }

    onProgress?.call(1);
    return true;
  }

  static Future<void> _copyWithProgress(
    File source,
    File target, {
    ProgressCallback? onProgress,
  }) async {
    await target.parent.create(recursive: true);
    final bytes = await source.readAsBytes();
    final sink = target.openWrite();
    var copiedBytes = 0;

    for (var offset = 0; offset < bytes.length; offset += _chunkSize) {
      final end = (offset + _chunkSize).clamp(0, bytes.length);
      sink.add(bytes.sublist(offset, end));
      copiedBytes += end - offset;
      onProgress?.call(bytes.isEmpty ? 1 : copiedBytes / bytes.length);
    }

    await sink.close();
  }
}

class _PlatformPaths {
  static Future<String> history() async {
    final directory = await getApplicationSupportDirectory();
    return path.join(directory.path, FileUtils.historyConfig);
  }

  static Future<String> createDirectory(
    String directory,
    String folderName,
  ) async {
    try {
      final newDirectory = Directory(path.join(directory, folderName));
      await newDirectory.create(recursive: true);
      Log('文件夹已准备: ${newDirectory.path}');
      return newDirectory.path;
    } catch (error) {
      Log('创建文件夹时出错: $error');
      return '';
    }
  }

  static Future<bool> requestManageExternalStoragePermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final status = androidInfo.version.sdkInt >= 30
        ? await Permission.manageExternalStorage.request()
        : await Permission.storage.request();
    return status.isGranted;
  }

  static Future<String> defaultOutput() async {
    if (Device.isMacOS || Device.isLinux) {
      return path.join(Platform.environment['HOME'] ?? '', 'Desktop');
    }
    if (Device.isWindows) {
      return path.join(Platform.environment['USERPROFILE'] ?? '', 'Desktop');
    }
    if (Device.isAndroid) {
      final access = await requestManageExternalStoragePermission();
      if (access) {
        return createDirectory(
          FileUtils.androidOutPutPath,
          FileUtils.androidOutPutFolderName,
        );
      }
      final directory = await getExternalStorageDirectory();
      return directory?.path ?? '';
    }
    return 'Web平台默认直接下载，暂不支持选择默认路径';
  }

  static Future<bool> reveal(String targetPath) async {
    if (targetPath.trim().isEmpty) return false;

    final directory = Directory(targetPath);
    final file = File(targetPath);
    final exists = await directory.exists() || await file.exists();
    if (!exists) {
      Log('打开目录失败，路径不存在: $targetPath');
      return false;
    }

    try {
      if (Device.isWindows) {
        await Process.start('explorer', [targetPath]);
        return true;
      }
      if (Device.isMacOS) {
        await Process.start('open', [targetPath]);
        return true;
      }
      if (Device.isLinux) {
        await Process.start('xdg-open', [targetPath]);
        return true;
      }
    } catch (error) {
      Log('打开目录失败: $targetPath, $error');
    }

    return false;
  }
}

class _PickerOps {
  static Future<String> pickDirectory(String initialDirectory) async {
    final selectedPath = await FilePicker.platform.getDirectoryPath(
      lockParentWindow: true,
      initialDirectory: initialDirectory.isEmpty ? null : initialDirectory,
    );
    return selectedPath ?? '';
  }

  static Future<String> pickFile(
    String initialDirectory, {
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    final hasExtensionFilter =
        allowedExtensions != null && allowedExtensions.isNotEmpty;
    final result = await FilePicker.platform.pickFiles(
      type: hasExtensionFilter ? FileType.custom : FileType.any,
      allowedExtensions: hasExtensionFilter ? allowedExtensions : null,
      allowMultiple: allowMultiple,
      initialDirectory: initialDirectory.isEmpty ? null : initialDirectory,
    );

    if (result == null || result.files.isEmpty) return '';
    return result.files.first.path ?? '';
  }
}

class _ConfigFileOps {
  static Future<void> saveText({
    required String content,
    required String fileName,
    String? directoryPath,
  }) async {
    final outputDirectory =
        directoryPath ?? await FileUtils.getDefaultOutputDirectory();
    final directory = Directory(outputDirectory);
    await directory.create(recursive: true);

    final file = File(path.join(directory.path, fileName));
    await file.writeAsString(content);
  }

  static Future<ConfigModel> readConfigModel(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      final jsonMap = jsonDecode(await file.readAsString());
      if (jsonMap is! Map<String, dynamic>) {
        throw const FormatException('配置文件根节点不是 JSON 对象');
      }
      _validateConfigModelJson(jsonMap);
      return ConfigModel.fromJson(jsonMap);
    } on FileSystemException catch (error) {
      throw Exception('文件系统错误: $error');
    } on FormatException catch (error) {
      throw Exception('JSON格式错误: $error');
    } catch (error) {
      throw Exception('未知错误: $error');
    }
  }

  static void _validateConfigModelJson(Map<String, dynamic> jsonMap) {
    const requiredKeys = [
      'cpuType',
      'platformType',
      'acpi',
      'booter',
      'deviceProperties',
      'kernel',
      'misc',
      'nvram',
      'platformInfo',
      'uefi',
    ];

    final missingKeys = requiredKeys.where((key) => !jsonMap.containsKey(key));
    if (missingKeys.isNotEmpty) {
      throw FormatException(
        '不是 RapidEFI configModel 文件，缺少字段: ${missingKeys.join(', ')}',
      );
    }
  }
}
