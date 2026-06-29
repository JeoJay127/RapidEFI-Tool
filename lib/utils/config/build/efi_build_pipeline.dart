import 'package:rapidefi/utils/config/build/config_rule_engine.dart';
import 'package:rapidefi/utils/config/build/efi_asset_planner.dart';
import 'package:rapidefi/utils/config/build/efi_build_options.dart';
import 'package:rapidefi/utils/config/build/efi_exporter.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/services/config_service.dart';
import 'package:rapidefi/utils/config/services/config_session.dart';

class EfiBuildPipeline {
  const EfiBuildPipeline(this.configService);

  final ConfigService configService;

  Future<bool> build({
    required ConfigModel configModel,
    EfiBuildOptions options = const EfiBuildOptions(),
    ConfigModelMode? mode,
  }) async {
    final result = await buildResult(
      configModel: configModel,
      options: options,
      mode: mode,
    );
    return result.success;
  }

  Future<EfiBuildResult> buildResult({
    required ConfigModel configModel,
    EfiBuildOptions options = const EfiBuildOptions(),
    ConfigModelMode? mode,
  }) async {
    final previousMode = configService.configModelMode;
    final targetMode = mode ?? previousMode;

    try {
      configService.setConfigModelMode(targetMode);
      configService.setConfigModel(configModel);

      final draft = await ConfigRuleEngine(configService).buildDraft(
        options: options,
      );
      final assetPlan = EfiAssetPlanner(configService).plan(draft);
      final success = await EfiExporter(configService).export(
        draft: draft,
        assetPlan: assetPlan,
      );
      return EfiBuildResult(
        success: success,
        efiRootPath: draft.efiRootPath,
        outputDirectory: draft.outputDirectory,
      );
    } finally {
      configService.setConfigModelMode(previousMode);
    }
  }
}

class EfiBuildResult {
  const EfiBuildResult({
    required this.success,
    required this.efiRootPath,
    required this.outputDirectory,
  });

  final bool success;
  final String efiRootPath;
  final String outputDirectory;
}
