import 'package:flutter_test/flutter_test.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/enums/brand_enum.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/presets/sections/config_acpi.dart';
import 'package:rapidefi/utils/config/presets/sections/config_device_properties.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/services/apple_alc_resolver.dart';
import 'package:rapidefi/utils/hardware/config/hardware_config_model_builder.dart';
import 'package:rapidefi/utils/hardware/config/hardware_config_options.dart';
import 'package:rapidefi/utils/hardware/model/allinfo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppleALCResolver.initialize();
  });

  group('HardwareConfigModelBuilder', () {
    test('selects kexts from analyzed hardware data', () {
      final rawInfo = _rawInfo();
      final model = HardwareConfigModelBuilder(
        hardwareInfo: HardwareAllInfo.fromJson(rawInfo),
        rawInfo: rawInfo,
      ).build(
        options: const HardwareConfigOptions(
          macOSVersion: 'Sequoia 15',
          alcLayoutId: 7,
        ),
      );

      final bundlePaths =
          model.kernel.kernelKexts.map((kext) => kext.bundlePath).toSet();

      expect(bundlePaths, contains(ConfigKernel.AppleALC.bundlePath));
      expect(bundlePaths, contains(ConfigKernel.IntelMausi.bundlePath));
      expect(
        bundlePaths,
        contains(ConfigKernel.AirportItlwm_Sequoia.bundlePath),
      );
      expect(bundlePaths, contains(ConfigKernel.RtWlanU.bundlePath));
      expect(bundlePaths, contains(ConfigKernel.RtWlanU1827.bundlePath));
      expect(
        bundlePaths,
        contains(ConfigKernel.AirPortAtheros40_9485.bundlePath),
      );
      expect(bundlePaths, contains(ConfigKernel.IOSkywalkFamily.bundlePath));
      expect(
        bundlePaths,
        contains(ConfigKernel.IO80211FamilyLegacy.bundlePath),
      );
      expect(bundlePaths, contains(ConfigKernel.AMFIPass.bundlePath));
      expect(bundlePaths, contains(ConfigKernel.RealtekCardReader.bundlePath));
      expect(
        bundlePaths,
        contains(ConfigKernel.RealtekCardReaderFriend.bundlePath),
      );
      expect(BootArgsAccessor.getAlcid(model), 7);
      expect(model.csrsetting, CsrSetting.partialDisabled);
      expect(model.darwinMajorVersion, 24);
      expect(model.pentiumOrCeleron, isFalse);
      expect(model.brand, Brand.asus);
      expect(model.specialMotherboard, SpecialMotherboard.none);
      expect(model.kernel.kernelQuirks.forceAquantiaEthernet, isTrue);
    });

    test('adds Ventura AVX2 workaround for non-AVX2 CPU', () {
      final rawInfo = _rawInfo(
        cpuName: 'Intel Core i5-3570K',
        cpuCodename: 'Ivy Bridge',
        simdFeatures: 'SSE4',
      );

      final model = _buildModel(
        rawInfo,
        options: const HardwareConfigOptions(macOSVersion: 'Ventura 13'),
      );

      expect(
        _bundlePaths(model),
        contains(ConfigKernel.CryptexFixup.bundlePath),
      );
      expect(
        BootArgsAccessor.contains(model, ConfigNvram.amd_no_dgpu_accel.arg),
        isFalse,
      );
      expect(model.pentiumOrCeleron, isFalse);
    });

    test('adds AMD no dGPU accel for non-AVX2 Ventura Navi or Polaris dGPU',
        () {
      final rawInfo = _rawInfo(
        cpuName: 'Intel Core i5-3570K',
        cpuCodename: 'Ivy Bridge',
        simdFeatures: 'SSE4',
        gpu: {
          'Radeon RX 580': {
            'Device Type': 'Discrete',
            'Codename': 'Polaris',
            'Device ID': '1002-67DF',
          },
        },
      );

      final model = _buildModel(
        rawInfo,
        options: const HardwareConfigOptions(macOSVersion: 'Ventura 13'),
      );

      expect(
        _bundlePaths(model),
        contains(ConfigKernel.CryptexFixup.bundlePath),
      );
      expect(
        BootArgsAccessor.contains(model, ConfigNvram.amd_no_dgpu_accel.arg),
        isTrue,
      );
    });

    test('skips AVX2 workaround on Monterey or older', () {
      final rawInfo = _rawInfo(
        cpuName: 'Intel Core i5-3570K',
        cpuCodename: 'Ivy Bridge',
        simdFeatures: 'SSE4',
        gpu: {
          'Radeon RX 580': {
            'Device Type': 'Discrete',
            'Codename': 'Polaris',
            'Device ID': '1002-67DF',
          },
        },
      );

      final model = _buildModel(
        rawInfo,
        options: const HardwareConfigOptions(macOSVersion: 'Monterey 12'),
      );

      expect(
        _bundlePaths(model),
        isNot(contains(ConfigKernel.CryptexFixup.bundlePath)),
      );
      expect(
        BootArgsAccessor.contains(model, ConfigNvram.amd_no_dgpu_accel.arg),
        isFalse,
      );
    });

    test('marks Pentium and Celeron CPUs', () {
      final rawInfo = _rawInfo(
        cpuName: 'Intel Pentium G4560',
        cpuCodename: 'Kaby Lake',
        simdFeatures: 'SSE4 AVX2',
      );

      final model = _buildModel(
        rawInfo,
        options: const HardwareConfigOptions(macOSVersion: 'Monterey 12'),
      );

      expect(model.pentiumOrCeleron, isTrue);
    });

    test('maps motherboard brand and Intel special motherboard', () {
      final rawInfo = _rawInfo(
        motherboardManufacturer: 'Micro-Star International Co., Ltd.',
        motherboardProduct: 'MAG Z490 TOMAHAWK',
        motherboardChipset: 'Intel Z490',
      );

      final model = _buildModel(rawInfo);

      expect(model.brand, Brand.msi);
      expect(model.specialMotherboard, SpecialMotherboard.intelZ490);
    });

    test('maps AMD special motherboard from chipset', () {
      final rawInfo = _rawInfo(
        cpuManufacturer: 'AMD',
        cpuName: 'AMD Ryzen 7 5800X',
        cpuCodename: 'Vermeer',
        motherboardManufacturer: 'ASRock',
        motherboardProduct: 'B550 Steel Legend',
        motherboardChipset: 'AMD B550',
      );

      final model = _buildModel(rawInfo);

      expect(model.brand, Brand.asrock);
      expect(model.specialMotherboard, SpecialMotherboard.amdB550A520);
    });

    test('maps mixed Ivy Bridge CPU with 6-series motherboard', () {
      final rawInfo = _rawInfo(
        cpuName: 'Intel Core i5-3570K',
        cpuCodename: 'Ivy Bridge',
        motherboardManufacturer: 'Gigabyte',
        motherboardProduct: 'GA-H61M-DS2',
        motherboardChipset: 'Intel H61',
      );

      final model = _buildModel(rawInfo);

      expect(model.brand, Brand.gigabyte);
      expect(model.platformCode, 'ivy_bridge');
      expect(model.specialMotherboard, SpecialMotherboard.intelS6);
    });

    test('recognizes Intel 14th desktop CPU as Raptor Lake Refresh', () {
      final model = _buildModel(
        _rawInfo(
          cpuName: '14th Gen Intel Core i5-14600K',
          cpuCodename: '',
          motherboardProduct: '',
          motherboardChipset: '',
        ),
      );

      expect(model.platformType, PlatformType.desktop);
      expect(model.platformCode, 'raptor_lake_refresh');
    });

    test('recognizes X299 CPU as Intel HEDT', () {
      final model = _buildModel(
        _rawInfo(
          cpuName: 'Intel Core i9-10980XE',
          cpuCodename: '',
          motherboardProduct: '',
          motherboardChipset: '',
        ),
      );

      expect(model.platformType, PlatformType.hedt);
      expect(model.platformCode, 'skylake_x_w');
    });

    test('recognizes Broadwell-E Xeon as Intel HEDT', () {
      final model = _buildModel(
        _rawInfo(
          cpuName: 'Intel Xeon E5-2690 v4',
          cpuCodename: '',
          motherboardProduct: '',
          motherboardChipset: '',
        ),
      );

      expect(model.platformType, PlatformType.hedt);
      expect(model.platformCode, 'broadwell_e');
    });

    test('uses Intel iGPU fallback when CPU name is unknown', () {
      final model = _buildModel(
        _rawInfo(
          cpuName: 'Intel Genuine CPU 0000',
          cpuCodename: '',
          motherboardProduct: '',
          motherboardChipset: '',
          gpu: {
            'Intel UHD Graphics 630': {
              'Device Type': 'Integrated',
              'Manufacturer': 'Intel',
              'Device ID': '8086-3E9B',
            },
          },
        ),
      );

      expect(model.platformType, PlatformType.desktop);
      expect(model.platformCode, 'coffee_lake_8th');
    });

    test('uses motherboard chipset fallback when CPU and iGPU are unknown', () {
      final model = _buildModel(
        _rawInfo(
          cpuName: 'Intel Genuine CPU 0000',
          cpuCodename: '',
          motherboardProduct: 'MAG Z690 TOMAHAWK',
          motherboardChipset: 'Intel Z690',
        ),
      );

      expect(model.platformType, PlatformType.desktop);
      expect(model.platformCode, 'alder_lake');
    });

    test('uses X299 motherboard fallback to infer HEDT', () {
      final model = _buildModel(
        _rawInfo(
          cpuName: 'Intel Genuine CPU 0000',
          cpuCodename: '',
          motherboardProduct: 'X299 DESIGNARE EX',
          motherboardChipset: 'Intel X299',
        ),
      );

      expect(model.platformType, PlatformType.hedt);
      expect(model.platformCode, 'skylake_x_w');
    });

    test('configures Intel iGPU display output properties', () {
      final rawInfo = _rawInfo(
        gpu: {
          'Intel UHD Graphics 630': {
            'Device Type': 'Integrated',
            'Manufacturer': 'Intel',
            'PCI Path': ConfigDp.pciPath,
          },
        },
        monitor: {
          'Built-in Display': {
            'Connected GPU': 'Intel UHD Graphics 630',
          },
        },
      );

      final model = _buildModel(rawInfo);

      expect(
        _bundlePaths(model),
        contains(ConfigKernel.WhateverGreen.bundlePath),
      );
      expect(
        _devicePropertyValue(model, ConfigDp.pciPath, 'AAPL,ig-platform-id'),
        '07009B3E',
      );
      expect(
        _devicePropertyValue(model, ConfigDp.pciPath, 'device-id'),
        '9B3E0000',
      );
    });

    test('uses Intel iGPU compute properties when dGPU handles display', () {
      final rawInfo = _rawInfo(
        gpu: {
          'Intel UHD Graphics 630': {
            'Device Type': 'Integrated',
            'Manufacturer': 'Intel',
            'PCI Path': ConfigDp.pciPath,
          },
          'Radeon RX 580': {
            'Device Type': 'Discrete',
            'Manufacturer': 'AMD',
            'Codename': 'Polaris',
            'Device ID': '1002-67DF',
          },
        },
        monitor: {
          'External Display': {
            'Connected GPU': 'Radeon RX 580',
          },
        },
      );

      final model = _buildModel(rawInfo);

      expect(
        _bundlePaths(model),
        contains(ConfigKernel.WhateverGreen.bundlePath),
      );
      expect(
        _devicePropertyValue(model, ConfigDp.pciPath, 'AAPL,ig-platform-id'),
        '0300913E',
      );
    });

    test('adds XHCI unsupported kext for unsupported USB controller', () {
      final model = _buildModel(
        _rawInfo(
          usbControllers: {
            'Intel XHCI': {
              'Bus Type': 'PCI',
              'Device ID': '8086-A2AF',
            },
          },
        ),
      );

      expect(
        _bundlePaths(model),
        contains(ConfigKernel.XHCIUnsupported.bundlePath),
      );
    });

    test('adds SATA unsupported kext for Catalina and older', () {
      final model = _buildModel(
        _rawInfo(
          storageControllers: {
            'Intel SATA AHCI': {
              'Bus Type': 'PCI',
              'Device ID': '8086-A102',
              'DeviceDesc': 'Intel SATA AHCI Controller',
            },
          },
        ),
        options: const HardwareConfigOptions(macOSVersion: 'Catalina 10.15'),
      );

      expect(
        _bundlePaths(model),
        contains(ConfigKernel.SATAUnsupported.bundlePath),
      );
      expect(
        _bundlePaths(model),
        isNot(contains(ConfigKernel.CtlnaAHCIPort.bundlePath)),
      );
    });

    test('adds CtlnaAHCIPort kext for Big Sur and newer', () {
      final model = _buildModel(
        _rawInfo(
          storageControllers: {
            'Intel SATA AHCI': {
              'Bus Type': 'PCI',
              'Device ID': '8086-A102',
              'DeviceDesc': 'Intel SATA AHCI Controller',
            },
          },
        ),
        options: const HardwareConfigOptions(macOSVersion: 'BigSur 11'),
      );

      expect(
        _bundlePaths(model),
        contains(ConfigKernel.CtlnaAHCIPort.bundlePath),
      );
      expect(
        _bundlePaths(model),
        isNot(contains(ConfigKernel.SATAUnsupported.bundlePath)),
      );
    });

    test('adds NootedRed for supported AMD integrated GPU', () {
      final model = _buildModel(
        _rawInfo(
          cpuManufacturer: 'AMD',
          cpuName: 'AMD Ryzen 7 5800H',
          cpuCodename: 'Cezanne',
          motherboardPlatform: 'Laptop',
          gpu: {
            'AMD Radeon Graphics': {
              'Device Type': 'Integrated',
              'Manufacturer': 'AMD',
              'Device ID': '1002-1638',
            },
          },
        ),
      );

      expect(model.cpuType, CpuType.amd);
      expect(model.platformType, PlatformType.laptop);
      expect(model.platformCode, 'ryzen');
      expect(
        _bundlePaths(model),
        contains(ConfigKernel.NootedRed.bundlePath),
      );
    });

    test('keeps default boot args for AMD legacy NUC on Tahoe', () {
      final model = _buildModel(
        _rawInfo(
          cpuManufacturer: 'AMD',
          cpuName: 'AMD A8-7600 APU',
          cpuCodename: 'Kaveri',
          motherboardPlatform: 'NUC',
        ),
        options: const HardwareConfigOptions(macOSVersion: 'Tahoe 26'),
      );

      expect(model.cpuType, CpuType.amd);
      expect(model.platformType, PlatformType.nuc);
      expect(model.platformCode, 'bulldozer_jaguar');
      expect(BootArgsAccessor.contains(model, ConfigNvram.verbose.arg), isTrue);
      expect(
        BootArgsAccessor.contains(model, ConfigNvram.keepsyms1.arg),
        isTrue,
      );
      expect(
        BootArgsAccessor.contains(model, ConfigNvram.debug100.arg),
        isTrue,
      );
    });

    test('keeps default boot args for AMD legacy desktop on Tahoe', () {
      final model = _buildModel(
        _rawInfo(
          cpuManufacturer: 'AMD',
          cpuName: 'AMD A8-7600 APU',
          cpuCodename: 'Kaveri',
          motherboardPlatform: 'Desktop',
        ),
        options: const HardwareConfigOptions(macOSVersion: 'Tahoe 26'),
      );

      expect(model.cpuType, CpuType.amd);
      expect(model.platformType, PlatformType.desktop);
      expect(model.platformCode, 'bulldozer_jaguar');
      expect(BootArgsAccessor.contains(model, ConfigNvram.verbose.arg), isTrue);
      expect(
        BootArgsAccessor.contains(model, ConfigNvram.keepsyms1.arg),
        isTrue,
      );
      expect(
        BootArgsAccessor.contains(model, ConfigNvram.debug100.arg),
        isTrue,
      );
    });

    test('does not add static SSDT-GPI0 for I2C touchpad', () {
      final model = _buildModel(
        _rawInfo(
          motherboardPlatform: 'Laptop',
          inputDevices: {
            'I2C Touchpad': {
              'Device Type': 'I2C Touchpad',
              'Bus Type': 'I2C',
            },
          },
        ),
        options: const HardwareConfigOptions(
          cpuType: CpuType.intel,
          platformType: PlatformType.laptop,
          platformCode: 'coffee_lake_8th',
          macOSVersion: 'Tahoe 26',
        ),
      );

      expect(
        _bundlePaths(model),
        contains(ConfigKernel.VoodooI2C.bundlePath),
      );
      expect(
        model.acpi.acpiAddItems.map((item) => item.path),
        isNot(contains(ConfigAcpi.SSDT_GPI0.path)),
      );
    });
  });
}

