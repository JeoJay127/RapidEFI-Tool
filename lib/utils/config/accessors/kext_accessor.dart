import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';

class KextAccessor {
  KextAccessor._();

  static List<KernelKext> selectedKexts(ConfigModel model) {
    return model.kernel.kernelKexts;
  }

  static List<KernelKext> selectedKextsIn(
    ConfigModel model,
    Iterable<KernelKext> candidates,
  ) {
    return candidates
        .where((kext) => hasBundlePath(model, kext.bundlePath))
        .toList();
  }

  static bool containsKext(ConfigModel model, KernelKext kext) {
    return hasBundlePath(model, kext.bundlePath);
  }

  static void addKexts(ConfigModel model, Iterable<KernelKext> kexts) {
    for (final kext in kexts) {
      addKext(model, kext);
    }
  }

  static void removeKexts(ConfigModel model, Iterable<KernelKext> kexts) {
    final bundlePaths = kexts.map((kext) => kext.bundlePath).toSet();
    model.kernel.kernelKexts = List<KernelKext>.from(model.kernel.kernelKexts)
      ..removeWhere((kext) => bundlePaths.contains(kext.bundlePath));
  }

  static void replaceKexts(
    ConfigModel model,
    Iterable<KernelKext> removableKexts,
    Iterable<KernelKext> selectedKexts,
  ) {
    removeKexts(model, removableKexts);
    addKexts(model, selectedKexts);
  }

  static bool hasBundlePath(ConfigModel model, String bundlePath) {
    return model.kernel.kernelKexts
        .any((kext) => kext.bundlePath == bundlePath);
  }

  static void addKext(ConfigModel model, KernelKext kext) {
    final kexts = List<KernelKext>.from(model.kernel.kernelKexts);
    if (kexts.any((item) => item.bundlePath == kext.bundlePath)) return;
    kexts.add(kext.copyWith(enabled: true));
    model.kernel.kernelKexts = kexts;
  }

  static void removeBundlePath(ConfigModel model, String bundlePath) {
    model.kernel.kernelKexts = List<KernelKext>.from(model.kernel.kernelKexts)
      ..removeWhere((kext) => kext.bundlePath == bundlePath);
  }

  static bool usesUsbWifi(ConfigModel model) {
    return hasBundlePath(model, ConfigKernel.RtWlanU.bundlePath) ||
        hasBundlePath(model, ConfigKernel.RtWlanU1827.bundlePath);
  }

  static void setUsesUsbWifi(ConfigModel model, bool enabled) {
    removeBundlePath(model, ConfigKernel.RtWlanU.bundlePath);
    removeBundlePath(model, ConfigKernel.RtWlanU1827.bundlePath);
    if (enabled) {
      addKext(model, ConfigKernel.RtWlanU);
      addKext(model, ConfigKernel.RtWlanU1827);
    }
  }

  static bool shouldRecommendCpuFriend(ConfigModel model) {
    return model.cpuType == CpuType.intel &&
        model.platformType == PlatformType.desktop &&
        model.platformRank >= 12 &&
        (model.platformInfo.generic?.systemProductName.contains('MacPro7,1') ??
            false);
  }

  static void applyCpuFriendRecommendation(ConfigModel model) {
    final kexts = ConfigKextGroups.cpuFriend.kexts;
    if (shouldRecommendCpuFriend(model)) {
      addKexts(model, kexts);
    } else {
      removeKexts(model, kexts);
    }
  }
}

extension KextConfigAccess on ConfigModel {
  bool get enableUSBWiFi => KextAccessor.usesUsbWifi(this);
  set enableUSBWiFi(bool value) => KextAccessor.setUsesUsbWifi(this, value);
}
