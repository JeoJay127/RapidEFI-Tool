import 'package:rapidefi/utils/config/config_model.dart';

class MacOSVersionInfo {
  const MacOSVersionInfo({
    required this.name,
    required this.productVersion,
    required this.darwinMajor,
  });

  final String name;
  final String productVersion;
  final int darwinMajor;

  String get label => '$name $productVersion';

  int get productMajor => int.tryParse(productVersion.split('.').first) ?? 0;
}

class MacOSVersions {
  const MacOSVersions._();

  static const List<MacOSVersionInfo> all = [
    MacOSVersionInfo(
      name: 'Tahoe',
      productVersion: '26',
      darwinMajor: 25,
    ),
    MacOSVersionInfo(
      name: 'Sequoia',
      productVersion: '15',
      darwinMajor: 24,
    ),
    MacOSVersionInfo(
      name: 'Sonoma',
      productVersion: '14',
      darwinMajor: 23,
    ),
    MacOSVersionInfo(
      name: 'Ventura',
      productVersion: '13',
      darwinMajor: 22,
    ),
    MacOSVersionInfo(
      name: 'Monterey',
      productVersion: '12',
      darwinMajor: 21,
    ),
    MacOSVersionInfo(
      name: 'BigSur',
      productVersion: '11',
      darwinMajor: 20,
    ),
    MacOSVersionInfo(
      name: 'Catalina',
      productVersion: '10.15',
      darwinMajor: 19,
    ),
    MacOSVersionInfo(
      name: 'Mojave',
      productVersion: '10.14',
      darwinMajor: 18,
    ),
    MacOSVersionInfo(
      name: 'HighSierra',
      productVersion: '10.13',
      darwinMajor: 17,
    ),
  ];

  static const int defaultDarwinMajor = 24;

  static List<String> get labels =>
      all.map((version) => version.label).toList();

  static MacOSVersionInfo byDarwinMajor(int darwinMajor) {
    return all.firstWhere(
      (version) => version.darwinMajor == darwinMajor,
      orElse: () => all.firstWhere(
        (version) => version.darwinMajor == defaultDarwinMajor,
      ),
    );
  }

  static int darwinMajorFromLabel(String label) {
    final normalized = label.trim().toLowerCase();
    for (final version in all) {
      if (version.label.toLowerCase() == normalized ||
          version.name.toLowerCase() == normalized ||
          version.productVersion == normalized) {
        return version.darwinMajor;
      }
    }

    final versionMatch = RegExp(r'(\d+(?:\.\d+)?)$').firstMatch(label.trim());
    return darwinMajorFromProductVersion(versionMatch?.group(1) ?? '');
  }

  static int darwinMajorFromProductVersion(String productVersion) {
    final normalized = productVersion.trim();
    for (final version in all) {
      if (version.productVersion == normalized) {
        return version.darwinMajor;
      }
    }

    final numericVersion = double.tryParse(normalized);
    if (numericVersion == null) return defaultDarwinMajor;
    if (numericVersion >= 26) return 25;
    if (numericVersion >= 15) return 24;
    if (numericVersion >= 14) return 23;
    if (numericVersion >= 13) return 22;
    if (numericVersion >= 12) return 21;
    if (numericVersion >= 11) return 20;
    if (numericVersion >= 10.15) return 19;
    if (numericVersion >= 10.14) return 18;
    if (numericVersion >= 10.13) return 17;
    if (numericVersion >= 10.12) return 16;
    if (numericVersion >= 10.11) return 15;
    if (numericVersion >= 10.10) return 14;
    if (numericVersion >= 10.9) return 13;
    if (numericVersion >= 10.8) return 12;
    if (numericVersion >= 10.7) return 11;
    if (numericVersion >= 10.6) return 10;
    return defaultDarwinMajor;
  }

  static int productMajorFromDarwinMajor(int darwinMajor) {
    final known = all.where((version) => version.darwinMajor == darwinMajor);
    if (known.isNotEmpty) return known.first.productMajor;
    if (darwinMajor >= 25) return darwinMajor + 1;
    if (darwinMajor >= 20) return darwinMajor - 9;
    return 10;
  }

  static String productVersionFromDarwinMajor(int darwinMajor) {
    final known = all.where((version) => version.darwinMajor == darwinMajor);
    if (known.isNotEmpty) return known.first.productVersion;

    return switch (darwinMajor) {
      16 => '10.12',
      15 => '10.11',
      14 => '10.10',
      13 => '10.9',
      12 => '10.8',
      11 => '10.7',
      10 => '10.6',
      9 => '10.5',
      _ when darwinMajor >= 25 => '${darwinMajor + 1}',
      _ when darwinMajor >= 20 => '${darwinMajor - 9}',
      _ => 'Darwin $darwinMajor',
    };
  }

  static String labelFromDarwinMajor(int darwinMajor) {
    final known = all.where((version) => version.darwinMajor == darwinMajor);
    if (known.isNotEmpty) return known.first.label;

    return 'macOS ${productVersionFromDarwinMajor(darwinMajor)}';
  }
}

extension MacOSVersionConfigAccess on ConfigModel {
  String get macOSVersion =>
      MacOSVersions.byDarwinMajor(darwinMajorVersion).label;

  set macOSVersion(String value) {
    darwinMajorVersion = MacOSVersions.darwinMajorFromLabel(value);
  }
}
