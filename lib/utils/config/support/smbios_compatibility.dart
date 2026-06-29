import 'package:rapidefi/utils/config/models/platform_info/pi_generic.dart';
import 'package:rapidefi/utils/config/support/macos_version.dart';

class SMBIOSCompatibility {
  const SMBIOSCompatibility._();

  static const Map<String, ({int min, int max})> _supportRanges = {
    'iMac10,1': (min: 10, max: 17),
    'iMac11,1': (min: 10, max: 17),
    'iMac11,2': (min: 10, max: 17),
    'iMac12,2': (min: 10, max: 17),
    'iMac13,1': (min: 12, max: 19),
    'iMac13,2': (min: 12, max: 19),
    'iMac14,2': (min: 13, max: 20),
    'iMac14,4': (min: 13, max: 20),
    'iMac15,1': (min: 13, max: 20),
    'iMac16,1': (min: 15, max: 21),
    'iMac16,2': (min: 15, max: 21),
    'iMac17,1': (min: 15, max: 21),
    'iMac18,1': (min: 16, max: 22),
    'iMac18,3': (min: 16, max: 22),
    'iMac19,2': (min: 18, max: 24),
    'iMac19,1': (min: 18, max: 24),
    'iMac20,1': (min: 19, max: 25),
    'iMac20,2': (min: 19, max: 25),
    'MacBookPro5,1': (min: 9, max: 15),
    'MacBookPro5,2': (min: 9, max: 15),
    'MacBookPro5,3': (min: 9, max: 15),
    'MacBookPro5,4': (min: 9, max: 15),
    'MacBookPro6,1': (min: 10, max: 17),
    'MacBookPro6,2': (min: 10, max: 17),
    'MacBookAir4,1': (min: 11, max: 17),
    'MacBookAir4,2': (min: 11, max: 17),
    'MacBookPro8,1': (min: 11, max: 17),
    'MacBookPro8,2': (min: 11, max: 17),
    'MacBookPro8,3': (min: 11, max: 17),
    'Macmini5,1': (min: 11, max: 17),
    'Macmini5,2': (min: 11, max: 17),
    'Macmini5,3': (min: 11, max: 17),
    'MacBookAir5,1': (min: 12, max: 19),
    'MacBookAir5,2': (min: 12, max: 19),
    'MacBookPro9,2': (min: 12, max: 19),
    'MacBookPro10,1': (min: 12, max: 19),
    'MacBookPro10,2': (min: 12, max: 19),
    'Macmini6,1': (min: 12, max: 19),
    'Macmini6,2': (min: 12, max: 19),
    'MacBookAir6,1': (min: 13, max: 20),
    'MacBookAir6,2': (min: 13, max: 20),
    'MacBookPro11,1': (min: 13, max: 20),
    'MacBookPro11,2': (min: 13, max: 20),
    'MacBookPro11,3': (min: 13, max: 20),
    'MacBookPro11,4': (min: 17, max: 21),
    'MacBookPro11,5': (min: 17, max: 21),
    'Macmini3,1': (min: 9, max: 15),
    'Macmini4,1': (min: 9, max: 15),
    'Macmini7,1': (min: 18, max: 21),
    'MacBook8,1': (min: 15, max: 20),
    'MacBookAir7,1': (min: 15, max: 21),
    'MacBookAir7,2': (min: 15, max: 21),
    'MacBookPro12,1': (min: 16, max: 21),
    'MacBook9,1': (min: 16, max: 21),
    'MacBookPro13,1': (min: 16, max: 21),
    'MacBookPro13,2': (min: 16, max: 21),
    'MacBookPro13,3': (min: 16, max: 21),
    'MacBookPro14,1': (min: 17, max: 22),
    'MacBookPro14,2': (min: 17, max: 22),
    'MacBookPro14,3': (min: 17, max: 22),
    'MacBookPro15,1': (min: 18, max: 24),
    'MacBookPro15,2': (min: 18, max: 24),
    'MacBookPro15,3': (min: 18, max: 24),
    'MacBookPro15,4': (min: 18, max: 24),
    'Macmini8,1': (min: 18, max: 24),
    'MacBookPro16,1': (min: 19, max: 25),
    'MacBookPro16,3': (min: 19, max: 24),
    'MacBookPro16,4': (min: 19, max: 25),
    'MacBookAir9,1': (min: 19, max: 24),
    'MacBookPro16,2': (min: 19, max: 25),
    'MacPro6,1': (min: 13, max: 21),
    'iMacPro1,1': (min: 17, max: 24),
    'MacPro7,1': (min: 19, max: 25),
  };

