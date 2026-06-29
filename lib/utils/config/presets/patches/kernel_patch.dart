import 'package:rapidefi/extension/string_extension.dart';

import '../../models/kernel/kernel_block_item.dart';
import '../../models/kernel/kernel_force_item.dart';
import '../../models/kernel/kernel_patch_item.dart';

class KernelPatch {
  static KernelBlockItem fixLucy8125Ethernet = KernelBlockItem(
      arch: 'Any',
      comment: 'Fix LucyRTL8125Ethernet',
      enabled: true,
      identifier: 'com.apple.driver.AppleEthernetRL',
      minKernel: '25.0.0',
      maxKernel: '',
      strategy: 'Exclude');

  static KernelBlockItem fixBrcmWiFiForSonoma = KernelBlockItem(
      arch: 'Any',
      comment: 'Fix Brcm&Intel WiFi',
      enabled: true,
      identifier: 'com.apple.iokit.IOSkywalkFamily',
      minKernel: '23.0.0',
      maxKernel: '',
      strategy: 'Exclude');

  static KernelBlockItem fixIntelWiFiForSequoia = KernelBlockItem(
      arch: 'Any',
      comment: 'Fix Brcm&Intel WiFi',
      enabled: true,
      identifier: 'com.apple.iokit.IOSkywalkFamily',
      minKernel: '24.0.0',
      maxKernel: '',
      strategy: 'Exclude');

  static KernelForceItem forceIO80211FamilyToLoad = KernelForceItem(
      arch: 'Any',
      bundlePath: 'System/Library/Extensions/IO80211Family.kext',
      comment: 'Force IO80211Family to load',
      enabled: true,
      executablePath: 'Contents/MacOS/IO80211Family',
      identifier: 'com.apple.iokit.IO80211Family',
      minKernel: '17.0.0',
      maxKernel: '19.99.99',
      plistPath: 'Contents/Info.plist');

  static KernelPatchItem skipDidTerminate = KernelPatchItem(
    arch: 'x86_64',
    base: '__ZN11IOHIDDevice12didTerminateEP9IOServicejPb',
    comment: 'Skip IOHIDDevice didTerminate',
    count: 0,
    enabled: true,
    find: null,
    limit: 0,
    mask: null,
    replace: 'B801000000C3'.toBytes(),
    replaceMask: null,
    identifier: 'com.apple.iokit.IOHIDFamily',
    minKernel: '25.0.0',
    maxKernel: '',
    skip: 0,
  );

  static KernelPatchItem fixRTCWakeScheduling = KernelPatchItem(
    arch: 'Any',
    base: '__ZN8AppleRTC18setupDateTimeAlarmEPK11RTCDateTime',
    comment: 'Disable RTC wake scheduling',
    count: 1,
    enabled: true,
    find: null,
    limit: 0,
    mask: null,
    replace: 'C3'.toBytes(),
    replaceMask: null,
    identifier: 'com.apple.driver.AppleRTC',
    minKernel: '19.0.0',
    maxKernel: '',
    skip: 0,
    note: '禁用 RTC 唤醒计划,修复睡眠后自动唤醒问题',
  );

  static KernelPatchItem fixBroadcomBCM57785 = KernelPatchItem(
    arch: 'x86_64',
    base: '__ZN11BCM5701Enet14getAdapterInfoEv',
    comment: 'Broadcom BCM57785 patch',
    count: 1,
    enabled: true,
    find: 'E8 00 00 FF FF 66 89 83 00 05 00 00'.toBytes(),
    limit: 0,
    mask: 'FF0000FFFFFFFFFFFFFFFFFF'.toBytes(),
    replace: 'B8B416000066898300050000'.toBytes(),
    replaceMask: null,
    identifier: 'com.apple.iokit.AppleBCM5701Ethernet',
    minKernel: '',
    maxKernel: '19.9.9',
    skip: 0,
  );

  static KernelPatchItem xcmpForIvyBridgeCatalinaToBigSur = KernelPatchItem(
    arch: 'x86_64',
    base: '_xcpm_bootstrap',
    comment: 'XCPM for Ivy Bridge. macOS 10.15.x - 11.x by 5T33Z0',
    count: 1,
    enabled: true,
    find: '8D43C43C42'.toBytes(),
    limit: 0,
    mask: ''.toBytes(),
    replace: '8D43C63C42'.toBytes(),
    replaceMask: null,
    identifier: 'kernel',
    minKernel: '19.0.0',
    maxKernel: '20.99.99',
    skip: 0,
  );

