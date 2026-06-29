import '../../models/uefi/uefi_apfs.dart';
import '../../models/uefi/uefi_drivers_item.dart';

class ConfigUefi {
  static UefiApfs commonUefiApfs = UefiApfs(
    minDate: -1,
    minVersion: -1,
  );
  static UefiDriversItem HfsPlusLegacy =
      UefiDriversItem(path: 'HfsPlusLegacy.efi', enabled: true);
  static UefiDriversItem HfsPlus =
      UefiDriversItem(path: 'HfsPlus.efi', enabled: true);
  static UefiDriversItem OpenRuntime =
      UefiDriversItem(path: 'OpenRuntime.efi', enabled: true);
  static UefiDriversItem OpenCanopy =
      UefiDriversItem(path: 'OpenCanopy.efi', enabled: true);
  static UefiDriversItem ResetNvramEntry =
      UefiDriversItem(path: 'ResetNvramEntry.efi', enabled: true);
  static UefiDriversItem OpenUsbKbDxe =
      UefiDriversItem(path: 'OpenUsbKbDxe.efi', enabled: true);
  static UefiDriversItem Ps2KeyboardDxe =
      UefiDriversItem(path: 'Ps2KeyboardDxe.efi', enabled: true);

  static List<UefiDriversItem> commonDesktopLegacyDriversItems = [
    HfsPlusLegacy,
    OpenRuntime,
    OpenCanopy,
    OpenUsbKbDxe,
    ResetNvramEntry
  ];
  static List<UefiDriversItem> commonDesktopLegacyUefiDriversItems = [
    HfsPlusLegacy,
    OpenRuntime,
    OpenCanopy,
    ResetNvramEntry
  ];
  static List<UefiDriversItem> commonDesktopUefiDriversItems = [
    HfsPlus,
    OpenRuntime,
    OpenCanopy,
    ResetNvramEntry
  ];

  static List<UefiDriversItem> commonLaptopLegacyDriversItems = [
    HfsPlusLegacy,
    OpenRuntime,
    OpenCanopy,
    Ps2KeyboardDxe,
    ResetNvramEntry,
  ];
  static List<UefiDriversItem> commonLaptopLegacyUefiDriversItems = [
    HfsPlusLegacy,
    OpenRuntime,
    OpenCanopy,
    ResetNvramEntry,
  ];
  static List<UefiDriversItem> commonLaptopUefiDriversItems = [
    HfsPlus,
    OpenRuntime,
    OpenCanopy,
    ResetNvramEntry,
  ];

  static List<UefiDriversItem> commonNucLegacyDriversItems = [
    HfsPlusLegacy,
    OpenRuntime,
    OpenCanopy,
    OpenUsbKbDxe,
    ResetNvramEntry
  ];
  static List<UefiDriversItem> commonNucLegacyUefiDriversItems = [
    HfsPlusLegacy,
    OpenRuntime,
    OpenCanopy,
    ResetNvramEntry,
  ];
  static List<UefiDriversItem> commonNucUefiDriversItems = [
    HfsPlus,
    OpenRuntime,
    OpenCanopy,
    ResetNvramEntry,
  ];

  static List<UefiDriversItem> commonHedtLegacyDriversItems = [
    HfsPlusLegacy,
    OpenRuntime,
    OpenCanopy,
    OpenUsbKbDxe,
    ResetNvramEntry
  ];
  static List<UefiDriversItem> commonHedtUefiDriversItems = [
    HfsPlus,
    OpenRuntime,
    OpenCanopy,
    ResetNvramEntry
  ];
}