  static const Map<String, String> _supportDescriptions = {
    'iMac10,1': '支持OS X Snow Leopard 10.6 ~ macOS High Sierra 10.13',
    'iMac11,1': '支持OS X Snow Leopard 10.6 ~ macOS High Sierra 10.13',
    'iMac11,2': '支持OS X Snow Leopard 10.6 ~ macOS High Sierra 10.13',
    'iMac12,2': '支持OS X Snow Leopard 10.6 ~ macOS High Sierra 10.13,适用于核显+独显机型',
    'iMac13,1':
        '支持OS X Mountain Lion 10.8 ~ macOS Catalina 10.15,适用于Ivy Bridge架构,仅核显机型',
    'iMac13,2':
        '支持OS X Mountain Lion 10.8 ~ macOS Catalina 10.15,适用于Ivy Bridge架构,核显解码+独显输出机型',
    'iMac14,2':
        '支持OS X Mavericks 10.9 ~ macOS Big Sur 11,适用于Haswell架构NVIDIA Maxwell 和 Pascal独显',
    'iMac14,4': '支持OS X Mavericks 10.9 ~ macOS Big Sur 11,适用于Haswell架构仅核显机型',
    'iMac15,1': '支持OS X Mavericks 10.9 ~ macOS Big Sur 11,适用于Haswell架构核显+独显机型',
    'iMac16,1': '支持macOS El Capitan 10.11 ~ macOS Monterey 12,适用于核显(或带独显)机型',
    'iMac16,2':
        '支持macOS El Capitan 10.11 ~ macOS Monterey 12,适用于Broadwell架构核显(或带独显)',
    'iMac17,1':
        '支持macOS El Capitan 10.11 ~ macOS Monterey 12,适用于Broadwell架构核显(或带独显)',
    'iMac18,1':
        '支持macOS Sierra 10.12 ~ macOS Ventura 13.适用于核显+独显机型.需要注意的是,使用此机型,多数仅核显用户会出现屏幕颜色不正常.仅核显用户,不推荐此机型',
    'iMac18,3': '支持macOS Sierra 10.12 ~ macOS Ventura 13,适用于核显解码+独显输出机型',
    'iMac19,2': '支持macOS 10.14 ~ macOS Sequoia 15,适用于核显(或带独显)机型',
    'iMac19,1': '支持macOS 10.14 ~ macOS Sequoia 15,适用于核显(或带独显)机型',
    'iMac20,1': '支持macOS 10.15 ~ macOS Tahoe 26,适用于i7-10700K及以下处理器核显(或带独显)机型',
    'iMac20,2': '支持macOS 10.15 ~ macOS Tahoe 26,适用于i9-10850K更高处理器核显(或带独显)机型',
    'MacBookPro5,1': '支持macOS 10.5 ~ macOS El Capitan 10.11',
    'MacBookPro5,2': '支持macOS 10.5 ~ macOS El Capitan 10.11',
    'MacBookPro5,3': '支持macOS 10.5 ~ macOS El Capitan 10.11',
    'MacBookPro5,4': '支持macOS 10.5 ~ macOS El Capitan 10.11',
    'MacBookPro6,1': '支持macOS 10.6 ~ macOS High Sierra 10.13',
    'MacBookPro6,2': '支持macOS 10.6 ~ macOS High Sierra 10.13',
    'MacBookAir4,1': '支持macOS 10.7 ~ macOS High Sierra 10.13',
    'MacBookAir4,2': '支持macOS 10.7 ~ macOS High Sierra 10.13',
    'MacBookPro8,1': '支持macOS 10.7 ~ macOS High Sierra 10.13',
    'MacBookPro8,2': '支持macOS 10.7 ~ macOS High Sierra 10.13',
    'MacBookPro8,3': '支持macOS 10.7 ~ macOS High Sierra 10.13',
    'Macmini5,1': '支持macOS 10.7 ~ macOS High Sierra 10.13',
    'Macmini5,2': '支持macOS 10.7 ~ macOS High Sierra 10.13',
    'Macmini5,3': '支持macOS 10.7 ~ macOS High Sierra 10.13',
    'MacBookAir5,1': '支持macOS 10.8 ~ macOS Catalina 10.15',
    'MacBookAir5,2': '支持macOS 10.8 ~ macOS Catalina 10.15',
    'MacBookPro9,2': '支持macOS 10.8 ~ macOS Catalina 10.15',
    'MacBookPro10,1': '支持macOS 10.8 ~ macOS Catalina 10.15',
    'MacBookPro10,2': '支持macOS 10.8 ~ macOS Catalina 10.15',
    'Macmini6,1': '支持macOS 10.8 ~ macOS Catalina 10.15',
    'Macmini6,2': '支持macOS 10.8 ~ macOS Catalina 10.15',
    'MacBookAir6,1': '支持macOS 10.9 ~ macOS Big Sur 11',
    'MacBookAir6,2': '支持macOS 10.9 ~ macOS Big Sur 11',
    'MacBookPro11,1': '支持macOS 10.9 ~ macOS Big Sur 11',
    'MacBookPro11,2': '支持macOS 10.9 ~ macOS Big Sur 11',
    'MacBookPro11,3': '支持macOS 10.9 ~ macOS Big Sur 11',
    'MacBookPro11,4': '支持macOS High Sierra 10.13 ~ macOS Monterey 12',
    'MacBookPro11,5': '支持macOS High Sierra 10.13 ~ macOS Monterey 12',
    'Macmini3,1': '支持macOS 10.5 ~ macOS El Capitan 10.11',
    'Macmini4,1': '支持macOS 10.5 ~ macOS El Capitan 10.11',
    'Macmini7,1': '支持macOS Mojave 10.14 ~ macOS Monterey 12',
    'MacBook8,1': '支持OS X El Capitan 10.11 ~ macOS Big Sur 11',
    'MacBookAir7,1': '支持OS X El Capitan 10.11 ~ macOS Monterey 12',
    'MacBookAir7,2': '支持OS X El Capitan 10.11 ~ macOS Monterey 12',
    'MacBookPro12,1': '支持macOS Sierra 10.12 ~ macOS Monterey 12',
    'MacBook9,1':
        '支持macOS Sierra 10.12 ~ macOS Monterey 12(核显HD 515官方仅支持macOS Monterey 12,仿冒支持最新macOS Sequoia 15)',
    'MacBookPro13,1':
        '支持macOS Sierra 10.12 ~ macOS Monterey 12(核显Iris 540官方仅支持macOS Monterey 12,仿冒支持最新macOS Sequoia 15)',
    'MacBookPro13,2':
        '支持macOS Sierra 10.12 ~ macOS Monterey 12(核显Iris 550官方仅支持macOS Monterey 12,仿冒支持最新macOS Sequoia 15)',
    'MacBookPro13,3':
        '支持macOS Sierra 10.12 ~ macOS Monterey 12(核显HD530官方仅支持macOS Monterey 12,仿冒支持最新macOS Sequoia 15)',
    'MacBookPro14,1': '支持macOS High Sierra 10.13 ~ macOS Ventura 13',
    'MacBookPro14,2': '支持macOS High Sierra 10.13 ~ macOS Ventura 13',
    'MacBookPro14,3': '支持macOS High Sierra 10.13 ~ macOS Ventura 13',
    'MacBookPro15,1': '支持macOS Mojave 10.14 ~ macOS Sequoia 15',
    'MacBookPro15,2': '支持macOS Mojave 10.14 ~ macOS Sequoia 15',
    'MacBookPro15,3': '支持macOS Mojave 10.14 ~ macOS Sequoia 15',
    'MacBookPro15,4': '支持macOS Mojave 10.14 ~ macOS Sequoia 15',
    'Macmini8,1': '支持macOS Mojave 10.14 ~ macOS Sequoia 15',
    'MacBookPro16,1': '支持macOS Catalina 10.15 ~ macOS Tahoe 26',
    'MacBookPro16,3': '支持macOS Catalina 10.15 ~ macOS Sequoia 15',
    'MacBookPro16,4': '支持macOS Catalina 10.15 ~ macOS Tahoe 26',
    'MacBookAir9,1': '支持macOS Catalina 10.15 ~ macOS Sequoia 15',
    'MacBookPro16,2': '支持macOS Catalina 10.15 ~ macOS Tahoe 26',
    'MacPro6,1': '支持macOS 10.9 ~ macOS Monterey 12,适用于仅独显机型',
    'iMacPro1,1':
        '支持macOS 10.13 ~ macOS Sequoia 15.适用于仅独显机型.对于Intel 11代及以上,通常使用此机型,CPU变频和睿频正常,无需额外Kext补丁(如果macOS系统睿频不正常,请提取使用本机SSDT-PLUG)',
    'MacPro7,1':
        '支持macOS 10.15 ~ macOS Tahoe 26,适用于仅A卡独显机型.支持的免驱A卡(例如RX560,RX570,RX5500,RX6600),会完美支持VDA硬解.对于Intel 11代及以上,通常使用此机型,CPU睿频不正常,需额外Kext补丁.可以去【可选Kexts驱动】->【CPU相关】->[CPU变频驱动,主要提供11代及以上平台 MacPro7,1变频支持]勾选此项.',
  };