  static KernelPatchItem hv_vmm_present_patch = KernelPatchItem(
      arch: 'x86_64',
      base: '',
      comment: 'Reroute kern.hv_vmm_present patch (1)',
      count: 1,
      enabled: true,
      find:
          '006469726563745F68616E646F666600456E61626C65206469726563742068616E646F666620666F72207265616C74696D65207468726561647300'
              .toBytes(),
      identifier: 'kernel',
      limit: 0,
      mask: ''.toBytes(),
      maxKernel: '',
      minKernel: '20.4.0',
      replace:
          '0068765F766D6D5F70726573656E7400456E61626C65206469726563742068616E646F666620666F72207265616C74696D65207468726561647300'
              .toBytes(),
      replaceMask: ''.toBytes(),
      skip: 0);

  static KernelPatchItem hv_vmm_present_patch_legacy = KernelPatchItem(
      arch: 'x86_64',
      base: '',
      comment: 'Reroute kern.hv_vmm_present patch (2) Legacy',
      count: 1,
      enabled: true,
      find: '0068765F64697361626C650068765F766D6D5F70726573656E7400'.toBytes(),
      identifier: 'kernel',
      limit: 0,
      mask: ''.toBytes(),
      maxKernel: '21.99.99',
      minKernel: '20.4.0',
      replace:
          '0068765F64697361626C65006469726563745F68616E646F666600'.toBytes(),
      replaceMask: ''.toBytes(),
      skip: 0);

  static KernelPatchItem hv_vmm_present_patch_ventura_newer = KernelPatchItem(
      arch: 'x86_64',
      base: '',
      comment: 'Reroute kern.hv_vmm_present patch (2) Ventura or Newer',
      count: 1,
      enabled: true,
      find: '626F6F742073657373696F6E20555549440068765F766D6D5F70726573656E7400'
          .toBytes(),
      identifier: 'kernel',
      limit: 0,
      mask: ''.toBytes(),
      maxKernel: '',
      minKernel: '22.0.0',
      replace:
          '626F6F742073657373696F6E2055554944006469726563745F68616E646F666600'
              .toBytes(),
      replaceMask: ''.toBytes(),
      skip: 0);

  static KernelPatchItem disable_Root_Hash_validation = KernelPatchItem(
      arch: 'x86_64',
      base: '_authenticate_root_hash',
      comment: 'Disable Root Hash validation',
      count: 0,
      enabled: true,
      find: ''.toBytes(),
      identifier: 'com.apple.filesystems.apfs',
      limit: 0,
      mask: ''.toBytes(),
      maxKernel: '',
      minKernel: '22.0.0',
      replace: 'B800000000C3'.toBytes(),
      replaceMask: ''.toBytes(),
      skip: 0);

  static KernelPatchItem force_FileVault_on_Broken_Seal = KernelPatchItem(
      arch: 'x86_64',
      base: '_apfs_filevault_allowed',
      comment: 'Force FileVault on Broken Seal',
      count: 0,
      enabled: true,
      find: ''.toBytes(),
      identifier: 'com.apple.filesystems.apfs',
      limit: 0,
      mask: ''.toBytes(),
      maxKernel: '',
      minKernel: '20.4.0',
      replace: 'B801000000C3'.toBytes(),
      replaceMask: ''.toBytes(),
      skip: 0);

  static KernelPatchItem fixLegacyUSBKeyboard = KernelPatchItem(
    arch: 'Any',
    base: '_isSingleUser',
    comment: 'fix legacy USB Keyboard and Mouse',
    count: 1,
    enabled: true,
    find: null,
    limit: 0,
    mask: null,
    replace: 'B801000000C3'.toBytes(),
    replaceMask: null,
    identifier: 'com.apple.iokit.IOHIDFamily',
    minKernel: '20.0.0',
    maxKernel: '',
    skip: 0,
  );

