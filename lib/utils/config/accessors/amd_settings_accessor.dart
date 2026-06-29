import 'dart:typed_data';

import 'package:rapidefi/extension/int_extension.dart';
import 'package:rapidefi/extension/string_extension.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/presets/patches/kernel_patch.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_patch_item.dart';

class AmdSettingsAccessor {
  AmdSettingsAccessor._();

  static bool usesRyzenGpu(ConfigModel model) {
    return model.kernel.kernelKexts.any(
      (kext) => kext.bundlePath == ConfigKernel.NootedRed.bundlePath,
    );
  }

  static void setUsesRyzenGpu(ConfigModel model, bool enabled) {
    final kexts = List.of(model.kernel.kernelKexts)
      ..removeWhere(
        (kext) => kext.bundlePath == ConfigKernel.NootedRed.bundlePath,
      );
    if (enabled) {
      kexts.add(ConfigKernel.NootedRed.copyWith(
        enabled: false,
      ));
    }
    model.kernel.kernelKexts = kexts;
  }

  static String getAmdCore(ConfigModel model) {
    final patch = (model.kernel.kernelPatchItems ?? []).firstWhere(
      _isAmdCorePatch,
      orElse: () => KernelPatchItem(),
    );
    final replace = patch.replace;
    if (replace == null || replace.length < 5) {
      return '6';
    }
    return replace[1].toString();
  }

  static void setAmdCore(ConfigModel model, String core) {
    final coreNumber = int.tryParse(core);
    if (coreNumber == null) {
      return;
    }

    final coreHex = coreNumber.toHexString;
    final replacements = [
      'B8${coreHex}00000000',
      'BA${coreHex}00000000',
      'BA${coreHex}00000090',
      'BA${coreHex}000000',
    ];
    final patches = KernelPatch.amd_ryzen_kernel_patches
        .map((patch) => patch.copyWith())
        .toList();
    for (var i = 0; i < replacements.length; i++) {
      patches[i] = patches[i].copyWith(replace: replacements[i].toBytes());
    }
    model.kernel.kernelPatchItems = patches;
  }

  static bool hasAmdKernelPatches(ConfigModel model) {
    return (model.kernel.kernelPatchItems ?? []).any(_isAmdCorePatch);
  }

  static bool _isAmdCorePatch(KernelPatchItem patch) {
    return patch.base == '_cpuid_set_info' &&
        _bytesEqual(patch.find, 'C1E81A000000'.toBytes());
  }

  static bool _bytesEqual(Uint8List? left, Uint8List right) {
    if (left == null || left.length != right.length) {
      return false;
    }
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) {
        return false;
      }
    }
    return true;
  }
}
