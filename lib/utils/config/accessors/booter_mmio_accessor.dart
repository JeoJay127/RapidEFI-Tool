import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/presets/patches/booter_patch.dart';

class BooterMmioAccessor {
  BooterMmioAccessor._();

  static bool usesPrecastMmio(ConfigModel model) {
    return model.booter.booterQuirks.devirtualiseMmio &&
        model.booter.booterMmioWhitelistItems.any(
          (item) => item.address == BooterPatch.mmioWhitelistItem1.address,
        );
  }

  static void setUsesPrecastMmio(ConfigModel model, bool enabled) {
    model.booter.booterQuirks.devirtualiseMmio = enabled;
    model.booter.booterMmioWhitelistItems =
        enabled ? [BooterPatch.mmioWhitelistItem1] : [];
  }
}

extension BooterMmioConfigAccess on ConfigModel {
  bool get usePrecastMMIO => BooterMmioAccessor.usesPrecastMmio(this);
  set usePrecastMMIO(bool value) =>
      BooterMmioAccessor.setUsesPrecastMmio(this, value);
}