  static KernelPatchItem cpuid_set_info_user_specified1 = KernelPatchItem(
    arch: 'x86_64',
    base: '_cpuid_set_info',
    comment:
        'algrey | Force cpuid_cores_per_package to constant (user-specified) | 10.13-10.14 ',
    count: 1,
    enabled: true,
    find: 'C1E81A000000'.toBytes(),
    limit: 0,
    mask: 'FFFDFF000000'.toBytes(),
    replace: 'B80800000000'.toBytes(),
    replaceMask: 'FFFFFFFFFF00'.toBytes(),
    identifier: 'kernel',
    minKernel: '17.0.0',
    maxKernel: '18.99.99',
    skip: 0,
  );
  static KernelPatchItem cpuid_set_info_user_specified2 = KernelPatchItem(
    arch: 'x86_64',
    base: '_cpuid_set_info',
    comment:
        'algrey | Force cpuid_cores_per_package to constant (user-specified) | 10.15-11.0 ',
    count: 1,
    enabled: true,
    find: 'C1E81A000000'.toBytes(),
    limit: 0,
    mask: 'FFFDFF000000'.toBytes(),
    replace: 'BA0800000000'.toBytes(),
    replaceMask: 'FFFFFFFFFF00'.toBytes(),
    identifier: 'kernel',
    minKernel: '19.0.0',
    maxKernel: '20.99.99',
    skip: 0,
  );

  static KernelPatchItem cpuid_set_info_user_specified3 = KernelPatchItem(
    arch: 'x86_64',
    base: '_cpuid_set_info',
    comment:
        'algrey | Force cpuid_cores_per_package to constant (user-specified) | 12.0-13.2 ',
    count: 1,
    enabled: true,
    find: 'C1E81A000000'.toBytes(),
    limit: 0,
    mask: 'FFFDFF000000'.toBytes(),
    replace: 'BA0800000090'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '21.0.0',
    maxKernel: '22.3.99',
    skip: 0,
  );

  static KernelPatchItem cpuid_set_info_user_specified4 = KernelPatchItem(
    arch: 'x86_64',
    base: '_cpuid_set_info',
    comment:
        'algrey | Force cpuid_cores_per_package to constant (user-specified) | 13.3+ ',
    count: 1,
    enabled: true,
    find: 'C1E81A0000'.toBytes(),
    limit: 0,
    mask: 'FFFDFF0000'.toBytes(),
    replace: 'BA08000000'.toBytes(),
    replaceMask: 'FFFFFFFFFF'.toBytes(),
    identifier: 'kernel',
    minKernel: '22.4.0',
    maxKernel: '25.99.99',
    skip: 0,
  );

  static KernelPatchItem algrey_commpage_populate_Remove_rdmsr =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment: 'algrey | _commpage_populate | Remove rdmsr | 10.13+ ',
    count: 1,
    enabled: true,
    find: 'B9A00100000F32'.toBytes(),
    limit: 0,
    mask: ''.toBytes(),
    replace: '66906690669090'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '17.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );
  static KernelPatchItem algrey_cpuid_set_cache_info_set_cpuid_proper =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment:
        'algrey | _cpuid_set_cache_info | Set CPUID proper instead of 4 | 10.13+ ',
    count: 1,
    enabled: true,
    find: 'B8040000004489F14489'.toBytes(),
    limit: 0,
    mask: ''.toBytes(),
    replace: 'B81D0000804489F14489'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '17.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );
  static KernelPatchItem algrey_cpuid_set_generic_info_remove_wrmsr =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment: 'algrey | _cpuid_set_generic_info | Remove wrmsr(0x8B) | 10.13+ ',
    count: 1,
    enabled: true,
    find: 'B98B00000031C031D20F30'.toBytes(),
    limit: 0,
    mask: ''.toBytes(),
    replace: '6690669066906690669090'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '17.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );
  static KernelPatchItem algrey_cpuid_set_generic_info_replace_rdmsr =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment:
        'algrey | _cpuid_set_generic_info | Replace rdmsr(0x8B) with constant 186 | 10.13+ ',
    count: 1,
    enabled: true,
    find: 'B98B0000000F32'.toBytes(),
    limit: 0,
    mask: ''.toBytes(),
    replace: 'BABA0000006690'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '17.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );
  static KernelPatchItem algrey_cpuid_set_generic_info_set_flag =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment: 'algrey | _cpuid_set_generic_info | Set flag=1 | 10.13+ ',
    count: 1,
    enabled: true,
    find: 'B9170000000F32C1EA1280E207'.toBytes(),
    limit: 0,
    mask: ''.toBytes(),
    replace: 'B201660F1F8400000000006690'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '17.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );

