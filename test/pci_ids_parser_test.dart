import 'package:flutter_test/flutter_test.dart';
import 'package:rapidefi/utils/hardware/data/gpu_codename_data.dart';
import 'package:rapidefi/utils/hardware/pci_ids_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IdsParser', () {
    late IdsParser pciParser;
    late IdsParser usbParser;

    setUpAll(() async {
      pciParser = await IdsParser.load('assets/data/pci.ids');
      usbParser = await IdsParser.load('assets/data/usb.ids');
    });

    test('pci.ids 解析后不为空', () {
      expect(pciParser.vendors, isNotEmpty);
    });

    test('usb.ids 解析后不为空', () {
      expect(usbParser.vendors, isNotEmpty);
    });

    group('vendor 查找', () {
      test('Intel 厂商名称', () {
        expect(pciParser.vendorName('8086'), 'Intel Corporation');
      });

      test('AMD 厂商名称', () {
        expect(pciParser.vendorName('1002'), contains('AMD'));
      });

      test('NVIDIA 厂商名称', () {
        expect(pciParser.vendorName('10de'), 'NVIDIA Corporation');
      });

      test('大小写 ID 都可查找', () {
        expect(pciParser.vendorName('10DE'), 'NVIDIA Corporation');
        expect(pciParser.deviceName('1002', '67DF'), contains('Ellesmere'));
        expect(pciParser.deviceName('1002', '67df'), contains('Ellesmere'));
      });

      test('不存在的厂商返回 null', () {
        expect(pciParser.vendorName('0000'), isNull);
      });

      test('USB Intel 厂商名称', () {
        expect(usbParser.vendorName('8086'), 'Intel Corp.');
      });
    });

    group('device 查找', () {
      test('Intel 设备名称', () {
        expect(pciParser.deviceName('8086', '0007'), '82379AB');
      });

      test('AMD 设备名称', () {
        expect(pciParser.deviceName('1002', '1304'), 'Kaveri');
      });

      test('不存在的设备返回 null', () {
        expect(pciParser.deviceName('8086', '0000'), isNull);
      });

      test('完整设备 ID 查找设备名称', () {
        expect(
          pciParser.deviceNameByFullId('PCI\\VEN_10DE&DEV_1B80'),
          contains('GP104'),
        );
      });
    });

    group('GPU Codename 提取', () {
      test('从 AMD pci.ids 设备名提取 codename', () {
        final name = pciParser.deviceNameByFullId('1002-67DF');
        expect(name, isNotNull);
        expect(IdsParser.extractCodenameFromDeviceName(name!), 'Ellesmere');
      });

      test('从纯 codename 设备名提取 codename', () {
        final name = pciParser.deviceNameByFullId('1002-1304');
        expect(name, 'Kaveri');
        expect(IdsParser.extractCodenameFromDeviceName(name!), 'Kaveri');
      });

      test('从 NVIDIA pci.ids 设备名提取 codename', () {
        final name = pciParser.deviceNameByFullId('10DE-1B80');
        expect(name, isNotNull);
        expect(IdsParser.extractCodenameFromDeviceName(name!), 'GP104');
      });

      test('从显式 codename 字段提取 codename', () {
        expect(
          IdsParser.extractCodenameFromDeviceName(
            'Volari 8300 (chip: XP10, codename: XG47)',
          ),
          'XG47',
        );
      });

      test('GpuCodenameData 使用 pci.ids, Intel 核显不直接返回', () async {
        await GpuCodenameData.ensureLoaded();

        expect(GpuCodenameData.lookupCodename('1002-67DF'), 'Ellesmere');
        expect(GpuCodenameData.lookupCodename('1002-1304'), 'Kaveri');
        expect(GpuCodenameData.lookupCodename('10DE-1B80'), 'GP104');
        expect(GpuCodenameData.lookupCodename('8086-9BC5'), isNull);
      });
    });

    group('USB 设备查找', () {
      test('Intel USB 设备', () {
        final dev = usbParser.device('8086', '0044');
        expect(dev, isNotNull);
        expect(dev!.name, contains('DRAM'));
      });
    });

    group('数据完整性', () {
      test('pci.ids 至少包含常见厂商', () {
        final ids = ['8086', '1002', '10de', '14e4', '1022'];
        for (final id in ids) {
          expect(pciParser.vendorName(id), isNotNull, reason: 'vendor $id');
        }
      });

      test('Intel 有多条设备记录', () {
        final intel = pciParser.vendors['8086'];
        expect(intel, isNotNull);
        expect(intel!.devices.length, greaterThan(100));
      });
    });
  });
}
