import '../../models/misc/misc_boot.dart';
import '../../models/misc/misc_security.dart';
import '../../models/misc/misc_tools_item.dart';

class ConfigMisc {
  static MiscBoot commonMiscBoot = MiscBoot(
      hideAuxiliary: true,
      pollAppleHotKeys: true,
      showPicker: true,
      pickerAttributes: 145,
      pickerMode: 'External',
      pickerVariant: 'Acidanthera\\GoldenGate');

  static MiscSecurity commonMiscSecurity = MiscSecurity(
      allowSetDefault: true,
      blacklistAppleUpdate: true,
      secureBootModel: 'Disabled',
      vault: 'Optional',
      scanPolicy: 0);
  static List<MiscToolsItem> commoMiscToolsItems = [
    MiscToolsItem(
        name: 'UEFI Shell',
        path: 'OpenShell.efi',
        arguments: '',
        auxiliary: true,
        comment: 'Uefi Shell Tool',
        enabled: true,
        flavour: 'OpenShell:UEFIShell:Shell')
  ];
}