  static KernelPatchItem
      algrey_cpuid_set_generic_disable_check_to_allow_leaf7_10_13 =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment:
        'algrey | _cpuid_set_generic_info | Disable check to allow leaf7 | 10.13+ ',
    count: 1,
    enabled: true,
    find: '003A0F82'.toBytes(),
    limit: 0,
    mask: ''.toBytes(),
    replace: '00000F82'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '17.0.0',
    maxKernel: '23.99.99',
    skip: 0,
  );
  static KernelPatchItem
      algrey_cpuid_set_generic_disable_check_to_allow_leaf7_15 =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment:
        'algrey | _cpuid_set_generic_info | Disable check to allow leaf7 | 15.x ',
    count: 1,
    enabled: true,
    find: '00050F82'.toBytes(),
    limit: 0,
    mask: ''.toBytes(),
    replace: '00000F82'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '24.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );

  static KernelPatchItem algrey_cpuid_set_info_GenuineIntel_to_AuthenticAMD =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment:
        'algrey | _cpuid_set_info | GenuineIntel to AuthenticAMD | 10.13-11.0 ',
    count: 1,
    enabled: true,
    find: '47656E75696E65496E74656C00'.toBytes(),
    limit: 0,
    mask: ''.toBytes(),
    replace: '41757468656E746963414D4400'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '17.0.0',
    maxKernel: '20.99.99',
    skip: 0,
  );

  static KernelPatchItem Goldfish64_algrey_Bypass_GenuineIntel_check_panic =
      KernelPatchItem(
    arch: 'x86_64',
    base: '_cpuid_set_info',
    comment: 'Goldfish64, algrey | Bypass GenuineIntel check panic | 12.0+ ',
    count: 1,
    enabled: true,
    find: '00000000000031D2B301'.toBytes(),
    limit: 0,
    mask: '000000000000FFFFFFFF'.toBytes(),
    replace: '90909090909031D2B301'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '21.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );

  static KernelPatchItem
      algrey_cpuid_set_cpufamily_Force_CPUFAMILY_INTEL_PENRYN_11_2 =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment:
        'algrey | _cpuid_set_cpufamily | Force CPUFAMILY_INTEL_PENRYN | 10.13-11.2 ',
    count: 1,
    enabled: true,
    find: '31DB803D00000000067500'.toBytes(),
    limit: 0,
    mask: 'FFFFFFFF000000FFFFFF00'.toBytes(),
    replace: 'BBBC4FEA78E95D00000090'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '17.0.0',
    maxKernel: '20.3.0',
    skip: 0,
  );
  static KernelPatchItem
      algrey_cpuid_set_cpufamily_Force_CPUFAMILY_INTEL_PENRYN_11_3 =
      KernelPatchItem(
    arch: 'x86_64',
    base: '_cpuid_set_info',
    comment:
        'algrey | _cpuid_set_cpufamily | Force CPUFAMILY_INTEL_PENRYN | 11.3+ ',
    count: 1,
    enabled: true,
    find: '803D000000000675'.toBytes(),
    limit: 0,
    mask: 'FFFF00000000FFFF'.toBytes(),
    replace: 'BABC4FEA7831DBEB'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '20.4.0',
    maxKernel: '25.99.99',
    skip: 0,
  );

  static KernelPatchItem algrey_i386_init_Remove_3_rdmsr_calls =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment: 'algrey | _i386_init | Remove 3 rdmsr calls | 10.13+ ',
    count: 0,
    enabled: true,
    find:
        'B9990100000F3248C1E22089C64809D6B9980100000F3248C1E22089C04809C2BF5802310531C94531C0'
            .toBytes(),
    limit: 0,
    mask: ''.toBytes(),
    replace:
        '660F1F840000000000660F1F840000000000660F1F840000000000660F1F840000000000660F1F440000'
            .toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '17.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );
  static KernelPatchItem algrey_XLNC_Remove_version_check_and_panic =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment: 'algrey, XLNC | Remove version check and panic | 10.13+ ',
    count: 1,
    enabled: true,
    find: '25FC00000083F813'.toBytes(),
    limit: 0,
    mask: ''.toBytes(),
    replace: '25FC0000000F1F00'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '17.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );

  static KernelPatchItem
      CaseySJ_probeBusGated_Disable_10_bit_tags_sequoia_below = KernelPatchItem(
    arch: 'x86_64',
    base: '__ZN11IOPCIBridge13probeBusGatedEP14probeBusParams',
    comment: 'CaseySJ | probeBusGated | Disable 10 bit tags | 12.0-15.x',
    count: 1,
    enabled: true,
    find: 'E0117200'.toBytes(),
    limit: 0,
    mask: 'F0FFFFF0'.toBytes(),
    replace: '00000300'.toBytes(),
    replaceMask: '00000F00'.toBytes(),
    identifier: 'com.apple.iokit.IOPCIFamily',
    minKernel: '21.0.0',
    maxKernel: '24.99.99',
    skip: 0,
  );

  static KernelPatchItem CaseySJ_probeBusGated_Disable_10_bit_tags_tahoe =
      KernelPatchItem(
    arch: 'x86_64',
    base: '__ZN11IOPCIBridge13probeBusGatedEP14probeBusParams',
    comment: 'CaseySJ | probeBusGated | Disable 10 bit tags | 26.0+',
    count: 1,
    enabled: true,
    find: 'E0117340'.toBytes(),
    limit: 0,
    mask: 'F0FFFFF0'.toBytes(),
    replace: '00000200'.toBytes(),
    replaceMask: '00000F00'.toBytes(),
    identifier: 'com.apple.iokit.IOPCIFamily',
    minKernel: '25.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );

  static KernelPatchItem
      CaseySJ_IOPCIIsHotplugPort_Fix_PCI_bus_enumeration_on_AM5 =
      KernelPatchItem(
    arch: 'x86_64',
    base: '__ZN17IOPCIConfigurator18IOPCIIsHotplugPortEP16IOPCIConfigEntry',
    comment:
        'CaseySJ | IOPCIIsHotplugPort | Fix PCI bus enumeration on AM5 | 13.0+ ',
    count: 1,
    enabled: false,
    find: '8400754B'.toBytes(),
    limit: 0,
    mask: 'FF00FFFF'.toBytes(),
    replace: '0000EB00'.toBytes(),
    replaceMask: '0000FF00'.toBytes(),
    identifier: 'com.apple.iokit.IOPCIFamily',
    minKernel: '22.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );

  static KernelPatchItem
      Visual_thread_quantum_expire_thread_unblock_thread_invoke =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment:
        'Visual | thread_quantum_expire, thread_unblock, thread_invoke | Remove non-monotonic time panic | 12.0+ ',
    count: 3,
    enabled: true,
    find: '48000000020000480000580000000F0000000000'.toBytes(),
    limit: 0,
    mask: 'FF00000FFFFFFFFF0000FF000000FF0000000000'.toBytes(),
    replace: '0000000000000000000000000000669066906690'.toBytes(),
    replaceMask: '0000000000000000000000000000FFFFFFFFFFFF'.toBytes(),
    identifier: 'kernel',
    minKernel: '21.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );

  static KernelPatchItem Visual_thread_invoke_thread_dispatch = KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment:
        'Visual | thread_invoke, thread_dispatch | Remove non-monotonic time panic | 12.0+ ',
    count: 2,
    enabled: true,
    find: '480000800400000F0000000000'.toBytes(),
    limit: 0,
    mask: '480000F0FFFFFFFF0000000000'.toBytes(),
    replace: '00000000000000669066906690'.toBytes(),
    replaceMask: '00000000000000FFFFFFFFFFFF'.toBytes(),
    identifier: 'kernel',
    minKernel: '21.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );

  static KernelPatchItem algrey_mtrr_update_action_fix_PAT = KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment: 'algrey | _mtrr_update_action | fix PAT | 10.13+ ',
    count: 0,
    enabled: true,
    find: '89C081E2FFFF00FF81CA00000100B977020000'.toBytes(),
    limit: 0,
    mask: 'FFFFFFFFFFFF0FFFFFFFFFFFFFFFFFFFFFFFFF'.toBytes(),
    replace: 'B977020000B806010700BA060107000F1F4000'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '17.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );
  static KernelPatchItem Shaneee_mtrr_update_action_fix_PAT = KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment: 'Shaneee | _mtrr_update_action | Fix PAT | 10.13+ ',
    count: 0,
    enabled: false,
    find: '89C081E2FFFF00FF81CA00000100B977020000'.toBytes(),
    limit: 0,
    mask: 'FFFFFFFFFFFF0FFFFFFFFFFFFFFFFFFFFFFFFF'.toBytes(),
    replace: 'B977020000B806060606BA060606060F300F09'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '17.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );
  static KernelPatchItem Algrey_Zormeister_mtrr_update_action_fix_PAT =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment: 'Algrey / Zormeister | _mtrr_update_action | Fix PAT | 15+ ',
    count: 0,
    enabled: true,
    find: '89C081E2FFFF00FF81CA000000000F30'.toBytes(),
    limit: 0,
    mask: 'FFFFFFFFFFFFFFFFFFFF00000000FFFF'.toBytes(),
    replace: '89C0B806010700BA060107000F309090'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '24.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );

  static KernelPatchItem Shaneee_Zormeister_mtrr_update_action_fix_PAT =
      KernelPatchItem(
    arch: 'x86_64',
    base: '',
    comment: 'Shaneee / Zormeister | _mtrr_update_action | Fix PAT | 15+ ',
    count: 0,
    enabled: false,
    find: '89C081E2FFFF00FF81CA000000000F30'.toBytes(),
    limit: 0,
    mask: 'FFFFFFFFFFFFFFFFFFFF00000000FFFF'.toBytes(),
    replace: '89C0B806060606BA060606060F309090'.toBytes(),
    replaceMask: ''.toBytes(),
    identifier: 'kernel',
    minKernel: '24.0.0',
    maxKernel: '25.99.99',
    skip: 0,
  );
  static List<KernelPatchItem> amd_ryzen_kernel_patches = [
    cpuid_set_info_user_specified1,
    cpuid_set_info_user_specified2,
    cpuid_set_info_user_specified3,
    cpuid_set_info_user_specified4,
    algrey_commpage_populate_Remove_rdmsr,
    algrey_cpuid_set_cache_info_set_cpuid_proper,
    algrey_cpuid_set_generic_info_remove_wrmsr,
    algrey_cpuid_set_generic_info_replace_rdmsr,
    algrey_cpuid_set_generic_info_set_flag,
    algrey_cpuid_set_generic_disable_check_to_allow_leaf7_10_13,
    algrey_cpuid_set_generic_disable_check_to_allow_leaf7_15,
    algrey_cpuid_set_info_GenuineIntel_to_AuthenticAMD,
    Goldfish64_algrey_Bypass_GenuineIntel_check_panic,
    algrey_cpuid_set_cpufamily_Force_CPUFAMILY_INTEL_PENRYN_11_2,
    algrey_cpuid_set_cpufamily_Force_CPUFAMILY_INTEL_PENRYN_11_3,
    algrey_i386_init_Remove_3_rdmsr_calls,
    algrey_XLNC_Remove_version_check_and_panic,
    CaseySJ_probeBusGated_Disable_10_bit_tags_sequoia_below,
    CaseySJ_probeBusGated_Disable_10_bit_tags_tahoe,
    CaseySJ_IOPCIIsHotplugPort_Fix_PCI_bus_enumeration_on_AM5,
    Visual_thread_quantum_expire_thread_unblock_thread_invoke,
    Visual_thread_invoke_thread_dispatch,
    algrey_mtrr_update_action_fix_PAT,
    Shaneee_mtrr_update_action_fix_PAT,
    Algrey_Zormeister_mtrr_update_action_fix_PAT,
    Shaneee_Zormeister_mtrr_update_action_fix_PAT,
  ];
}
