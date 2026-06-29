import '../../models/booter/booter_quirk_type.dart';
import '../../models/booter/booter_quirks.dart';

class ConfigBooter {
  /// 775 - 0代
  static BooterQuirks booterQuirks_intel_desktop_0th = BooterQuirks(
      avoidRuntimeDefrag: true,
      enableSafeModeSlide: true,
      provideCustomSlide: true,
      setupVirtualMap: true);

  /// 1156 - 1代
  static BooterQuirks booterQuirks_intel_desktop_1th =
      booterQuirks_intel_desktop_0th.copyWith();

  /// 1155 - 2代
  static BooterQuirks booterQuirks_intel_desktop_2th =
      booterQuirks_intel_desktop_1th.copyWith(
    enableWriteUnprotector: true,
  );

  /// 1155 - 3代
  static BooterQuirks booterQuirks_intel_desktop_3th =
      booterQuirks_intel_desktop_2th.copyWith();

  /// 1150 - 4代
  static BooterQuirks booterQuirks_intel_desktop_4th =
      booterQuirks_intel_desktop_3th.copyWith();

  /// 1150 - 5代
  static BooterQuirks booterQuirks_intel_desktop_5th =
      booterQuirks_intel_desktop_4th.copyWith();

  /// 1151 - 6代
  static BooterQuirks booterQuirks_intel_desktop_6th =
      booterQuirks_intel_desktop_4th.copyWith();

  /// 1151 - 7代
  static BooterQuirks booterQuirks_intel_desktop_7th =
      booterQuirks_intel_desktop_4th.copyWith();

  /// 1151 - 8代
  static BooterQuirks booterQuirks_intel_desktop_8th =
      booterQuirks_intel_desktop_7th.copyWith();

  /// 1151 - 9代
  static BooterQuirks booterQuirks_intel_desktop_9th = BooterQuirks(
    avoidRuntimeDefrag: true,
    devirtualiseMmio: true,
    enableSafeModeSlide: true,
    provideCustomSlide: true,
    setupVirtualMap: true,
    rebuildAppleMemoryMap: true,
    syncRuntimePermissions: true,
  );

  /// 1200 - 10代
  static BooterQuirks booterQuirks_intel_desktop_10th = BooterQuirks(
    avoidRuntimeDefrag: true,
    devirtualiseMmio: true,
    enableSafeModeSlide: true,
    provideCustomSlide: true,
    setupVirtualMap: true,
    rebuildAppleMemoryMap: true,
    syncRuntimePermissions: true,
  );

  /// 1200 - 11代
  static BooterQuirks booterQuirks_intel_desktop_11th = BooterQuirks(
    avoidRuntimeDefrag: true,
    devirtualiseMmio: true,
    enableSafeModeSlide: true,
    provideCustomSlide: true,
    protectUefiServices: true,
    setupVirtualMap: true,
    rebuildAppleMemoryMap: true,
    syncRuntimePermissions: true,
  );

  /// 1700 - 12代
  static BooterQuirks booterQuirks_intel_desktop_12th =
      booterQuirks_intel_desktop_11th;

  /// 1700 - 13代
  static BooterQuirks booterQuirks_intel_desktop_13th =
      booterQuirks_intel_desktop_11th;

  /// 1700 - 14代
  static BooterQuirks booterQuirks_intel_desktop_14th =
      booterQuirks_intel_desktop_11th;

  ///0代
  static BooterQuirks booterQuirks_laptop_0th = BooterQuirks(
    avoidRuntimeDefrag: true,
    enableSafeModeSlide: true,
    provideCustomSlide: true,
    setupVirtualMap: true,
    rebuildAppleMemoryMap: true,
  );

  static BooterQuirks booterQuirks_laptop_1th =
      booterQuirks_laptop_0th.copyWith();
  static BooterQuirks booterQuirks_laptop_2th = BooterQuirks(
    avoidRuntimeDefrag: true,
    enableSafeModeSlide: true,
    enableWriteUnprotector: true,
    provideCustomSlide: true,
    setupVirtualMap: true,
  );
  static BooterQuirks booterQuirks_laptop_3th =
      booterQuirks_laptop_2th.copyWith();
  static BooterQuirks booterQuirks_laptop_4th =
      booterQuirks_laptop_2th.copyWith();
  static BooterQuirks booterQuirks_laptop_5th =
      booterQuirks_laptop_2th.copyWith();
  static BooterQuirks booterQuirks_laptop_6th =
      booterQuirks_laptop_2th.copyWith();
  static BooterQuirks booterQuirks_laptop_7th =
      booterQuirks_laptop_2th.copyWith();
  static BooterQuirks booterQuirks_laptop_8th =
      booterQuirks_laptop_7th.copyWith();
  static BooterQuirks booterQuirks_laptop_9th = BooterQuirks(
      avoidRuntimeDefrag: true,
      enableSafeModeSlide: true,
      provideCustomSlide: true,
      setupVirtualMap: true,
      rebuildAppleMemoryMap: true,
      syncRuntimePermissions: true);
  static BooterQuirks booterQuirks_laptop_10th_cometLake = BooterQuirks(
      avoidRuntimeDefrag: true,
      devirtualiseMmio: true,
      enableSafeModeSlide: true,
      protectUefiServices: true,
      provideCustomSlide: true,
      rebuildAppleMemoryMap: true,
      syncRuntimePermissions: true);
  static BooterQuirks booterQuirks_laptop_10th_IceLake = BooterQuirks(
      avoidRuntimeDefrag: true,
      devirtualiseMmio: true,
      enableSafeModeSlide: true,
      protectUefiServices: true,
      provideCustomSlide: true,
      rebuildAppleMemoryMap: true,
      syncRuntimePermissions: true);

