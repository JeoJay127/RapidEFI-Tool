import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_block_item.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/patches/kernel_patch.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';

class WifiOclpSupport {
  WifiOclpSupport._();

  static bool applyToModel(
    ConfigModel model, {
    Iterable<KernelKext>? selectedKexts,
    bool clearWhenNotRequired = false,
  }) {
    final selectedBundlePaths = (selectedKexts ?? model.kernel.kernelKexts)
        .map((kext) => kext.bundlePath)
        .toSet();
    final requiredBlocks = _requiredKernelBlocks(
      selectedBundlePaths,
      model.darwinMajorVersion,
    );
    final needsAtherosOclp =
        model.darwinMajorVersion >= 21 && _hasAtherosWifi(selectedBundlePaths);
    final needsOclp = requiredBlocks.isNotEmpty || needsAtherosOclp;

    _removeManagedKernelBlocks(model);

    if (!needsOclp) {
      if (clearWhenNotRequired) {
        _clearManagedRuntimeItems(model);
      }
      return false;
    }

    NvramSettingsAccessor.setCsrSetting(model, CsrSetting.partialDisabled);
    ensureAmfiBypass(model);

    for (final block in requiredBlocks) {
      _addKernelBlock(model, block);
    }

    if (needsAtherosOclp) {
      KextAccessor.addKexts(
        model,
        ConfigKextGroups.atherosWifiModernSupport.kexts,
      );
    }

    return true;
  }

  static Set<KernelBlockItem> _requiredKernelBlocks(
    Set<String> selectedBundlePaths,
    int darwinMajorVersion,
  ) {
    final blocks = <KernelBlockItem>{};

    if (darwinMajorVersion >= 24 &&
        (_hasSequoiaIntelWifi(selectedBundlePaths) ||
            _hasBrcmWifi(selectedBundlePaths))) {
      blocks.add(KernelPatch.fixIntelWiFiForSequoia);
      return blocks;
    }

    if (darwinMajorVersion >= 23 && _hasBrcmWifi(selectedBundlePaths)) {
      blocks.add(KernelPatch.fixBrcmWiFiForSonoma);
    }

    return blocks;
  }

  static bool _hasSequoiaIntelWifi(Set<String> bundlePaths) {
    return bundlePaths.contains(ConfigKernel.AirportItlwm_Sequoia.bundlePath);
  }

  static bool _hasBrcmWifi(Set<String> bundlePaths) {
    return [
      ...ConfigKextGroups.brcm94360.kexts,
      ConfigKernel.AirportBrcmFixup,
      ConfigKernel.AirportBrcmFixupAirPortBrcm4360_Injector,
      ConfigKernel.AirportBrcmFixupAirPortBrcmNIC_Injector,
      ConfigKernel.IO80211ElCap_AirPortBrcm4331,
      ConfigKernel.IO80211ElCap_AppleAirPortBrcm43224,
    ].any((kext) => bundlePaths.contains(kext.bundlePath));
  }

  static bool _hasAtherosWifi(Set<String> bundlePaths) {
    return ConfigKextGroups.atherosWifiModels.kexts.any(
      (kext) => bundlePaths.contains(kext.bundlePath),
    );
  }

  static void ensureAmfiBypass(ConfigModel model) {
    if (!BootArgsAccessor.containsPrefix(model, ConfigNvram.amfi.arg) &&
        !BootArgsAccessor.containsPrefix(
          model,
          ConfigNvram.amfi_get_out_of_my_way.arg,
        )) {
      BootArgsAccessor.add(model, ConfigNvram.amfi.arg);
    }
    if (!BootArgsAccessor.containsPrefix(
      model,
      ConfigNvram.ipc_control_port_options.arg,
    )) {
      BootArgsAccessor.add(model, ConfigNvram.ipc_control_port_options.arg);
    }
    KextAccessor.addKext(model, ConfigKernel.AMFIPass);
  }

  static void _addKernelBlock(ConfigModel model, KernelBlockItem block) {
    final blocks = model.kernel.kernelBlockItems ??= [];
    if (block.identifier == KernelPatch.fixBrcmWiFiForSonoma.identifier) {
      _removeManagedKernelBlocks(model);
    }

    final exists = blocks.any(
      (item) =>
          item.identifier == block.identifier &&
          item.minKernel == block.minKernel &&
          item.strategy == block.strategy,
    );
    if (!exists) {
      blocks.add(block.copyWith());
    }
  }

  static void _removeManagedKernelBlocks(ConfigModel model) {
    model.kernel.kernelBlockItems?.removeWhere(
      (item) =>
          item.identifier == KernelPatch.fixBrcmWiFiForSonoma.identifier &&
          (item.minKernel == KernelPatch.fixBrcmWiFiForSonoma.minKernel ||
              item.minKernel == KernelPatch.fixIntelWiFiForSequoia.minKernel),
    );
  }

  static void _clearManagedRuntimeItems(ConfigModel model) {
    NvramSettingsAccessor.setCsrSetting(model, CsrSetting.enabled);
    clearAmfiBypass(model);
  }

  static void clearAmfiBypass(ConfigModel model) {
    BootArgsAccessor.remove(model, ConfigNvram.amfi.arg);
    BootArgsAccessor.remove(model, ConfigNvram.amfi_get_out_of_my_way.arg);
    BootArgsAccessor.remove(model, ConfigNvram.amfipassbeta.arg);
    BootArgsAccessor.remove(model, ConfigNvram.ipc_control_port_options.arg);
    KextAccessor.removeKexts(model, [ConfigKernel.AMFIPass]);
  }
}
