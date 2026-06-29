import 'package:flutter_test/flutter_test.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis_models.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_compatibility.dart';
import 'package:rapidefi/utils/hardware/hardware_info.dart';
import 'package:rapidefi/utils/hardware/model/allinfo.dart';

void main() {
  test('hardware model parsing tolerates malformed sections', () {
    final info = HardwareAllInfo.fromJson({
      'CPU': [
        {
          'Name': 123,
          'NumberOfCores': '8',
          'VirtualizationFirmwareEnabled': 'true',
        },
        'not a cpu map',
      ],
      'GPU': {
        'Intel UHD': {
          'Device ID': 8086,
          'Codename': ' ',
        },
      },
      'Monitor': {
        'Built-in': {
          'Size': '13.3',
          'Connector Type': '',
        },
      },
      'Memory': 'not a memory list',
      'Disk': [
        {
          'Size': '512.0',
        }
      ],
      'Network': {
        'invalid': 'not a network map',
      },
      'BIOS': 'not a bios map',
    });

    expect(info.cpu?.cpuList, hasLength(2));
    expect(info.cpu?.cpuList.first.name, '123');
    expect(info.cpu?.cpuList.first.numberOfCores, 8);
    expect(info.cpu?.cpuList.first.virtualizationFirmwareEnabled, isTrue);
    expect(info.cpu?.cpuList.last.name, isNull);

    expect(
        info.graphicsInfoList?.graphicsCards?['Intel UHD']?.deviceID, '8086');
    expect(
        info.graphicsInfoList?.graphicsCards?['Intel UHD']?.codename, isNull);
    expect(info.monitorsInfo?.monitors['Built-in']?.size, 13.3);
    expect(info.monitorsInfo?.monitors['Built-in']?.connectorType, isNull);
    expect(info.memoryInfo?.memoryModules, isEmpty);
    expect(info.diskInfo?.disks?.first.size, 512);
    expect(info.networkInfoList?.networkAdapters?['invalid']?.deviceID, isNull);
    expect(info.biosInfo?.name, '');
  });

  test('hardware model keeps USB controllers under canonical key', () {
    final info = HardwareAllInfo.fromJson({
      'USB Controllers': {
        'Intel XHCI': {
          'Bus Type': 'PCI',
          'Device ID': '8086-A2AF',
        },
      },
    });

    expect(info.usbInfoList?.usbControllers?['Intel XHCI']?.deviceID,
        '8086-A2AF');
    expect(info.toJson(), contains('USB Controllers'));
    expect(info.toJson(), isNot(contains('USB')));
  });

  test('hardware info ignores old USB key', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HardwareInfo.clearInfo('test-usb');

    await HardwareInfo.importRawInfo('test-usb', {
      'USB': {
        'Intel XHCI': {
          'Bus Type': 'PCI',
          'Device ID': '8086-A2AF',
        },
      },
    });

    expect(HardwareInfo.rawInfo, isNot(contains('USB')));
    expect(HardwareInfo.rawInfo?['USB Controllers'], isEmpty);
    expect(
      HardwareInfo.getHardwareInfoForPage('test-usb')?.usbInfoList?.usbControllers,
      isEmpty,
    );
  });

  test('hardware info normalizes GPU codename when raw value is model name',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HardwareInfo.clearInfo('test');

    await HardwareInfo.importRawInfo('test', {
      'CPU': [
        {
          'Name': 'Intel Core i5-4590',
          'Codename': 'Haswell',
          'SIMD Features': 'SSE4 AVX2',
        }
      ],
      'GPU': {
        'Intel(R) HD Graphics P4600/P4700': {
          'Bus Type': 'PCI',
          'Device ID': '8086-041A',
          'PCI Path': 'PciRoot(0x0)/Pci(0x2,0x0)',
          'ACPI Path': '_SB.PCI0.GFX0',
          'Manufacturer': 'Intel',
          'Codename': 'Intel(R) HD Graphics P4600/P4700',
          'Device Type': '核心显卡',
        },
      },
    });

    final gpuMap = HardwareInfo.rawInfo?['GPU'] as Map?;
    final gpu = gpuMap?['Intel(R) HD Graphics P4600/P4700'] as Map?;

    expect(gpu?['Codename'], 'Haswell');
    expect(
      HardwareInfo.getHardwareInfoForPage('test')
          ?.graphicsInfoList
          ?.graphicsCards?['Intel(R) HD Graphics P4600/P4700']
          ?.codename,
      'Haswell',
    );
  });

  test('hardware info prefers AMD chipset rules for AMD motherboard', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HardwareInfo.clearInfo('test-amd-chipset');

    await HardwareInfo.importRawInfo('test-amd-chipset', {
      'Motherboard': {
        'Device ID': '1002-FFFF',
        'Product': 'ASUS ROG STRIX B550-F GAMING',
        'Chipset': 'AMD 500 Series',
      },
    });

    final board = HardwareInfo.rawInfo?['Motherboard'] as Map?;
    expect(board?['Chipset'], 'B550');
  });

  test('hardware info prefers AMD chipset rules for AMD 1022 motherboard',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HardwareInfo.clearInfo('test-amd-1022-chipset');

    await HardwareInfo.importRawInfo('test-amd-1022-chipset', {
      'Motherboard': {
        'Manufacturer': 'GIGABYTE Technology Co., Ltd.',
        'Model': 'F2A88XM-D3H',
        'Name': 'F2A88XM-D3H',
        'Product': 'F2A88XM-D3H',
        'Chipset': 'A88X',
        'Device ID': '1022-780E',
        'Platform': 'Desktop',
      },
    });

    final board = HardwareInfo.rawInfo?['Motherboard'] as Map?;
    expect(board?['Chipset'], 'A88X');
  });

  test('hardware info falls back to chipset controller table', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HardwareInfo.clearInfo('test-chipset-fallback');

    await HardwareInfo.importRawInfo('test-chipset-fallback', {
      'Motherboard': {
        'Device ID': '1002-434C',
        'Product': 'Legacy board',
      },
    });

    final board = HardwareInfo.rawInfo?['Motherboard'] as Map?;
    expect(board?['Chipset'], 'SB200 (AMD)');
  });

  test('hardware info keeps Intel chipset controller mapping', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HardwareInfo.clearInfo('test-intel-chipset');

    await HardwareInfo.importRawInfo('test-intel-chipset', {
      'Motherboard': {
        'Device ID': '8086-A305',
        'Product': 'Intel Z390 board',
        'Chipset': 'Intel board',
      },
    });

    final board = HardwareInfo.rawInfo?['Motherboard'] as Map?;
    expect(board?['Chipset'], 'Z390');
  });

  test('disk compatibility falls back to unsupported NVMe model', () {
    final data = {
      'Disk': [
        {
          'Model': 'SAMSUNG MZVLB512HAJQ-00000',
          'BusType': 'NVMe',
          'Controller Device ID': '1234-5678',
        },
      ],
    };

    expect(diskCompatibility(data)?.level, CompatibilityLevel.unsupported);
    expect(
      isUnsupportedDisk(
        (data['Disk'] as List).first as Map<String, dynamic>,
        unsupportedDiskControllerIds(data),
      ),
      isTrue,
    );
  });

  test('unsupported disk model fallback only applies to NVMe disks', () {
    final data = {
      'Disk': [
        {
          'Model': 'SAMSUNG MZVLB512HAJQ-00000',
          'BusType': 'SATA',
          'Controller Device ID': '1234-5678',
        },
      ],
    };

    expect(diskCompatibility(data)?.level, CompatibilityLevel.supported);
    expect(
      isUnsupportedDisk(
        (data['Disk'] as List).first as Map<String, dynamic>,
        unsupportedDiskControllerIds(data),
      ),
      isFalse,
    );
  });

  test('disk compatibility is limited when only part of disks are unsupported',
      () {
    final data = {
      'Disk': [
        {
          'Model': 'SAMSUNG MZVLB512HAJQ-00000',
          'BusType': 'NVMe',
          'Controller Device ID': '1234-5678',
        },
        {
          'Model': 'Known Good SATA',
          'BusType': 'SATA',
          'Controller Device ID': '1234-5678',
        },
      ],
    };

    expect(diskCompatibility(data)?.level, CompatibilityLevel.limited);
  });
}