  static BooterQuirks booterQuirks_laptop_11th_TigerLake = BooterQuirks(
      avoidRuntimeDefrag: true,
      devirtualiseMmio: true,
      enableSafeModeSlide: true,
      protectUefiServices: true,
      protectMemoryRegions: true,
      provideCustomSlide: true,
      rebuildAppleMemoryMap: true,
      syncRuntimePermissions: true);

  ///0代
  static BooterQuirks booterQuirks_nuc_0th = BooterQuirks(
    avoidRuntimeDefrag: true,
    enableSafeModeSlide: true,
    provideCustomSlide: true,
    setupVirtualMap: true,
  );

  ///1代
  static BooterQuirks booterQuirks_nuc_1th = BooterQuirks(
    avoidRuntimeDefrag: true,
    enableSafeModeSlide: true,
    provideCustomSlide: true,
    setupVirtualMap: true,
  );

  ///2代
  static BooterQuirks booterQuirks_nuc_2th = BooterQuirks(
    avoidRuntimeDefrag: true,
    enableSafeModeSlide: true,
    enableWriteUnprotector: true,
    provideCustomSlide: true,
    setupVirtualMap: true,
  );
  static BooterQuirks booterQuirks_nuc_3th = booterQuirks_nuc_2th.copyWith();
  static BooterQuirks booterQuirks_nuc_4th = booterQuirks_nuc_2th.copyWith();
  static BooterQuirks booterQuirks_nuc_5th = booterQuirks_nuc_2th.copyWith();
  static BooterQuirks booterQuirks_nuc_6th = booterQuirks_nuc_2th.copyWith();
  static BooterQuirks booterQuirks_nuc_7th = booterQuirks_nuc_2th.copyWith();
  static BooterQuirks booterQuirks_nuc_8th = booterQuirks_nuc_7th.copyWith();
  static BooterQuirks booterQuirks_nuc_9th = BooterQuirks(
      avoidRuntimeDefrag: true,
      enableSafeModeSlide: true,
      provideCustomSlide: true,
      setupVirtualMap: true,
      rebuildAppleMemoryMap: true,
      syncRuntimePermissions: true);
  static BooterQuirks booterQuirks_nuc_10th_cometLake = BooterQuirks(
      avoidRuntimeDefrag: true,
      devirtualiseMmio: true,
      enableSafeModeSlide: true,
      protectUefiServices: true,
      provideCustomSlide: true,
      rebuildAppleMemoryMap: true,
      syncRuntimePermissions: true);
  static BooterQuirks booterQuirks_nuc_10th_IceLake = BooterQuirks(
      avoidRuntimeDefrag: true,
      devirtualiseMmio: true,
      enableSafeModeSlide: true,
      protectUefiServices: true,
      provideCustomSlide: true,
      rebuildAppleMemoryMap: true,
      syncRuntimePermissions: true);

  static BooterQuirks booterQuirks_nuc_11th_TigerLake = BooterQuirks(
      avoidRuntimeDefrag: true,
      devirtualiseMmio: true,
      enableSafeModeSlide: true,
      protectUefiServices: true,
      protectMemoryRegions: true,
      provideCustomSlide: true,
      rebuildAppleMemoryMap: true,
      syncRuntimePermissions: true);

  static BooterQuirks booterQuirks_hedt_1th = BooterQuirks(
    avoidRuntimeDefrag: true,
    enableSafeModeSlide: true,
    enableWriteUnprotector: true,
    provideCustomSlide: true,
    setupVirtualMap: true,
  );

