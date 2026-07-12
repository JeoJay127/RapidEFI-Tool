import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rapidefi/extension/bool_extension.dart';
import 'package:rapidefi/extension/int_extension.dart';
import 'package:rapidefi/pages/history/history_event_notifier.dart';
import 'package:rapidefi/pages/history/model/history_model.dart';
import 'package:rapidefi/utils/asset_util.dart';
import 'package:rapidefi/utils/config/build/config_draft.dart';
import 'package:rapidefi/utils/config/build/efi_asset_plan.dart';
import 'package:rapidefi/utils/config/services/config_service.dart';
import 'package:rapidefi/utils/constant.dart';
import 'package:rapidefi/utils/file_util.dart';
import 'package:sp_util/sp_util.dart';

class EfiExporter {
  const EfiExporter(this.configService);

  final ConfigService configService;

  Future<bool> export({
    required ConfigDraft draft,
    required EfiAssetPlan assetPlan,
  }) async {
    final acpiFileBytes = await _cacheFiles(assetPlan.acpiFiles);

    for (final path in assetPlan.cleanupPaths) {
      await FileUtils.deleteFilesAndDirectories(path);
    }

    final acpiDirectory = join(draft.ocPath, 'ACPI');
    await Directory(acpiDirectory).create(recursive: true);

    await AssetUtils.copyMultipleAssetsToDirectory(
      assetPlan.acpiAssets,
      acpiDirectory,
    );
    await _copyCachedFiles(acpiFileBytes, acpiDirectory);

    await FileUtils.copyAssetsAndUnzip(
      assetPlan.kextZipAssets,
      join(draft.ocPath, 'Kexts'),
    );

    if (assetPlan.copyUtbMapKext && assetPlan.utbMapPath != null) {
      await FileUtils.copyKext(
        assetPlan.utbMapPath!,
        join(draft.ocPath, 'Kexts'),
      );
    }

    if (assetPlan.copyResourcesTheme) {
      await FileUtils.copyAssetsAndUnzip(
        ['assets/theme/Resources.zip'],
        draft.ocPath,
      );
    } else {
      draft.patchModel.uefi.uefiDriversItems
          .removeWhere((e) => e.path == 'OpenCanopy.efi');
      draft.persistedModel.uefi.uefiDriversItems
          .removeWhere((e) => e.path == 'OpenCanopy.efi');
      await FileUtils.deleteFilesAndDirectories(
          join(draft.ocPath, 'Resources'));
    }

    await AssetUtils.copyMultipleAssetsToDirectory(
      assetPlan.driverAssets,
      join(draft.ocPath, 'Drivers'),
    );

    await AssetUtils.copyMultipleAssetsToDirectory(
      assetPlan.toolAssets,
      join(draft.ocPath, 'Tools'),
    );

    await AssetUtils.copyAssetsToDirectory(
      'assets/OpenCore/X64/EFI/BOOT/BOOTx64.efi',
      join(draft.efiRootPath, 'EFI', 'BOOT'),
    );
    await AssetUtils.copyAssetsToDirectory(
      'assets/OpenCore/X64/EFI/BOOT/.contentVisibility',
      join(draft.efiRootPath, 'EFI', 'BOOT'),
    );
    await AssetUtils.copyAssetsToDirectory(
      'assets/OpenCore/X64/EFI/BOOT/.contentFlavour',
      join(draft.efiRootPath, 'EFI', 'BOOT'),
    );
    await AssetUtils.copyAssetsToDirectory(
      'assets/OpenCore/X64/EFI/OC/OpenCore.efi',
      draft.ocPath,
    );
    await AssetUtils.copyAssetsToDirectory(
      'assets/OpenCore/Docs/Sample.plist',
      draft.ocPath,
      rename: 'config.plist',
      replaceExisting: true,
    );

    if (assetPlan.copyLegacyBoot) {
      await AssetUtils.copyAssetsToDirectory(
        'assets/LegacyBoot/boot',
        draft.efiRootPath,
      );
    }

    final success = await configService.executePostConfig(
      draft.configPlistPath,
      patchModel: draft.patchModel,
    );

    var hookSuccess = true;
    final hook = draft.afterConfigWritten;
    if (success && hook != null) {
      hookSuccess = await hook(draft);
    }

    await _saveConfigModelAndHistory(draft);

    final zipEfi = draft.zipEfi ?? SpUtil.getBool(Constant.zipEFI).nullSafe;
    if (zipEfi) {
      await FileUtils.compressFileOrFolder(draft.efiRootPath);
    }
    return success && hookSuccess;
  }

  Future<Map<String, List<int>>> _cacheFiles(List<String> filePaths) async {
    final result = <String, List<int>>{};
    for (final filePath in filePaths) {
      final file = File(filePath);
      if (await file.exists()) {
        result[basename(filePath)] = await file.readAsBytes();
      }
    }
    return result;
  }

  Future<void> _copyCachedFiles(
    Map<String, List<int>> files,
    String destinationDirectory,
  ) async {
    if (files.isEmpty) return;
    await Directory(destinationDirectory).create(recursive: true);
    for (final entry in files.entries) {
      await File(
        join(destinationDirectory, entry.key),
      ).writeAsBytes(entry.value, flush: true);
    }
  }

  Future<void> _saveConfigModelAndHistory(ConfigDraft draft) async {
    final jsonString = const JsonEncoder.withIndent('  ')
        .convert(draft.persistedModel.toJson());

    if (draft.saveHistory) {
      configService.historyModels = SpUtil.getObjList(
        Constant.historyConfigModel,
        (v) => HistoryModel.fromJson(v as Map<String, dynamic>),
        defValue: [],
      );

      final historyDirectory = await FileUtils.getHistoryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await FileUtils.saveToFile(
        content: jsonString,
        directoryPath: historyDirectory,
        fileName: '${draft.efiName}-${timestamp.yyyy_MM_dd_HH_mm_ss()}',
      );

      final historyModel = HistoryModel(
        path: join(historyDirectory, draft.efiName),
        name: draft.efiName,
        fileName: draft.efiName,
        timestamp: timestamp,
      );
      configService.historyModels?.add(historyModel);
      SpUtil.putObjectList(
        Constant.historyConfigModel,
        configService.historyModels!.map((e) => e.toJson()).toList(),
      );
      HistoryEventNotifier.instance.notifyHistoryChanged();
    }

    final saveConfigModel = draft.saveConfigModel ??
        SpUtil.getBool(Constant.outConfigModel, defValue: true).nullSafe;
    if (saveConfigModel) {
      await FileUtils.saveToFile(
        content: jsonString,
        directoryPath: draft.efiRootPath,
        fileName: 'configModel',
      );
    }
  }
}
