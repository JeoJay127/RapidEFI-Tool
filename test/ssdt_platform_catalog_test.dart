import 'package:flutter_test/flutter_test.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/hardware/ssdt/ssdt_platform_catalog.dart';
import 'package:rapidefi/utils/ssdttool/table.dart';

void main() {
  group('SsdtPlatformCatalog', () {
    test('resolves items for Intel and AMD platform families', () {
      for (final cpuType in [CpuType.intel, CpuType.amd]) {
        for (final platformType in PlatformType.values) {
          final codes = SsdtPlatformCatalog.platformCodes(
            cpuType,
            platformType,
          );
          expect(codes, isNotEmpty);
          expect(
            SsdtPlatformCatalog.items(cpuType, platformType, codes.first),
            isNotEmpty,
          );
        }
      }
    });

    test('desktop defaults select only basic items', () {
      final keys = SsdtPlatformCatalog.defaultSelectedKeys(
        CpuType.intel,
        PlatformType.desktop,
        'haswell',
      );
      final selectedItems = SsdtPlatformCatalog.items(
        CpuType.intel,
        PlatformType.desktop,
        'haswell',
      ).where((item) => keys.contains(item.key));

      expect(selectedItems, isNotEmpty);
      expect(selectedItems.every((item) => item.isBasic), isTrue);
    });

    test('laptop, nuc, and hedt defaults include recommended items', () {
      for (final platformType in [
        PlatformType.laptop,
        PlatformType.nuc,
        PlatformType.hedt,
      ]) {
        final code = SsdtPlatformCatalog.platformCodes(
          CpuType.intel,
          platformType,
        ).first;
        final keys = SsdtPlatformCatalog.defaultSelectedKeys(
          CpuType.intel,
          platformType,
          code,
        );
        final selectedItems = SsdtPlatformCatalog.items(
          CpuType.intel,
          platformType,
          code,
        ).where((item) => keys.contains(item.key));

        expect(selectedItems.any((item) => item.isBasic), isTrue);
        expect(selectedItems.any((item) => item.isRecommend), isTrue);
      }
    });

    test('laptop defaults include lid, wake screen, and led SSDTs', () {
      final keys = SsdtPlatformCatalog.defaultSelectedKeys(
        CpuType.intel,
        PlatformType.laptop,
        'haswell',
      );
      final selectedNames = SsdtPlatformCatalog.items(
        CpuType.intel,
        PlatformType.laptop,
        'haswell',
      ).where((item) => keys.contains(item.key)).map((item) => item.name);

      expect(selectedNames, contains(ACPITable.ssdtLID.name));
      expect(selectedNames, contains(ACPITable.ssdtWakeScreen.name));
      expect(selectedNames, contains(ACPITable.ssdtLED.name));
    });

    test('desktop defaults do not include laptop lid SSDTs', () {
      final keys = SsdtPlatformCatalog.defaultSelectedKeys(
        CpuType.intel,
        PlatformType.desktop,
        'haswell',
      );
      final selectedNames = SsdtPlatformCatalog.items(
        CpuType.intel,
        PlatformType.desktop,
        'haswell',
      ).where((item) => keys.contains(item.key)).map((item) => item.name);

      expect(selectedNames, isNot(contains(ACPITable.ssdtLID.name)));
      expect(selectedNames, isNot(contains(ACPITable.ssdtWakeScreen.name)));
      expect(selectedNames, isNot(contains(ACPITable.ssdtLED.name)));
    });
  });
}
