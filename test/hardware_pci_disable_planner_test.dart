import 'package:flutter_test/flutter_test.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/hardware/analysis/gpu_compatibility_data.dart';
import 'package:rapidefi/utils/hardware/ssdt/hardware_pci_disable_planner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GpuCompatibilityData.ensureLoaded();
  });

  group('AcpiDeviceBlockPlanner', () {
    test('classifies unsupported discrete GPU and NVMe targets', () {
      final targets = const AcpiDeviceBlockPlanner().targets({
        'CPU': [
          {'SIMD Features': 'SSE4 AVX2'},
        ],
        'GPU': {
          'Intel UHD Graphics': {
            'Device Type': 'Integrated',
            'Device ID': '8086-9BC5',
            'PCI Path': 'PciRoot(0x0)/Pci(0x2,0x0)',
          },
          'Unsupported Radeon': {
            'Device Type': 'Discrete',
            'Device ID': '1002-0000',
            'ACPI Path': '_SB.PCI0.PEG0.PEGP',
            'PCI Path': 'PciRoot(0x0)/Pci(0x1,0x0)',
          },
        },
        'Storage Controllers': {
          'Samsung PM981': {
            'Bus Type': 'PCI',
            'Device ID': '144D-A808',
            'DeviceDesc': 'Samsung PM981 NVMe',
            'ACPI Path': '_SB.PCI0.RP05.PXSX',
            'PCI Path': 'PciRoot(0x0)/Pci(0x1D,0x0)',
          },
        },
      });

      expect(targets.map((target) => target.type), containsAll(['GPU', 'NVME']));
      expect(
        targets.any((target) => target.deviceId == '8086-9BC5'),
        isFalse,
      );
      expect(
        targets.map((target) => target.acpiPath),
        containsAll(['_SB.PCI0.PEG0.PEGP', '_SB.PCI0.RP05.PXSX']),
      );
    });

    test('skips targets that only provide PCI Path', () {
      final targets = const AcpiDeviceBlockPlanner().targets({
        'CPU': [
          {'SIMD Features': 'SSE4 AVX2'},
        ],
        'GPU': {
          'Unsupported NVIDIA': {
            'Device Type': 'Discrete',
            'Device ID': '10DE-DFFF',
            'PCI Path': 'PciRoot(0x0)/Pci(0x1,0x0)',
          },
        },
        'Storage Controllers': {
          'Samsung PM981': {
            'Bus Type': 'PCI',
            'Device ID': '144D-A808',
            'DeviceDesc': 'Samsung PM981 NVMe',
            'PCI Path': 'PciRoot(0x0)/Pci(0x1D,0x0)',
          },
        },
      });

      expect(targets, isEmpty);
    });

    test('skips targets with invalid ACPI Path', () {
      final targets = const AcpiDeviceBlockPlanner().targets({
        'CPU': [
          {'SIMD Features': 'SSE4 AVX2'},
        ],
        'GPU': {
          'Unsupported NVIDIA': {
            'Device Type': 'Discrete',
            'Device ID': '10DE-DFFF',
            'ACPI Path': 'PciRoot(0x0)/Pci(0x1,0x0)',
          },
        },
      });

      expect(targets, isEmpty);
    });

    test('uses laptop fallback methods and desktop IOName only', () {
      final planner = const AcpiDeviceBlockPlanner();

      expect(
        planner.disableMethods(PlatformType.laptop),
        ['OFF', 'PS3', 'IOName'],
      );
      expect(planner.disableMethods(PlatformType.desktop), ['IOName']);
      expect(planner.disableMethods(PlatformType.nuc), ['IOName']);
      expect(planner.disableMethods(PlatformType.hedt), ['IOName']);
    });

    test('disables dGPU for Intel laptop with Intel iGPU display output', () {
      final targets = const AcpiDeviceBlockPlanner().targets(
        _intelLaptopIgpuDisplayRawInfo(),
        cpuType: CpuType.intel,
        platformType: PlatformType.laptop,
      );

      expect(targets, hasLength(1));
      expect(targets.single.type, 'GPU');
      expect(targets.single.deviceId, '1002-67DF');
      expect(targets.single.acpiPath, '_SB.PCI0.PEG0.PEGP');
    });

    test('does not actively disable dGPU when display is connected to dGPU', () {
      final targets = const AcpiDeviceBlockPlanner().targets(
        _intelLaptopIgpuDisplayRawInfo(
          connectedGpu: 'Radeon RX 580',
        ),
        cpuType: CpuType.intel,
        platformType: PlatformType.laptop,
      );

      expect(targets, isEmpty);
    });

    test('does not actively disable dGPU outside Intel laptop context', () {
      final planner = const AcpiDeviceBlockPlanner();

      expect(
        planner.targets(
          _intelLaptopIgpuDisplayRawInfo(),
          cpuType: CpuType.intel,
          platformType: PlatformType.desktop,
        ),
        isEmpty,
      );
      expect(
        planner.targets(
          _intelLaptopIgpuDisplayRawInfo(),
          cpuType: CpuType.amd,
          platformType: PlatformType.laptop,
        ),
        isEmpty,
      );
    });

    test('dedupes actively disabled dGPU already selected as unsupported', () {
      final data = _intelLaptopIgpuDisplayRawInfo(
        dgpuDeviceId: '10DE-DFFF',
        dgpuName: 'Unsupported NVIDIA',
      );
      final targets = const AcpiDeviceBlockPlanner().targets(
        data,
        cpuType: CpuType.intel,
        platformType: PlatformType.laptop,
      );

      expect(
        targets
            .where((target) => target.acpiPath == '_SB.PCI0.PEG0.PEGP')
            .length,
        1,
      );
    });

    test('skips active laptop dGPU disable without ACPI Path', () {
      final data = _intelLaptopIgpuDisplayRawInfo();
      final gpus = data['GPU'] as Map<String, dynamic>;
      final dgpu = gpus['Radeon RX 580'] as Map<String, dynamic>;
      dgpu.remove('ACPI Path');

      final targets = const AcpiDeviceBlockPlanner().targets(
        data,
        cpuType: CpuType.intel,
        platformType: PlatformType.laptop,
      );

      expect(targets, isEmpty);
    });
  });
}

Map<String, dynamic> _intelLaptopIgpuDisplayRawInfo({
  String connectedGpu = 'Intel UHD Graphics 630',
  String dgpuDeviceId = '1002-67DF',
  String dgpuName = 'Radeon RX 580',
}) {
  return {
    'CPU': [
      {'SIMD Features': 'SSE4 AVX2'},
    ],
    'GPU': {
      'Intel UHD Graphics 630': {
        'Device Type': 'Integrated',
        'Manufacturer': 'Intel',
        'Device ID': '8086-9BC5',
        'ACPI Path': '_SB.PCI0.GFX0',
        'PCI Path': 'PciRoot(0x0)/Pci(0x2,0x0)',
      },
      dgpuName: {
        'Device Type': 'Discrete',
        'Manufacturer': dgpuDeviceId.startsWith('10DE') ? 'NVIDIA' : 'AMD',
        'Device ID': dgpuDeviceId,
        'ACPI Path': '_SB.PCI0.PEG0.PEGP',
        'PCI Path': 'PciRoot(0x0)/Pci(0x1,0x0)',
      },
    },
    'Monitor': {
      'Internal Display': {
        'Connected GPU': connectedGpu,
      },
    },
  };
}