  static ({int min, int max})? supportRange(PlatformInfoGeneric smbios) {
    return _supportRanges[smbios.systemProductName];
  }

  static List<PlatformInfoGeneric> supportedByDarwinMajor(
    List<PlatformInfoGeneric> candidates,
    int darwinMajor,
  ) {
    final supported = candidates
        .where((candidate) => supportsDarwinMajor(candidate, darwinMajor))
        .toList();
    return supported.isNotEmpty ? supported : candidates;
  }

  static PlatformInfoGeneric? recommendForDarwinMajor(
    List<PlatformInfoGeneric> candidates,
    int darwinMajor, {
    PlatformInfoGeneric? current,
  }) {
    final supported = supportedByDarwinMajor(candidates, darwinMajor);
    if (supported.isEmpty) return null;

    if (current != null &&
        supported.any(
          (candidate) =>
              candidate.systemProductName == current.systemProductName,
        )) {
      return supported.firstWhere(
        (candidate) => candidate.systemProductName == current.systemProductName,
      );
    }

    return supported.first;
  }

  static int recommendDarwinMajorForSMBIOS(
    PlatformInfoGeneric smbios,
    int currentDarwinMajor,
  ) {
    if (supportsDarwinMajor(smbios, currentDarwinMajor)) {
      return currentDarwinMajor;
    }

    final range = supportRange(smbios);
    if (range != null && currentDarwinMajor > range.max) return range.max;
    if (range != null && currentDarwinMajor < range.min) return range.min;
    return currentDarwinMajor;
  }

  static bool supportsDarwinMajor(
    PlatformInfoGeneric smbios,
    int darwinMajor,
  ) {
    final range = supportRange(smbios);
    if (range == null) return true;
    if (darwinMajor < range.min) return false;
    if (darwinMajor > range.max) return false;
    return true;
  }

  static String supportSummary(PlatformInfoGeneric smbios) {
    final description = _supportDescriptions[smbios.systemProductName];
    if (description != null) {
      return description;
    }

    final range = supportRange(smbios);
    if (range == null) {
      return '未配置macOS兼容范围';
    }

    return '支持${MacOSVersions.labelFromDarwinMajor(range.min)} ~ '
        '${MacOSVersions.labelFromDarwinMajor(range.max)}';
  }
}
