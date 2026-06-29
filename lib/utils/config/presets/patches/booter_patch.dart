import 'package:rapidefi/extension/string_extension.dart';
import 'package:rapidefi/utils/config/models/booter/booter_patch_item.dart';

import '../../models/booter/booter_mmio_item.dart';

class BooterPatch {
  static final BooterPatchItem skipBoardIDCheck = BooterPatchItem(
      identifier: 'Apple',
      comment: 'Skip Board ID Check',
      count: 0,
      enabled: true,
      find:
          '0050006C006100740066006F0072006D0053007500700070006F00720074002E0070006C006900730074'
              .toBytes(),
      limit: 0,
      mask: null,
      replace:
          '002E002E002E002E002E002E002E002E002E002E002E002E002E002E002E002E002E002E002E002E002E'
              .toBytes(),
      replaceMask: null,
      skip: 0,
      arch: 'x86_64');

  static final BooterMmioWhitelistItem mmioWhitelistItem1 =
      BooterMmioWhitelistItem(
          address: 4244635648,
          comment: 'MMIO devirt 0xFD000000 (0x1E00 pages, 0x800000000000100D)',
          enabled: true);
  static final BooterMmioWhitelistItem mmioWhitelistItem2 =
      BooterMmioWhitelistItem(
          address: 4276092928,
          comment: 'MMIO devirt 0xFEE00000 (0x1 pages, 0x8000000000000001)',
          enabled: true);
  static final BooterMmioWhitelistItem mmioWhitelistItem3 =
      BooterMmioWhitelistItem(
          address: 4276097024,
          comment: 'MMIO devirt 0xFEE01000 (0x11FF pages, 0x800000000000100D)',
          enabled: true);
}
