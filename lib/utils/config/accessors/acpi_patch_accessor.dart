import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_patch_item.dart';
import 'package:rapidefi/utils/config/presets/patches/acpi_patch.dart';

class AcpiPatchAccessor {
  AcpiPatchAccessor._();

  static const String defaultHpetPath = r'\_SB.PCI0.LPCB.HPET';

  static AcpiPatchItem? getHpetPatch(ConfigModel model) {
    for (final patch in model.acpi.acpiPatchItems) {
      if (_isHpetPatch(patch)) {
        return patch;
      }
    }
    return null;
  }

  static bool isHpetPatchEnabled(ConfigModel model) {
    return getHpetPatch(model)?.enabled ?? false;
  }

  static String getHpetPath(ConfigModel model) {
    final patch = getHpetPatch(model);
    if (patch?.enabled != true) {
      return '';
    }

    final path = patch?.base ?? '';
    return path.isNotEmpty ? path : defaultHpetPath;
  }

  static void setHpetPatch(
    ConfigModel model, {
    required String path,
  }) {
    final patches = <AcpiPatchItem>[];
    var patched = false;

    for (final patch in model.acpi.acpiPatchItems) {
      if (!_isHpetPatch(patch)) {
        patches.add(patch);
        continue;
      }

      if (!patched) {
        patches.add(AcpiPatch.fixHPET.copyWith(
          base: path,
          enabled: true,
        ));
        patched = true;
      }
    }

    if (!patched) {
      patches.add(AcpiPatch.fixHPET.copyWith(
        base: path,
        enabled: true,
      ));
    }
    model.acpi.acpiPatchItems = patches;
  }

  static void removeHpetPatch(ConfigModel model) {
    model.acpi.acpiPatchItems = List<AcpiPatchItem>.from(
      model.acpi.acpiPatchItems,
    )..removeWhere(
        _isHpetPatch,
      );
  }

  static bool _isHpetPatch(AcpiPatchItem patch) {
    final fix = AcpiPatch.fixHPET;
    return patch.comment == fix.comment &&
        _sameBytes(patch.find, fix.find) &&
        _sameBytes(patch.replace, fix.replace);
  }

  static bool _sameBytes(List<int>? left, List<int>? right) {
    if (identical(left, right)) return true;
    if (left == null || right == null || left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

extension AcpiPatchConfigAccess on ConfigModel {
  bool get enableHpetPatch => AcpiPatchAccessor.isHpetPatchEnabled(this);
  set enableHpetPatch(bool value) {
    if (value) {
      final path =
          hpetPath.isNotEmpty ? hpetPath : AcpiPatchAccessor.defaultHpetPath;
      AcpiPatchAccessor.setHpetPatch(this, path: path);
    } else {
      AcpiPatchAccessor.removeHpetPatch(this);
    }
  }

  String get hpetPath => AcpiPatchAccessor.getHpetPath(this);
  set hpetPath(String value) {
    final path = value.trim();
    if (path.isEmpty) {
      AcpiPatchAccessor.removeHpetPatch(this);
      return;
    }
    AcpiPatchAccessor.setHpetPatch(this, path: path);
  }
}