ConfigModel _buildModel(
  Map<String, dynamic> rawInfo, {
  HardwareConfigOptions options = const HardwareConfigOptions(),
}) {
  return HardwareConfigModelBuilder(
    hardwareInfo: HardwareAllInfo.fromJson(rawInfo),
    rawInfo: rawInfo,
  ).build(options: options);
}

Set<String> _bundlePaths(ConfigModel model) {
  return model.kernel.kernelKexts.map((kext) => kext.bundlePath).toSet();
}

String? _devicePropertyValue(
  ConfigModel model,
  String pciPath,
  String key,
) {
  final properties = model.deviceProperties.addList ?? [];
  for (final propertyModel in properties) {
    if (propertyModel.pciPath != pciPath) continue;
    for (final item in propertyModel.propertyItems) {
      if (item.key == key) return item.value;
    }
  }
  return null;
}

Map<String, dynamic> _rawInfo({
  String cpuManufacturer = 'Intel',
  String cpuName = 'Intel Core i7-8700K',
  String cpuCodename = 'Coffee Lake',
  String simdFeatures = 'SSE4 AVX2',
  String motherboardManufacturer = 'ASUS',
  String motherboardProduct = 'Prime Z370-A',
  String motherboardChipset = '',
  String motherboardPlatform = 'Desktop',
  Map<String, dynamic>? gpu,
  Map<String, dynamic>? monitor,
  Map<String, dynamic>? storageControllers,
  Map<String, dynamic>? usbControllers,
  Map<String, dynamic>? inputDevices,
}) {
  return {
    'CPU': [
      {
        'Manufacturer': cpuManufacturer,
        'Name': cpuName,
        'Codename': cpuCodename,
        'SIMD Features': simdFeatures,
      }
    ],
    'Motherboard': {
      'Manufacturer': motherboardManufacturer,
      'Product': motherboardProduct,
      'Chipset': motherboardChipset,
      'Platform': motherboardPlatform,
    },
    'Network': {
      'Intel I219-V': {
        'Bus Type': 'PCI',
        'Device ID': '8086-15B8',
        'SubClass': '0',
      },
      'Intel Wireless AC 8265': {
        'Bus Type': 'PCI',
        'Device ID': '8086-24FD',
        'SubClass': '128',
      },
      'USB WiFi Dongle': {
        'Bus Type': 'USB',
        'Device ID': '0E8D-7612',
      },
      'Atheros AR9485': {
        'Bus Type': 'PCI',
        'Device ID': '168C-0032',
        'SubClass': '128',
      },
      'Broadcom BCM94360': {
        'Bus Type': 'PCI',
        'Device ID': '14E4-43A0',
        'SubClass': '128',
      },
      'Aquantia AQC107': {
        'Bus Type': 'PCI',
        'Device ID': '1D6A-D107',
        'SubClass': '0',
      },
    },
    'Audio': {
      'Realtek ALC255': {
        'DeviceDesc': 'Realtek ALC255',
        'Device ID': '8086-A348',
        'Codec Device ID': '10EC0255',
        'Controller Device ID': '8086-A348',
        'Bus Type': 'HDA',
      },
    },
    'Audio Controllers': {
      'Intel Cannon Lake PCH cAVS': {
        'DeviceDesc': 'Intel Cannon Lake PCH cAVS',
        'Device ID': '8086-A348',
        'Codec Device ID': '10EC0255',
        'Bus Type': 'PCI',
        'PCI Path': 'PciRoot(0x0)/Pci(0x1F,0x3)',
      },
    },
    'SD Controller': {
      'Realtek Card Reader': {
        'Device ID': '10EC-522A',
        'Bus Type': 'PCI',
        'DeviceDesc': 'Realtek Card Reader',
      },
    },
    'Storage Controllers': storageControllers ??
        {
          'NVMe Controller': {
            'Bus Type': 'PCI',
            'Device ID': '144D-A808',
            'DeviceDesc': 'Samsung NVMe Controller',
          },
        },
    if (usbControllers != null) 'USB Controllers': usbControllers,
    if (inputDevices != null) 'Input': inputDevices,
    if (gpu != null) 'GPU': gpu,
    if (monitor != null) 'Monitor': monitor,
  };
}
