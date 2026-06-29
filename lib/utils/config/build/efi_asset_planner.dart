import 'dart:io';

import 'package:path/path.dart';
import 'package:rapidefi/extension/bool_extension.dart';
import 'package:rapidefi/utils/config/build/config_draft.dart';
import 'package:rapidefi/utils/config/build/efi_asset_plan.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/services/config_service.dart';
import 'package:rapidefi/utils/constant.dart';
import 'package:sp_util/sp_util.dart';

class EfiAssetPlanner {
  const EfiAssetPlanner(this.configService);

  final ConfigService configService;

  EfiAssetPlan plan(ConfigDraft draft) {
    final model = draft.patchModel;
    final ocPath = draft.ocPath;
    final acpiSourceDirectory = draft.acpiSourceDirectory?.trim() ?? '';
    final acpiAssets = <String>[];
    final acpiFiles = <String>[];
    for (final item in draft.acpiItems) {
      final sourceFile = acpiSourceDirectory.isEmpty
          ? null
          : File(join(acpiSourceDirectory, item.path));
      if (sourceFile != null && sourceFile.existsSync()) {
        acpiFiles.add(sourceFile.path);
      } else {
        acpiAssets.add('assets/acpi/${item.path}');
      }
    }
    final copyResourcesTheme =
        SpUtil.getBool(Constant.configOpenCoreTheme, defValue: true).nullSafe;
    final kextZipAssets =
        draft.kexts.where((e) => !e.bundlePath.contains('/')).map((e) {
      return 'assets/kexts/${e.bundlePath}.zip';
    }).toList();

    return EfiAssetPlan(
      cleanupPaths: [
        join(draft.efiRootPath, 'configModel'),
        join(ocPath, 'ACPI'),
        join(ocPath, 'Kexts'),
        join(ocPath, 'Drivers'),
        join(draft.efiRootPath, 'boot'),
        join(ocPath, ConfigService.copyConfigName),
      ],
      acpiAssets: acpiAssets,
      acpiFiles: acpiFiles,
      kextZipAssets: kextZipAssets,
      driverAssets: model.uefi.uefiDriversItems
          .where((e) => copyResourcesTheme || e.path != 'OpenCanopy.efi')
          .map((e) => 'assets/OpenCore/X64/EFI/OC/Drivers/${e.path}')
          .toList(),
      toolAssets: model.misc.miscToolsItems
          .map((e) => 'assets/OpenCore/X64/EFI/OC/Tools/${e.path}')
          .toList(),
      copyResourcesTheme: copyResourcesTheme,
      copyLegacyBoot: model.legacy,
      copyUtbMapKext: configService.hasKext(ConfigKernel.USBToolBox) &&
          configService.utbMapPath != null &&
          configService.utbMapPath!.isNotEmpty,
      utbMapPath: configService.utbMapPath,
    );
  }
}
