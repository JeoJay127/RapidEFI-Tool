import 'package:rapidefi/utils/config/models/uefi/uefi_memory_item.dart';

class UefiMemoryPatch {
  static final UefiMemoryItem fixHD3000IGPUmemory = UefiMemoryItem(
      address: 268435456,
      comment: 'fixHD3000IGPUmemory',
      enabled: true,
      size: 268435456,
      type: 'Reserved');
  static final UefiMemoryItem fixBlackScreenForLenovoT490 = UefiMemoryItem(
      address: 569344,
      comment:
          'Fix black screen on wake from hibernation for Lenovo Thinkpad T490----',
      enabled: true,
      size: 4096,
      type: 'RuntimeCode');
}
