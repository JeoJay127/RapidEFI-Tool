import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/sections/config_acpi.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';

class SurfaceSupport {
  SurfaceSupport._();

  static final touchPadKexts = ConfigKextGroups.touchPadGroups
      .expand((group) => group.kexts)
      .toList(growable: false);

  static final _conflictingKexts = <KernelKext>[
    ...ConfigKextGroups.touchPadGroups
        .where((group) => group != ConfigKextGroups.bigSurface)
        .expand((group) => group.kexts),
    ConfigKernel.SMCBatteryManager,
    ConfigKernel.SMCLightSensor,
  ];

  static final _managedSurfaceKexts = <KernelKext>[
    ...ConfigKextGroups.bigSurface.kexts,
  ];

  static bool matchesText(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('surface') || normalized.contains('microsoft');
  }

  static List<KernelKext> selectedTouchPadKexts(ConfigModel model) {
    return KextAccessor.selectedKextsIn(model, touchPadKexts);
  }

  static void apply(ConfigModel model, {bool includeBrightnessKeys = false}) {
    KextAccessor.removeKexts(model, _conflictingKexts);
    KextAccessor.addKexts(model, ConfigKextGroups.bigSurface.kexts);
    if (includeBrightnessKeys) {
      KextAccessor.addKext(model, ConfigKernel.BrightnessKeys);
    }

    _removeAcpiByPath(model, ConfigAcpi.SSDT_ALS0.path);
    _addAcpiIfMissing(model, ConfigAcpi.SSDT_SURFACE);
  }

  static void restoreTouchPadSelection(
    ConfigModel model,
    Iterable<KernelKext> selectedKexts,
  ) {
    KextAccessor.removeKexts(model, touchPadKexts);
    KextAccessor.addKexts(model, selectedKexts);
    _removeAcpiByPath(model, ConfigAcpi.SSDT_SURFACE.path);
  }

  static void removeManagedSurfaceKexts(ConfigModel model) {
    KextAccessor.removeKexts(model, _managedSurfaceKexts);
  }

  static void _addAcpiIfMissing(ConfigModel model, AcpiAddItem item) {
    final items = List<AcpiAddItem>.from(model.acpi.acpiAddItems)
      ..removeWhere((acpi) => acpi.path == item.path);
    model.acpi.acpiAddItems = [
      item.copyWith(),
      ...items,
    ];
  }

  static void _removeAcpiByPath(ConfigModel model, String path) {
    model.acpi.acpiAddItems = List<AcpiAddItem>.from(model.acpi.acpiAddItems)
      ..removeWhere((item) => item.path == path);
  }
}
