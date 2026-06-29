import 'package:flutter_test/flutter_test.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis_models.dart';
import 'package:rapidefi/utils/hardware/analysis/gpu_compatibility_data.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_compatibility.dart';
import 'package:rapidefi/utils/hardware/data/hardware_device_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GpuCompatibilityData.ensureLoaded();
  });

  group('GpuCompatibilityData identity override records', () {
    test('finds migrated identity override records with compatibility details', () {
      final polaris = GpuCompatibilityData.findSync('1002-6981');
      expect(polaris, isNotNull);
      expect(polaris!.spoofId, '1002-67FF');
      expect(polaris.spoofDeviceIdPart, '67FF');
      expect(polaris.codename, 'Lexa');
      expect(polaris.minDarwin, '17.0.0');
      expect(polaris.maxDarwin, '25.99.99');

      final terascale = GpuCompatibilityData.findSync('1002-950F');
      expect(terascale, isNotNull);
      expect(terascale!.groupName, 'terascale_1_identity_override');
      expect(terascale.spoofId, '1002-9505');
      expect(terascale.spoofDeviceIdPart, '9505');
      expect(terascale.minOclp, '18.0.0');
      expect(terascale.maxOclp, '24.99.99');

      final navi = GpuCompatibilityData.findSync('1002-73EF');
      expect(navi, isNotNull);
      expect(navi!.groupName, 'navi_identity_override');
      expect(navi.spoofId, '1002-73FF');
      expect(navi.avx2Limited, isTrue);
      expect(navi.maxDarwin, '25.99.99');
    });

    test('includes the missing Cayman target and its identity override target', () {
      final target = GpuCompatibilityData.findSync('1002-6704');
      expect(target, isNotNull);
      expect(target!.groupName, 'terascale_2');
      expect(target.codename, 'Cayman PRO GL');

      final source = GpuCompatibilityData.findSync('1002-6707');
      expect(source, isNotNull);
      expect(source!.groupName, 'terascale_2_identity_override');
      expect(source.spoofId, '1002-6704');
      expect(source.spoofDeviceIdPart, '6704');
    });

    test('identityOverrideRecordsSync contains all migrated legacy entries', () {
      final ids = GpuCompatibilityData.identityOverrideRecordsSync()
          .map((record) => record.id)
          .toSet();

      expect(
        ids,
        containsAll({
          '1002-950F',
          '1002-944C',
          '1002-9498',
          '1002-675B',
          '1002-68BE',
          '1002-68BF',
          '1002-68F9',
          '1002-68FA',
          '1002-6778',
          '1002-6611',
          '1002-6707',
          '1002-6613',
          '1002-6617',
          '1002-682C',
          '1002-6809',
          '1002-6649',
          '1002-67A1',
          '1002-6658',
          '1002-679A',
          '1002-67B1',
          '1002-6811',
          '1002-6819',
          '1002-682B',
          '1002-6837',
          '1002-665F',
          '1002-6930',
          '1002-6939',
          '1002-6987',
          '1002-699F',
          '1002-6995',
          '1002-6985',
          '1002-6981',
          '1002-73EF',
          '1002-73E1',
          '1002-73AF',
          '1002-73A5',
        }),
      );
    });

    test('amdIdentityOverrideRecordsSync only exposes AMD 1002 records', () {
      final records = GpuCompatibilityData.amdIdentityOverrideRecordsSync();

      expect(records, isNotEmpty);
      expect(
        records.every((record) => record.vendorId.toUpperCase() == '1002'),
        isTrue,
      );
    });

    test('amdIdentityOverrideRecordsSync orders AMD identity override records by codename generation',
        () {
      final records = GpuCompatibilityData.amdIdentityOverrideRecordsSync();
      final ids = records.map((e) => e.id).toList();

      int indexOf(String id) => ids.indexOf(id);
      int firstIndexWhere(bool Function(GpuCompatibilityRecord) test) =>
          records.indexWhere(test);

      expect(indexOf('1002-73A5'), greaterThanOrEqualTo(0));
      expect(indexOf('1002-73AF'), greaterThanOrEqualTo(0));
      expect(indexOf('1002-73EF'), greaterThanOrEqualTo(0));
      expect(indexOf('1002-6981'), greaterThanOrEqualTo(0));
      expect(indexOf('1002-950F'), greaterThanOrEqualTo(0));

      expect(indexOf('1002-73A5'), lessThan(indexOf('1002-73AF')));
      expect(indexOf('1002-73AF'), lessThan(indexOf('1002-73E1')));
      expect(indexOf('1002-73E1'), lessThan(indexOf('1002-73EF')));

      final naviIndex = firstIndexWhere((record) =>
          record.groupName.contains('navi') ||
          record.codename.contains('Navi'));
      final polarisIndex = firstIndexWhere((record) =>
          record.groupName.contains('polaris') ||
          record.codename.contains('Polaris'));
      final gcnIndex =
          firstIndexWhere((record) => record.codename.contains('GCN'));
      final terascale2Index =
          firstIndexWhere((record) => record.codename.contains('TeraScale 2'));
      final terascale1Index =
          firstIndexWhere((record) => record.codename.contains('TeraScale 1'));

      expect(naviIndex, lessThan(polarisIndex));
      expect(polarisIndex, lessThan(gcnIndex));
      expect(gcnIndex, lessThan(terascale2Index));
      expect(terascale2Index, lessThan(terascale1Index));
      expect(indexOf('1002-665F'), lessThan(indexOf('1002-950F')));
      expect(indexOf('1002-6837'), lessThan(indexOf('1002-950F')));
      expect(indexOf('1002-6811'), lessThan(indexOf('1002-950F')));
    });
  });

  group('GPU compatibility display details', () {
    test('recognizes NootedRed supported AMD iGPU whitelist', () {
      expect(
        HardwareDeviceData.isNootedRedSupportedDeviceId('1002-15DD'),
        isTrue,
      );
      expect(
        HardwareDeviceData.isNootedRedSupportedDeviceId('1002:1638'),
        isTrue,
      );
      expect(
        HardwareDeviceData.isNootedRedSupportedDeviceId('8086-1638'),
        isFalse,
      );
      expect(
        HardwareDeviceData.isNootedRedSupportedDeviceId('10DE-DFFF'),
        isFalse,
      );
      expect(
        HardwareDeviceData.isNootedRedSupportedDeviceId(''),
        isFalse,
      );
    });

    test('marks NootedRed supported AMD iGPU as compatible', () {
      final note = gpuEntryCompatibility(
        {
          'CPU': [
            {'SIMD Features': 'SSE4 AVX AVX2'},
          ],
          'GPU': {},
        },
        'AMD Radeon Graphics',
        {
          'Device ID': '1002-1638',
          'Device Type': 'Integrated',
          'Manufacturer': 'AMD',
        },
      );

      expect(note.level, CompatibilityLevel.supported);
      expect(note.text, contains('NootedRed'));

      final missingTypeNote = gpuEntryCompatibility(
        {
          'CPU': [
            {'SIMD Features': 'SSE4 AVX AVX2'},
          ],
          'GPU': {},
        },
        'AMD Radeon Graphics',
        {
          'Device ID': '1002:1638',
        },
      );

      expect(missingTypeNote.level, CompatibilityLevel.supported);
      expect(missingTypeNote.text, contains('NootedRed'));
    });

    test('does not mark AMD dGPU as NootedRed iGPU compatible', () {
      final note = gpuEntryCompatibility(
        {
          'CPU': [
            {'SIMD Features': 'SSE4 AVX AVX2'},
          ],
          'GPU': {},
        },
        'AMD Radeon RX 580',
        {
          'Device ID': '1002-1638',
          'Device Type': 'Discrete',
          'Manufacturer': 'AMD',
        },
      );

      expect(note.text, isNot(contains('NootedRed')));
    });

    test('formats Darwin ranges as macOS labels', () {
      expect(macOSLabelFromDarwinVersion('21.0.0'), 'macOS Monterey 12');
      expect(macOSLabelFromDarwinVersion('22.99.99'), 'macOS Ventura 13');
      expect(macOSLabelFromDarwinVersion('23.0.0'), 'macOS Sonoma 14');
      expect(macOSLabelFromDarwinVersion('24.0.0'), 'macOS Sequoia 15');
      expect(macOSLabelFromDarwinVersion('25.99.99'), 'macOS Tahoe 26');
    });

    test('limited GPU details do not include identity override text', () {
      final note = gpuEntryCompatibility(
          {
            'CPU': [
              {'SIMD Features': 'SSE4 AVX AVX2'},
            ],
            'GPU': {},
          },
          'Radeon PRO WX 3200',
          {
            'Device ID': '1002-6981',
            'Device Type': '独立显卡',
          });

      expect(note.level, CompatibilityLevel.limited);
      expect(note.text, contains('原生支持 macOS HighSierra 10.13 ~ macOS Tahoe 26'));
      expect(note.text, isNot(contains('需要仿冒')));
      expect(note.text, isNot(contains('device-id')));
    });
  });
}