  static BooterQuirks booterQuirks_hedt_2th = booterQuirks_hedt_1th.copyWith();
  static BooterQuirks booterQuirks_hedt_3th = booterQuirks_hedt_1th.copyWith();
  static BooterQuirks booterQuirks_hedt_4th = booterQuirks_hedt_3th.copyWith();
  static BooterQuirks booterQuirks_hedt_5th = booterQuirks_hedt_3th.copyWith();
  static BooterQuirks booterQuirks_hedt_6th = BooterQuirks(
      avoidRuntimeDefrag: true,
      devirtualiseMmio: true,
      enableSafeModeSlide: true,
      provideCustomSlide: true,
      setupVirtualMap: true,
      rebuildAppleMemoryMap: true,
      syncRuntimePermissions: true);
  static BooterQuirks booterQuirks_hedt_10th = booterQuirks_hedt_6th.copyWith();

  static BooterQuirks booterQuirks_amd_desktop_legacy = BooterQuirks(
      avoidRuntimeDefrag: true,
      enableSafeModeSlide: true,
      enableWriteUnprotector: true,
      provideCustomSlide: true,
      setupVirtualMap: true);

  static BooterQuirks booterQuirks_amd_desktop_ryzen = BooterQuirks(
      avoidRuntimeDefrag: true,
      enableSafeModeSlide: true,
      provideCustomSlide: true,
      setupVirtualMap: true,
      rebuildAppleMemoryMap: true,
      syncRuntimePermissions: true);

  static BooterQuirks booterQuirks_amd_laptop_legacy = BooterQuirks(
      avoidRuntimeDefrag: true,
      enableSafeModeSlide: true,
      enableWriteUnprotector: true,
      provideCustomSlide: true,
      setupVirtualMap: true);

  static BooterQuirks booterQuirks_amd_laptop_ryzen = BooterQuirks(
      avoidRuntimeDefrag: true,
      enableSafeModeSlide: true,
      provideCustomSlide: true,
      setupVirtualMap: true,
      rebuildAppleMemoryMap: true,
      syncRuntimePermissions: true);

  static BooterQuirks booterQuirks_amd_nuc_legacy = BooterQuirks(
      avoidRuntimeDefrag: true,
      enableSafeModeSlide: true,
      provideCustomSlide: true,
      enableWriteUnprotector: true,
      setupVirtualMap: true);

  static BooterQuirks booterQuirks_amd_nuc_ryzen = BooterQuirks(
      avoidRuntimeDefrag: true,
      enableSafeModeSlide: true,
      provideCustomSlide: true,
      setupVirtualMap: true,
      rebuildAppleMemoryMap: true,
      syncRuntimePermissions: true);

  static BooterQuirks booterQuirks_amd_hedt_ryzen = BooterQuirks(
      avoidRuntimeDefrag: true,
      enableSafeModeSlide: true,
      provideCustomSlide: true,
      setupVirtualMap: true);

  static List<BooterQuirkType> booterQuirkTypes = [
    const BooterQuirkType(
        name: 'DevirtualiseMmio',
        comment:
            'DevirtualiseMmio(一些主板和固件在处理MMIO区域时可能会出现冲突或不兼容的问题。启用该选项可以帮助解决这些冲突,提高系统的兼容性和稳定性.此选项通常结合OpenCore Debug版本来定制MMIO,以解决部分主板(例如:部分X58,X79,X99,以及AMD 7000系列处理器主板)因内存问题导致的卡EB)'),
    const BooterQuirkType(
        name: 'EnableWriteUnprotector',
        comment:
            'EnableWriteUnprotector(不支持内存属性表（MAT）的固件上，特别是OEM固件上建议勾选.开启后会在执行期间删除CR0寄存器中的写入保护,保证NVRAM正常写入.通常适用于7代以前平台)'),
    const BooterQuirkType(
        name: 'ProtectUefiServices',
        comment:
            'ProtectUefiServices(保护UEFI服务不被固件覆盖,通常用于修复DevirtualiseMmio等导致卡EB问题。Z390,Z490主板,以及10代IceLake建议勾选)'),
    const BooterQuirkType(
        name: 'SetupVirtualMap',
        comment:
            'SetupVirtualMap(建立连续性虚拟内存供OC使用，并映射到分散的物理内存中.注意:10代Comet Lake 华硕(ASUS),技嘉(Gigabyte),华擎(AsRock)主板不建议勾选.'),
    const BooterQuirkType(
        name: 'RebuildAppleMemoryMap',
        comment:
            'RebuildAppleMemoryMap(支持内存属性表（MAT）的固件上,建议勾选.通常与SyncRuntimePermissions搭配使用。此项与EnableWriteUnprotector可能存在冲突,建议两者二选一。通常适用于8代以后平台,部分老平台也适用)'),
    const BooterQuirkType(
        name: 'SyncRuntimePermissions',
        comment:
            'SyncRuntimePermissions(修正硬件在注入内存时无法注入权限的问题。一般此类问题存在2018年后的主板。如果你因为此选项无法进入Windows,请开启它。此项通常与RebuildAppleMemoryMap搭配使用)')
  ];
}
