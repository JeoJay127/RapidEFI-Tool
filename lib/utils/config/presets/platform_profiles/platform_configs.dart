import 'package:rapidefi/utils/config/presets/platform_profiles/configs_intel_laptop.dart';
import 'package:rapidefi/utils/config/presets/sections/config_device_properties.dart';
import 'package:rapidefi/utils/config/presets/sections/config_platform_info.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi_generic.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';

import 'configs_amd_desktop.dart';
import 'configs_amd_hedt.dart';
import 'configs_amd_laptop.dart';
import 'configs_amd_nuc.dart';
import 'configs_intel_desktop.dart';

import 'configs_intel_hedt.dart';
import 'configs_intel_nuc.dart';
import 'platform_config_repository.dart';
import 'platform_profile.dart';

class Configs {
  static final Configs _instance = Configs._();

  factory Configs() => _instance;

  late final ConfigsRepository configsRepository;

  Configs._() {
    configsRepository = ConfigsRepository();

    _registerConfigFactories();

    _registerPlatformModels();
  }

  void _registerConfigFactories() {
    configsRepository.registerAll(
      cpuType: CpuType.intel,
      platformType: PlatformType.desktop,
      factories: ConfigsIntelDesktop.factories,
    );

    configsRepository.registerAll(
      cpuType: CpuType.intel,
      platformType: PlatformType.laptop,
      factories: ConfigsIntelLaptop.factories,
    );

    configsRepository.registerAll(
      cpuType: CpuType.intel,
      platformType: PlatformType.nuc,
      factories: ConfigsIntelNuc.factories,
    );

    configsRepository.registerAll(
      cpuType: CpuType.intel,
      platformType: PlatformType.hedt,
      factories: ConfigsIntelHedt.factories,
    );

    configsRepository.registerAll(
      cpuType: CpuType.amd,
      platformType: PlatformType.desktop,
      factories: ConfigsAmdDesktop.factories,
    );

    configsRepository.registerAll(
      cpuType: CpuType.amd,
      platformType: PlatformType.laptop,
      factories: ConfigsAmdLaptop.factories,
    );

    configsRepository.registerAll(
      cpuType: CpuType.amd,
      platformType: PlatformType.nuc,
      factories: ConfigsAmdNuc.factories,
    );

    configsRepository.registerAll(
      cpuType: CpuType.amd,
      platformType: PlatformType.hedt,
      factories: ConfigsAmdHedt.factories,
    );
  }

  void _registerPlatformModels() {
    configsRepository.registerPlatformModel(platformModelsIntelDesktop);

    configsRepository.registerPlatformModel(platformModelsIntelLaptop);

    configsRepository.registerPlatformModel(platformModelsIntelNuc);

    configsRepository.registerPlatformModel(platformModelsIntelHedt);

    configsRepository.registerPlatformModel(platformModelsAmdDesktop);

    configsRepository.registerPlatformModel(platformModelsAmdLaptop);

    configsRepository.registerPlatformModel(platformModelsAmdNuc);

    configsRepository.registerPlatformModel(platformModelsAmdHedt);
  }

  PlatformModel get platformModelsIntelDesktop {
    return PlatformModel(
      cpuType: CpuType.intel,
      platformType: PlatformType.desktop,
      platforms: _intelDesktop,
    );
  }

  PlatformModel get platformModelsIntelLaptop {
    return PlatformModel(
      cpuType: CpuType.intel,
      platformType: PlatformType.laptop,
      platforms: _intelLaptop,
    );
  }

  PlatformModel get platformModelsIntelNuc {
    return PlatformModel(
      cpuType: CpuType.intel,
      platformType: PlatformType.nuc,
      platforms: _intelNuc,
    );
  }

  PlatformModel get platformModelsIntelHedt {
    return PlatformModel(
      cpuType: CpuType.intel,
      platformType: PlatformType.hedt,
      platforms: _intelHedt,
    );
  }

  PlatformModel get platformModelsAmdDesktop {
    return PlatformModel(
      cpuType: CpuType.amd,
      platformType: PlatformType.desktop,
      platforms: _amdDesktop,
    );
  }

  PlatformModel get platformModelsAmdLaptop {
    return PlatformModel(
      cpuType: CpuType.amd,
      platformType: PlatformType.laptop,
      platforms: _amdLaptop,
    );
  }

  PlatformModel get platformModelsAmdNuc {
    return PlatformModel(
      cpuType: CpuType.amd,
      platformType: PlatformType.nuc,
      platforms: _amdNuc,
    );
  }

  PlatformModel get platformModelsAmdHedt {
    return PlatformModel(
      cpuType: CpuType.amd,
      platformType: PlatformType.hedt,
      platforms: _amdHedt,
    );
  }

