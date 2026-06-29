import 'package:rapidefi/extension/string_extension.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_delete_item.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_patch_item.dart';

class AcpiPatch {
  static List<AcpiPatchItem> patchChoicesList = [
    AcpiPatch.rtcFixHPPostError,
    AcpiPatch.surfacePatch,
  ];

  /// Surface 系列(Surface Pro 7 和 Book 3) ACPI补丁,修复“系统偏好设置”中电池识别问题
  static final AcpiPatchItem surfacePatch = AcpiPatchItem(
    base: '',
    baseSkip: 0,
    comment: 'fix Surface battery identification issue',
    count: 0,
    enabled: true,
    find: '00080900B2000000F0F1'.toBytes(),
    limit: 0,
    mask: null,
    oemTableId: null,
    replace: '00020900B2000000F0F1'.toBytes(),
    replaceMask: null,
    skip: 0,
    tableLength: 0,
    tableSignature: '46414350'.toBytes(),
    note: '修复Surface Pro 7 和 Book 3系列,“系统偏好设置”中电池识别问题',
  );

   /// HP 系列: RTC fix to prevent POST errors
  static final AcpiPatchItem rtcFixHPPostError = AcpiPatchItem(
    base: '',
    baseSkip: 0,
    comment: 'RTC fix to prevent POST errors',
    count: 0,
    enabled: true,
    find: '4701700070000108'.toBytes(),
    limit: 0,
    mask: null,
    oemTableId: null,
    replace: '4701700070000102'.toBytes(),
    replaceMask: null,
    skip: 0,
    tableLength: 0,
    tableSignature: '44534454'.toBytes(),
    note: '修复部分惠普品牌电脑实时时钟,启动时出现POST错误问题',
  );

  static final AcpiPatchItem osiToXOSI = AcpiPatchItem(
      base: '',
      baseSkip: 0,
      comment: '_OSI to XOSI rename - requires SSDT-XOSI.aml',
      count: 0,
      enabled: true,
      find: '5F4F5349'.toBytes(),
      limit: 0,
      mask: null,
      oemTableId: null,
      replace: '584f5349'.toBytes(),
      replaceMask: null,
      skip: 0,
      tableLength: 0,
      tableSignature: null);

  static final AcpiDeleteItem deleteCpuPm = AcpiDeleteItem(
      all: true,
      comment: 'Delete CpuPm',
      enabled: true,
      oemTableId: '437075506D000000'.toBytes(),
      tableLength: 0,
      tableSignature: '53534454'.toBytes());
  static final AcpiDeleteItem deleteCpu0Ist = AcpiDeleteItem(
      all: true,
      comment: 'Delete Cpu0Ist',
      enabled: true,
      oemTableId: '4370753049737400'.toBytes(),
      tableLength: 0,
      tableSignature: '53534454'.toBytes());

  static final AcpiPatchItem fixHPET = AcpiPatchItem(
    base: '\\_SB.PCI0.LPCB.HPET',
    baseSkip: 0,
    comment: 'HPET _CRS to XCRS',
    count: 1,
    enabled: true,
    find: '5F435253'.toBytes(),
    limit: 0,
    replace: '58435253'.toBytes(),
    skip: 0,
    tableLength: 0,
  );

  static final AcpiPatchItem rename_GPRW_To_XPRW = AcpiPatchItem(
    base: '',
    baseSkip: 0,
    comment: 'GPRW to XPRW rename - required SSDT-GPRW.aml',
    count: 0,
    enabled: true,
    find: '4750525702'.toBytes(),
    limit: 0,
    replace: '5850525702'.toBytes(),
    skip: 0,
    tableLength: 0,
  );

  static final AcpiPatchItem rename_UPRW_To_XPRW = AcpiPatchItem(
    base: '',
    baseSkip: 0,
    comment: 'UPRW to XPRW rename - required SSDT-UPRW.aml',
    count: 0,
    enabled: true,
    find: '5550525702'.toBytes(),
    limit: 0,
    replace: '5850525702'.toBytes(),
    skip: 0,
    tableLength: 0,
  );

  static final AcpiPatchItem ACPI_PCHA_Z890 = AcpiPatchItem(
    base: '',
    baseSkip: 0,
    comment: 'ACPI Patch(PCHA) for Z890/200 Series - vit9696',
    count: 1,
    enabled: true,
    find: 'A000000092935043484100'.toBytes(),
    limit: 0,
    mask: 'FF000000FFFFFFFFFFFFFF'.toBytes(),
    replace: 'A3A3A3A3A3A3A3A3A3A3A3'.toBytes(),
    skip: 0,
    tableLength: 0,
    tableSignature: '44534454'.toBytes(),
  );

  static final AcpiPatchItem ACPI_PWGS_Z890 = AcpiPatchItem(
    base: '',
    baseSkip: 0,
    comment: 'ACPI Patch(PWGS) for Z890/200 Series - vit9696',
    count: 1,
    enabled: true,
    find: 'A000000092935057475300'.toBytes(),
    limit: 0,
    mask: 'FF000000FFFFFFFFFFFFFF'.toBytes(),
    replace: 'A3A3A3A3A3A3A3A3A3A3A3'.toBytes(),
    skip: 0,
    tableLength: 0,
    tableSignature: '44534454'.toBytes(),
  );

  static final AcpiPatchItem ACPI_PWVA_Z890 = AcpiPatchItem(
    base: '',
    baseSkip: 0,
    comment: 'ACPI Patch(PWVA) for Z890/200 Series - vit9696',
    count: 1,
    enabled: true,
    find: 'A000000008935057564100'.toBytes(),
    limit: 0,
    mask: 'FF000000FFFFFFFFFFFFFF'.toBytes(),
    replace: 'A3A3A3A3A3A3A3A3A3A3A3'.toBytes(),
    skip: 0,
    tableLength: 0,
    tableSignature: '44534454'.toBytes(),
  );
}
