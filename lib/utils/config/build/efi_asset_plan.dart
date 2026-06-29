class EfiAssetPlan {
  const EfiAssetPlan({
    required this.cleanupPaths,
    required this.acpiAssets,
    required this.acpiFiles,
    required this.kextZipAssets,
    required this.driverAssets,
    required this.toolAssets,
    required this.copyResourcesTheme,
    required this.copyLegacyBoot,
    required this.copyUtbMapKext,
    this.utbMapPath,
  });

  final List<String> cleanupPaths;
  final List<String> acpiAssets;
  final List<String> acpiFiles;
  final List<String> kextZipAssets;
  final List<String> driverAssets;
  final List<String> toolAssets;
  final bool copyResourcesTheme;
  final bool copyLegacyBoot;
  final bool copyUtbMapKext;
  final String? utbMapPath;
}