  static PlatformInfoGeneric iMac10_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac10,1',
    systemProductNameRelatedCPU: 'Intel Core 2 Duo E7600 @ 3.06 GHz',
  );

  static PlatformInfoGeneric iMac11_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac11,1',
    systemProductNameRelatedCPU: 'Intel Core i7-870 @ 2.93 GHz',
  );

  static PlatformInfoGeneric iMac11_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac11,2',
    systemProductNameRelatedCPU: 'Intel Core i7-860S @ 2.53 GHz',
  );

  static PlatformInfoGeneric iMac12_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac12,2',
    systemProductNameRelatedCPU: 'Intel Core i7-2600S @ 2.80 GHz',
  );

  static PlatformInfoGeneric iMac13_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac13,1',
    systemProductNameRelatedCPU: 'Intel Core i7-3770S @ 3.10 GHz',
  );
  static PlatformInfoGeneric iMac13_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac13,2',
    systemProductNameRelatedCPU: 'Intel Core i5-3470S @ 2.90 GHz',
  );

  static PlatformInfoGeneric iMac14_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac14,2',
    systemProductNameRelatedCPU: 'Intel Core i7-4771 @ 3.50 GHz',
  );
  static PlatformInfoGeneric iMac14_4 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac14,4',
    systemProductNameRelatedCPU: 'Intel Core i5-4260U @ 1.40 GHz',
  );

  static PlatformInfoGeneric iMac15_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac15,1',
    systemProductNameRelatedCPU: 'Intel Core i7-4790k @ 4.00 GHz',
  );

  static PlatformInfoGeneric iMac16_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac16,1',
    systemProductNameRelatedCPU: 'Intel Core i5-5675R @ 3.10 GHz',
  );
  static PlatformInfoGeneric iMac16_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac16,2',
    systemProductNameRelatedCPU: 'Intel Core i5-5575R @ 2.80 GHz',
  );

  static PlatformInfoGeneric iMac17_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac17,1',
    systemProductNameRelatedCPU: 'Intel Core i5-6500 @ 3.20 GHz',
  );

  static PlatformInfoGeneric iMac18_3 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac18,3',
    systemProductNameRelatedCPU: 'Intel Core i5-7600K @ 3.80 GHz',
  );

  static PlatformInfoGeneric iMac19_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac19,1',
    systemProductNameRelatedCPU: 'Intel Core i9-9900K @ 3.60 GHz',
  );
  static PlatformInfoGeneric iMac19_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac19,2',
    systemProductNameRelatedCPU: 'Intel Core i5-8500 @ 3.00 GHz',
  );

  static PlatformInfoGeneric iMac20_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac20,1',
    systemProductNameRelatedCPU: 'Intel Core i7-10700K @ 3.80 GHz',
  );
  static PlatformInfoGeneric iMac20_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMac20,2',
    systemProductNameRelatedCPU: 'Intel Core i9-10910 @ 3.60 GHz',
  );

  static PlatformInfoGeneric iMacPro1_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'iMacPro1,1',
    systemProductNameRelatedCPU: 'Intel Xeon W-2140B @ 3.20 GHz',
  );

  static PlatformInfoGeneric Macmini3_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'Macmini3,1',
    systemProductNameRelatedCPU: 'Intel Core 2 Duo P7350 @ 2.00 GHz',
  );
  static PlatformInfoGeneric Macmini4_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'Macmini4,1',
    systemProductNameRelatedCPU: 'Intel Core 2 Duo P8600 @ 2.40 GHz',
  );
  static PlatformInfoGeneric Macmini5_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'Macmini5,1',
    systemProductNameRelatedCPU: 'Intel Core i5-2415M @ 2.30 GHz',
  );
  static PlatformInfoGeneric Macmini5_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'Macmini5,2',
    systemProductNameRelatedCPU: 'Intel Core i7-2635QM @ 2.00 GHz',
  );
  static PlatformInfoGeneric Macmini5_3 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'Macmini5,3',
    systemProductNameRelatedCPU: 'Intel Core i7-2635QM @ 2.00 GHz',
  );
  static PlatformInfoGeneric Macmini6_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'Macmini6,1',
    systemProductNameRelatedCPU: 'Intel Core i5-3210M @ 2.50 GHz',
  );
  static PlatformInfoGeneric Macmini6_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'Macmini6,2',
    systemProductNameRelatedCPU: 'Intel Core i7-3615QM @ 2.30 GHz',
  );
  static PlatformInfoGeneric Macmini7_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'Macmini7,1',
    systemProductNameRelatedCPU: 'Intel Core i5-4260U @ 1.40 GHz',
  );
  static PlatformInfoGeneric Macmini8_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'Macmini8,1',
    systemProductNameRelatedCPU: 'Intel Core i7-8700B @ 3.20 GHz',
  );

  static PlatformInfoGeneric MacBook5_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBook5,1',
    systemProductNameRelatedCPU: 'Intel Core 2 Duo P8600 @ 2.40 GHz',
  );

  static PlatformInfoGeneric MacBook5_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBook5,2',
    systemProductNameRelatedCPU: 'Intel Core 2 Duo P8700 @ 2.53 GHz',
  );

  static PlatformInfoGeneric MacBook6_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBook6,1',
    systemProductNameRelatedCPU: 'Intel Core 2 Duo P7550 @ 2.26 GHz',
  );

  static PlatformInfoGeneric MacBook8_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBook8,1',
    systemProductNameRelatedCPU: 'Intel Core M-5Y51 @ 1.10 GHz',
  );
  static PlatformInfoGeneric MacBook9_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBook9,1',
    systemProductNameRelatedCPU: 'Intel Core m3-6Y30 @ 1.10 GHz',
  );
  static PlatformInfoGeneric MacBook10_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBook10,1',
    systemProductNameRelatedCPU: 'Intel Core i5-7Y54 @ 1.20 GHz',
  );

  static PlatformInfoGeneric MacBookAir4_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookAir4,1',
    systemProductNameRelatedCPU: 'Intel Core i5-2557M @ 1.70 GHz',
  );
  static PlatformInfoGeneric MacBookAir4_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookAir4,2',
    systemProductNameRelatedCPU: 'Intel Core i5-2557M @ 1.70 GHz',
  );
  static PlatformInfoGeneric MacBookAir5_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookAir5,1',
    systemProductNameRelatedCPU: 'Intel Core i5-3317U @ 1.70 GHz',
  );
  static PlatformInfoGeneric MacBookAir5_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookAir5,2',
    systemProductNameRelatedCPU: 'Intel Core i5-3427U @ 1.80 GHz',
  );
  static PlatformInfoGeneric MacBookAir6_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookAir6,1',
    systemProductNameRelatedCPU: 'Intel Core i5-4250U @ 1.30 GHz',
  );
  static PlatformInfoGeneric MacBookAir6_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookAir6,2',
    systemProductNameRelatedCPU: 'Intel Core i5-4250U @ 1.30 GHz',
  );
  static PlatformInfoGeneric MacBookAir7_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookAir7,1',
    systemProductNameRelatedCPU: 'Intel Core i5-5250U @ 1.60 GHz',
  );
  static PlatformInfoGeneric MacBookAir7_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookAir7,2',
    systemProductNameRelatedCPU: 'Intel Core i5-5250U @ 1.60 GHz',
  );
  static PlatformInfoGeneric MacBookAir9_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookAir9,1',
    systemProductNameRelatedCPU: 'Intel Core i5-1030NG7 @ 1.10 GHz',
  );

  static PlatformInfoGeneric MacBookPro5_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro5,1',
    systemProductNameRelatedCPU: 'Intel Core 2 Duo P8600 @ 2.40 GHz',
  );
  static PlatformInfoGeneric MacBookPro5_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro5,2',
    systemProductNameRelatedCPU: 'Intel Core 2 Duo P8700 @ 2.53 GHz',
  );
  static PlatformInfoGeneric MacBookPro5_3 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro5,3',
    systemProductNameRelatedCPU: 'Intel Core 2 Duo T9600 @ 2.80 GHz',
  );
  static PlatformInfoGeneric MacBookPro5_4 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro5,4',
    systemProductNameRelatedCPU: 'Intel Core 2 Duo P8700 @ 2.53 GHz',
  );

  static PlatformInfoGeneric MacBookPro6_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro6,1',
    systemProductNameRelatedCPU: 'Intel Core i5-540M @ 2.53 GHz',
  );
  static PlatformInfoGeneric MacBookPro6_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro6,2',
    systemProductNameRelatedCPU: 'Intel Core i5-520M @ 2.40 GHz',
  );

  static PlatformInfoGeneric MacBookPro8_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro8,1',
    systemProductNameRelatedCPU: 'Intel Core i5-2415M @ 2.30 GHz',
  );
  static PlatformInfoGeneric MacBookPro8_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro8,2',
    systemProductNameRelatedCPU: 'Intel Core i7-2675QM @ 2.20 GHz',
  );
  static PlatformInfoGeneric MacBookPro8_3 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro8,3',
    systemProductNameRelatedCPU: 'Intel Core i7-2860QM @ 2.50 GHz',
  );

  static PlatformInfoGeneric MacBookPro9_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro9,2',
    systemProductNameRelatedCPU: 'Intel Core i7-3615QM @ 2.30 GHz',
  );

  static PlatformInfoGeneric MacBookPro10_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro10,1',
    systemProductNameRelatedCPU: 'Intel Core i7-3615QM @ 2.30 GHz',
  );
  static PlatformInfoGeneric MacBookPro10_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro10,2',
    systemProductNameRelatedCPU: 'Intel Core i5-3210M @ 2.50 GHz',
  );

  static PlatformInfoGeneric MacBookPro11_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro11,1',
    systemProductNameRelatedCPU: 'Intel Core i7-4870HQ @ 2.50 GHz',
  );
  static PlatformInfoGeneric MacBookPro11_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro11,2',
    systemProductNameRelatedCPU: 'Intel Core i7-4770HQ @ 2.20 GHz',
  );
  static PlatformInfoGeneric MacBookPro11_3 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro11,3',
    systemProductNameRelatedCPU: 'Intel Core i7-4960HQ @ 2.60 GHz',
  );
  static PlatformInfoGeneric MacBookPro11_4 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro11,4',
    systemProductNameRelatedCPU: 'Intel Core i7-4980HQ @ 2.80 GHz',
  );
  static PlatformInfoGeneric MacBookPro11_5 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro11,5',
    systemProductNameRelatedCPU: 'Intel Core i7-4980HQ @ 2.80 GHz',
  );

  static PlatformInfoGeneric MacBookPro12_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro12,1',
    systemProductNameRelatedCPU: 'Intel Core i5-5257U @ 2.70 GHz',
  );

  static PlatformInfoGeneric MacBookPro13_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro13,1',
    systemProductNameRelatedCPU: 'Intel Core i5-6267U @ 2.90 GHz',
  );
  static PlatformInfoGeneric MacBookPro13_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro13,2',
    systemProductNameRelatedCPU: 'Intel Core i7-6567U @ 3.30 GHz',
  );
  static PlatformInfoGeneric MacBookPro13_3 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro13,3',
    systemProductNameRelatedCPU: 'Intel Core i7-6700HQ @ 2.60 GHz',
  );

  static PlatformInfoGeneric MacBookPro14_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro14,1',
    systemProductNameRelatedCPU: 'Intel Core i7-7700HQ @ 2.80 GHz',
  );
  static PlatformInfoGeneric MacBookPro14_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro14,2',
    systemProductNameRelatedCPU: 'Intel Core i7-7567U @ 3.50 GHz',
  );
  static PlatformInfoGeneric MacBookPro14_3 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro14,3',
    systemProductNameRelatedCPU: 'Intel Core i7-7700HQ @ 2.80 GHz',
  );

  static PlatformInfoGeneric MacBookPro15_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro15,1',
    systemProductNameRelatedCPU: 'Intel Core i7-8750H @ 2.20 GHz',
  );
  static PlatformInfoGeneric MacBookPro15_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro15,2',
    systemProductNameRelatedCPU: 'Intel Core i7-8850H @ 2.60 GHz',
  );
  static PlatformInfoGeneric MacBookPro15_3 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro15,3',
    systemProductNameRelatedCPU: 'Intel Core i9-8950HK @ 2.90 GHz',
  );
  static PlatformInfoGeneric MacBookPro15_4 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro15,4',
    systemProductNameRelatedCPU: 'Intel Core i7-8559U @ 2.70 GHz',
  );

  static PlatformInfoGeneric MacBookPro16_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro16,1',
    systemProductNameRelatedCPU: 'Intel Core i9-9980HK @ 2.40 GHz',
  );
  static PlatformInfoGeneric MacBookPro16_2 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro16,2',
    systemProductNameRelatedCPU: 'Intel Core i9-9980HK @ 2.40 GHz',
  );
  static PlatformInfoGeneric MacBookPro16_3 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro16,3',
    systemProductNameRelatedCPU: 'Intel Core i7-9750H @ 2.60 GHz',
  );
  static PlatformInfoGeneric MacBookPro16_4 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacBookPro16,4',
    systemProductNameRelatedCPU: 'Intel Core i9-9980HK @ 2.40 GHz',
  );

  static PlatformInfoGeneric MacPro6_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacPro6,1',
    systemProductNameRelatedCPU: 'Intel Xeon E5-2697 v2 @ 2.70 GHz',
  );

  static PlatformInfoGeneric MacPro7_1 =
      ConfigPi.commonPlatformInfoGeneric.copyWith(
    systemProductName: 'MacPro7,1',
    systemProductNameRelatedCPU: 'Intel Xeon W-3245M CPU @ 3.20 GHz',
  );

  static final Map<String, PlatformEntry> _intelDesktop = {
    'penryn': PlatformEntry(
        label: '0代-Penryn-775平台',
        smbiosOptions: [iMac10_1, MacPro6_1, MacPro7_1, iMacPro1_1]),
    'lynnfield': PlatformEntry(
        label: '1代-Lynnfield-1156平台',
        smbiosOptions: [iMac11_1, iMac11_2, MacPro7_1, iMacPro1_1, MacPro6_1]),
    'sandy_bridge':
        PlatformEntry(label: '2代-Sandy Bridge-1155平台', smbiosOptions: [
      iMac12_2,
      iMac20_1,
      MacPro7_1,
      iMacPro1_1,
      MacPro6_1
    ], igpuModes: [
      ConfigDp.intel_desktop_2th,
      ConfigDp.intel_desktop_display_none_2th,
      ConfigDp.intel_desktop_computing_2th
    ]),
    'ivy_bridge': PlatformEntry(label: '3代-Ivy Bridge-1155平台', smbiosOptions: [
      iMac20_1,
      iMac13_1,
      iMac13_2,
      iMac19_1,
      iMac19_2,
      iMac20_2,
      MacPro7_1,
      iMacPro1_1
    ], igpuModes: [
      ConfigDp.intel_desktop_3th,
      ConfigDp.intel_desktop_display_none_3th,
      ConfigDp.intel_desktop_computing_3th
    ]),
    'haswell': PlatformEntry(label: '4代-Haswell-1150平台', smbiosOptions: [
      iMac20_1,
      iMac14_4,
      iMac15_1,
      iMac19_1,
      iMac19_2,
      iMac20_2,
      MacPro7_1,
      iMacPro1_1
    ], igpuModes: [
      ConfigDp.intel_desktop_4th,
      ConfigDp.intel_desktop_display_none_4th,
      ConfigDp.intel_desktop_computing_4th
    ]),
    'broadwell': PlatformEntry(label: '5代-Broadwell-1150平台', smbiosOptions: [
      iMac20_1,
      iMac16_1,
      iMac16_2,
      iMac19_1,
      iMac19_2,
      iMac20_2,
      MacPro7_1,
      iMacPro1_1
    ], igpuModes: [
      ConfigDp.intel_desktop_5th_1,
      ConfigDp.intel_desktop_5th_2,
      ConfigDp.intel_desktop_5th_3,
      ConfigDp.intel_desktop_display_none_5th,
      ConfigDp.intel_desktop_computing_5th
    ]),
    'skylake': PlatformEntry(label: '6代-Skylake-1151平台', smbiosOptions: [
      iMac20_1,
      iMac17_1,
      iMac19_1,
      iMac18_3,
      iMac20_2,
      MacPro7_1,
      iMacPro1_1
    ], igpuModes: [
      ConfigDp.intel_desktop_6th_1,
      ConfigDp.intel_desktop_6th_2,
      ConfigDp.intel_desktop_6th_3,
      ConfigDp.intel_desktop_display_none_6th,
      ConfigDp.intel_desktop_computing_6th
    ]),
    'kaby_lake': PlatformEntry(label: '7代-Kaby Lake-1151平台', smbiosOptions: [
      iMac20_1,
      iMac19_1,
      iMac18_3,
      iMac20_2,
      MacPro7_1,
      iMacPro1_1
    ], igpuModes: [
      ConfigDp.intel_desktop_7th_1,
      ConfigDp.intel_desktop_7th_2,
      ConfigDp.intel_desktop_7th_3,
      ConfigDp.intel_desktop_display_none_7th,
      ConfigDp.intel_desktop_computing_7th
    ]),
    'coffee_lake_8th':
        PlatformEntry(label: '8代-Coffee Lake-1151平台', smbiosOptions: [
      iMac20_1,
      iMac19_1,
      iMac19_2,
      iMac18_3,
      iMac20_2,
      MacPro7_1,
      iMacPro1_1
    ], igpuModes: [
      ConfigDp.intel_desktop_8th_1,
      ConfigDp.intel_desktop_8th_2,
      ConfigDp.intel_desktop_display_none_8th,
      ConfigDp.intel_desktop_computing_8th
    ]),
    'coffee_lake_9th':
        PlatformEntry(label: '9代-Coffee Lake-1151平台', smbiosOptions: [
      iMac20_1,
      iMac19_1,
      iMac19_2,
      iMac20_2,
      MacPro7_1,
      iMacPro1_1
    ], igpuModes: [
      ConfigDp.intel_desktop_8th_1,
      ConfigDp.intel_desktop_8th_2,
      ConfigDp.intel_desktop_display_none_8th,
      ConfigDp.intel_desktop_computing_8th
    ]),
    'comet_lake': PlatformEntry(label: '10代-Comet Lake-1200平台', smbiosOptions: [
      iMac20_1,
      iMac20_2,
      MacPro7_1,
      iMacPro1_1
    ], igpuModes: [
      ConfigDp.intel_desktop_8th_1,
      ConfigDp.intel_desktop_8th_2,
      ConfigDp.intel_desktop_display_none_8th,
      ConfigDp.intel_desktop_computing_10th
    ]),
    'rocket_lake': PlatformEntry(
        label: '11代-Rocket Lake-1200平台',
        smbiosOptions: [MacPro7_1, iMacPro1_1]),
    'alder_lake': PlatformEntry(
        label: '12代-Alder Lake-1700平台', smbiosOptions: [MacPro7_1, iMacPro1_1]),
    'raptor_lake': PlatformEntry(
        label: '13代-Raptor Lake-1700平台',
        smbiosOptions: [MacPro7_1, iMacPro1_1]),
    'raptor_lake_refresh': PlatformEntry(
        label: '14代-Raptor Lake Refresh-1700平台',
        smbiosOptions: [MacPro7_1, iMacPro1_1]),
    'arrow_lake': PlatformEntry(
        label: '15代-Arrow Lake-1851平台', smbiosOptions: [MacPro7_1, iMacPro1_1]),
  };

  static final Map<String, PlatformEntry> _intelLaptop = {
    'penryn': PlatformEntry(label: '0代-Penryn-笔记本', smbiosOptions: [
      MacBookPro5_1,
      MacBookPro5_2,
      MacBookPro5_3,
      MacBookPro5_4,
      MacBookPro9_2,
      MacBookPro10_2,
      MacBookPro16_3,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ]),
    'clarksfield_arrandale':
        PlatformEntry(label: '1代-Clarksfield&Arrandale-笔记本', smbiosOptions: [
      MacBookPro6_1,
      MacBookPro6_2,
      MacBookPro9_2,
      MacBookPro10_2,
      MacBookPro16_3,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_laptop_1th
    ]),
    'sandy_bridge': PlatformEntry(label: '2代-Sandy Bridge-笔记本', smbiosOptions: [
      MacBookAir4_1,
      MacBookAir4_2,
      MacBookPro8_1,
      MacBookPro8_2,
      MacBookPro8_3,
      MacBookPro9_2,
      MacBookPro10_2,
      MacBookPro16_3,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_laptop_2th_1,
      ConfigDp.intel_laptop_2th_2,
      ConfigDp.intel_laptop_2th_3
    ]),
    'ivy_bridge': PlatformEntry(label: '3代-Ivy Bridge-笔记本', smbiosOptions: [
      MacBookPro10_2,
      MacBookAir5_1,
      MacBookAir5_2,
      MacBookPro9_2,
      MacBookPro10_1,
      MacBookPro16_3,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_laptop_3th_1,
      ConfigDp.intel_laptop_3th_2,
      ConfigDp.intel_laptop_3th_3,
      ConfigDp.intel_laptop_3th_4
    ]),
    'haswell': PlatformEntry(label: '4代-Haswell-笔记本', smbiosOptions: [
      MacBookPro16_3,
      MacBookAir6_1,
      MacBookAir6_2,
      MacBookPro11_1,
      MacBookPro11_2,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_laptop_4th_1,
      ConfigDp.intel_laptop_4th_2,
      ConfigDp.intel_laptop_4th_3
    ]),
    'broadwell': PlatformEntry(label: '5代-Broadwell-笔记本', smbiosOptions: [
      MacBookPro16_3,
      MacBookAir7_1,
      MacBookAir7_2,
      MacBookPro12_1,
      MacBookPro11_2,
      MacBookPro11_3,
      MacBookPro11_4,
      MacBookPro11_5,
      MacBook8_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_laptop_5th_1,
      ConfigDp.intel_laptop_5th_2,
      ConfigDp.intel_laptop_5th_3,
      ConfigDp.intel_laptop_5th_4
    ]),
    'skylake': PlatformEntry(label: '6代-Skylake-笔记本', smbiosOptions: [
      MacBookPro16_3,
      MacBookPro13_1,
      MacBookPro13_2,
      MacBookPro13_3,
      MacBook9_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_laptop_6th_1,
      ConfigDp.intel_laptop_6th_2,
      ConfigDp.intel_laptop_6th_3,
      ConfigDp.intel_laptop_6th_4,
      ConfigDp.intel_laptop_6th_5
    ]),
    'kaby_lake': PlatformEntry(label: '7代-Kaby Lake-笔记本', smbiosOptions: [
      MacBookPro16_3,
      MacBookPro14_1,
      MacBookPro14_2,
      MacBookPro14_3,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_laptop_7th_1,
      ConfigDp.intel_laptop_7th_2,
      ConfigDp.intel_laptop_7th_3,
      ConfigDp.intel_laptop_7th_4
    ]),
    'coffee_lake_8th':
        PlatformEntry(label: '8代-Coffee Lake-笔记本', smbiosOptions: [
      MacBookPro16_3,
      MacBookPro15_1,
      MacBookPro15_2,
      MacBookPro15_3,
      MacBookPro15_4,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_laptop_8th_1,
      ConfigDp.intel_laptop_8th_2,
      ConfigDp.intel_laptop_8th_3,
      ConfigDp.intel_laptop_8th_4
    ]),
    'coffee_lake_9th':
        PlatformEntry(label: '9代-Coffee Lake-笔记本', smbiosOptions: [
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_3,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_laptop_9th_1,
      ConfigDp.intel_laptop_9th_2,
      ConfigDp.intel_laptop_9th_3
    ]),
    'comet_lake': PlatformEntry(label: '10代-Comet Lake-笔记本', smbiosOptions: [
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_3,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_laptop_10th_1,
      ConfigDp.intel_laptop_10th_2,
      ConfigDp.intel_laptop_10th_3
    ]),
    'ice_lake': PlatformEntry(label: '10代-Ice Lake-笔记本', smbiosOptions: [
      MacBookAir9_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_3,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_laptop_iceLake_1,
      ConfigDp.intel_laptop_iceLake_2
    ]),
    'tiger_lake': PlatformEntry(label: '11代-Tiger Lake-笔记本', smbiosOptions: [
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_3,
      MacBookPro16_4
    ]),
    'alder_lake': PlatformEntry(label: '12代-Alder Lake-笔记本', smbiosOptions: [
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_3,
      MacBookPro16_4
    ]),
    'raptor_lake': PlatformEntry(label: '13代-Raptor Lake-笔记本', smbiosOptions: [
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_3,
      MacBookPro16_4
    ]),
    'raptor_lake_refresh':
        PlatformEntry(label: '14代-Raptor Lake Refresh-笔记本', smbiosOptions: [
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_3,
      MacBookPro16_4
    ]),
  };

  static final Map<String, PlatformEntry> _intelNuc = {
    'penryn': PlatformEntry(label: '0代-Penryn-迷你主机', smbiosOptions: [
      Macmini3_1,
      Macmini4_1,
      iMac10_1,
      Macmini7_1,
      Macmini8_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ]),
    'clarksfield_arrandale':
        PlatformEntry(label: '1代-Clarksfield&Arrandale-迷你主机', smbiosOptions: [
      Macmini7_1,
      Macmini8_1,
      MacBookPro6_1,
      MacBookPro6_2,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_nuc_1th
    ]),
    'sandy_bridge':
        PlatformEntry(label: '2代-Sandy Bridge-迷你主机', smbiosOptions: [
      Macmini5_1,
      Macmini5_2,
      Macmini5_3,
      Macmini7_1,
      Macmini8_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_nuc_2th_1,
      ConfigDp.intel_nuc_2th_2
    ]),
    'ivy_bridge': PlatformEntry(label: '3代-Ivy Bridge-迷你主机', smbiosOptions: [
      Macmini6_1,
      Macmini6_2,
      Macmini7_1,
      Macmini8_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_nuc_3th_1,
      ConfigDp.intel_nuc_3th_2
    ]),
    'haswell': PlatformEntry(label: '4代-Haswell-迷你主机', smbiosOptions: [
      Macmini7_1,
      Macmini8_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_nuc_4th_1,
      ConfigDp.intel_nuc_4th_2
    ]),
    'broadwell': PlatformEntry(label: '5代-Broadwell-迷你主机', smbiosOptions: [
      iMac16_1,
      Macmini7_1,
      Macmini8_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_nuc_5th_1,
      ConfigDp.intel_nuc_5th_2,
      ConfigDp.intel_nuc_5th_3,
      ConfigDp.intel_nuc_5th_4
    ]),
    'skylake': PlatformEntry(label: '6代-Skylake-迷你主机', smbiosOptions: [
      iMac17_1,
      Macmini8_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_nuc_6th_1,
      ConfigDp.intel_nuc_6th_2,
      ConfigDp.intel_nuc_6th_3,
      ConfigDp.intel_nuc_6th_4,
      ConfigDp.intel_nuc_6th_5,
      ConfigDp.intel_nuc_6th_6,
      ConfigDp.intel_nuc_6th_7
    ]),
    'kaby_lake': PlatformEntry(label: '7代-Kaby Lake-迷你主机', smbiosOptions: [
      iMac19_1,
      Macmini8_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_nuc_7th_1,
      ConfigDp.intel_nuc_7th_2,
      ConfigDp.intel_nuc_7th_3,
      ConfigDp.intel_nuc_7th_4,
      ConfigDp.intel_nuc_7th_5
    ]),
    'coffee_lake_8th':
        PlatformEntry(label: '8代-Coffee Lake-迷你主机', smbiosOptions: [
      Macmini8_1,
      iMac19_1,
      iMac19_2,
      MacPro7_1,
      iMacPro1_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_nuc_8th_1,
      ConfigDp.intel_nuc_8th_2,
      ConfigDp.intel_nuc_8th_3,
      ConfigDp.intel_nuc_8th_4
    ]),
    'coffee_lake_9th':
        PlatformEntry(label: '9代-Coffee Lake-迷你主机', smbiosOptions: [
      Macmini8_1,
      iMac19_1,
      iMac19_2,
      MacPro7_1,
      iMacPro1_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ], igpuModes: [
      ConfigDp.intel_nuc_9th_1,
      ConfigDp.intel_nuc_9th_2,
      ConfigDp.intel_nuc_9th_3
    ]),
    'comet_lake': PlatformEntry(label: '10代-Comet Lake-迷你主机', smbiosOptions: [
      MacBookPro16_1,
      MacBookPro16_3,
      MacBookPro16_4,
      Macmini8_1,
      MacPro7_1,
      iMacPro1_1
    ], igpuModes: [
      ConfigDp.intel_nuc_10th_1,
      ConfigDp.intel_nuc_10th_2,
      ConfigDp.intel_nuc_10th_3
    ]),
    'ice_lake': PlatformEntry(label: '10代-Ice Lake-迷你主机', smbiosOptions: [
      MacBookAir9_1,
      MacBookPro16_2,
      MacBookPro16_1,
      MacBookPro16_4,
      Macmini8_1,
      MacPro7_1,
      iMacPro1_1
    ], igpuModes: [
      ConfigDp.intel_nuc_iceLake_1,
      ConfigDp.intel_nuc_iceLake_2
    ]),
    'tiger_lake': PlatformEntry(label: '11代-Tiger Lake-迷你主机', smbiosOptions: [
      MacPro7_1,
      iMacPro1_1,
      iMac20_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ]),
    'alder_lake': PlatformEntry(label: '12代-Alder Lake-迷你主机', smbiosOptions: [
      MacPro7_1,
      iMacPro1_1,
      iMac20_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ]),
    'raptor_lake': PlatformEntry(label: '13代-Raptor Lake-迷你主机', smbiosOptions: [
      MacPro7_1,
      iMacPro1_1,
      iMac20_1,
      MacBookPro16_1,
      MacBookPro16_2,
      MacBookPro16_4
    ]),
    'raptor_lake_refresh': PlatformEntry(
        label: '14代-Raptor Lake Refresh-迷你主机',
        smbiosOptions: [
          MacPro7_1,
          iMacPro1_1,
          iMac20_1,
          MacBookPro16_1,
          MacBookPro16_2,
          MacBookPro16_4
        ]),
  };

  static final Map<String, PlatformEntry> _intelHedt = {
    'nehalem_westmere': PlatformEntry(
        label: '1代-Nehalem&Westmere-X58平台',
        smbiosOptions: [MacPro6_1, MacPro7_1, iMacPro1_1]),
    'sandy_bridge_e': PlatformEntry(
        label: '2代-Sandy Bridge-E-X79平台',
        smbiosOptions: [MacPro7_1, iMacPro1_1]),
    'ivy_bridge_e': PlatformEntry(
        label: '3代-Ivy Bridge-E-X79平台', smbiosOptions: [MacPro7_1, iMacPro1_1]),
    'haswell_e': PlatformEntry(
        label: '4代-Haswell-E-X99平台', smbiosOptions: [MacPro7_1, iMacPro1_1]),
    'broadwell_e': PlatformEntry(
        label: '5代-Broadwell-E-X99平台', smbiosOptions: [MacPro7_1, iMacPro1_1]),
    'skylake_x_w': PlatformEntry(
        label: '6代-Skylake-X&W-X299平台', smbiosOptions: [MacPro7_1, iMacPro1_1]),
    'cascade_lake_x_w': PlatformEntry(
        label: '10代-Cascade Lake-X&W平台',
        smbiosOptions: [MacPro7_1, iMacPro1_1]),
  };

  static final Map<String, PlatformEntry> _amdDesktop = {
    'bulldozer_jaguar': PlatformEntry(
        label: 'Bulldozer(15h) and Jaguar(16h)',
        smbiosOptions: [MacPro7_1, MacPro6_1, iMacPro1_1, iMac14_2, iMac20_1]),
    'ryzen_threadripper': PlatformEntry(
        label: 'Ryzen and Threadripper(17h and 19h)',
        smbiosOptions: [MacPro7_1, MacPro6_1, iMacPro1_1, iMac14_2, iMac20_1]),
  };

  static final Map<String, PlatformEntry> _amdLaptop = {
    'bulldozer_jaguar': PlatformEntry(
        label: 'Bulldozer(15h) and Jaguar(16h)-笔记本',
        smbiosOptions: [
          MacBookPro16_2,
          MacBookPro16_1,
          MacBookPro16_4,
          MacBookPro16_3,
          MacBookAir9_1
        ]),
    'ryzen': PlatformEntry(
        label: 'Ryzen-笔记本',
        smbiosOptions: [
          MacBookPro16_2,
          MacBookPro16_1,
          MacBookPro16_4,
          MacBookPro16_3,
          MacBookAir9_1
        ]),
  };

  static final Map<String, PlatformEntry> _amdNuc = {
    'bulldozer_jaguar': PlatformEntry(
        label: 'Bulldozer(15h) and Jaguar(16h)-迷你主机',
        smbiosOptions: [iMac20_1, MacPro7_1, MacPro6_1, iMacPro1_1, iMac14_2]),
    'ryzen': PlatformEntry(
        label: 'Ryzen-迷你主机',
        smbiosOptions: [MacPro7_1, MacPro6_1, iMacPro1_1, iMac14_2, iMac20_1]),
  };

  static final Map<String, PlatformEntry> _amdHedt = {
    'ryzen_threadripper': PlatformEntry(
        label: 'Ryzen and Threadripper(17h and 19h)-服务器',
        smbiosOptions: [MacPro7_1, MacPro6_1, iMacPro1_1]),
  };
}
