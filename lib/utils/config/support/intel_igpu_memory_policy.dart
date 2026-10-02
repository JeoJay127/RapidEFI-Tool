import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/device_properties/device_property_item.dart';
import 'package:rapidefi/utils/config/models/device_properties/igpu_model.dart';
import 'package:rapidefi/utils/config/models/enums/brand_enum.dart';
import 'package:rapidefi/utils/config/models/enums/cpu_type_enum.dart';
import 'package:rapidefi/utils/config/models/enums/platform_type_enum.dart';
import 'package:rapidefi/utils/config/presets/sections/config_device_properties.dart';
import 'package:rapidefi/utils/config/support/platform_properties.dart';
import 'package:rapidefi/utils/hardware/model/monitor.dart';

class IntelIgpuMemoryPolicy {
  IntelIgpuMemoryPolicy._();

  static const _supportedPlatforms = {
    'ivy_bridge',
    'haswell',
    'broadwell',
    'skylake',
    'kaby_lake',
    'coffee_lake_8th',
    'coffee_lake_9th',
    'comet_lake',
    'ice_lake',
  };

  static bool hasDrivenFramebuffer(ConfigModel model) =>
      _drivenFramebuffer(model) != null;

  static bool hasManualDisplay(ConfigModel model) {
    final framebuffer =
        DevicePropertiesAccessor.getModel(model, ConfigDp.pciPath);
    return framebuffer != null &&
        hasDisplayProperties(framebuffer.propertyItems);
  }

  static bool hasDisplayProperties(Iterable<DevicePropertyItem> items) =>
      items.any((item) =>
          item.display &&
          (item.key == 'AAPL,ig-platform-id' ||
              item.key == 'AAPL,snb-platform-id' ||
              item.key == 'framebuffer-patch-enable') &&
          item.value != '11223344');

  static void applyManualDefault(ConfigModel model) {
    if (model.cpuType != CpuType.intel ||
        model.platformType == PlatformType.hedt) {
      return;
    }

    if (!hasManualDisplay(model)) {
      DevicePropertiesAccessor.replaceIGPUProperties(model, {});
      return;
    }

    final framebuffer =
        DevicePropertiesAccessor.getModel(model, ConfigDp.pciPath)!;
    _applyUnifiedMemoryDefault(model, framebuffer);
    if (model.brand == Brand.microsoft) return;

    DevicePropertiesAccessor.addIGPUProperties(model, [
      framebuffer_stolenmem_1k,
      framebuffer_fbmem,
    ]);
    _applyHdmiDefaults(model, framebuffer);
  }

  static void applyAutomaticDefault(ConfigModel model, MonitorsInfo? monitors) {
    if (model.brand == Brand.microsoft) return;

    final framebuffer = _drivenFramebuffer(model);
    if (framebuffer == null) {
      if (model.cpuType == CpuType.intel &&
          model.platformType != PlatformType.hedt) {
        DevicePropertiesAccessor.replaceIGPUProperties(model, {});
      }
      return;
    }

    _applyUnifiedMemoryDefault(model, framebuffer);

    final resolution = model.platformType == PlatformType.laptop
        ? _screenWidth(monitors)
        : null;
    final stolenmem = resolution == null || resolution <= 2560
        ? framebuffer_stolenmem_1k
        : resolution <= 3500
            ? framebuffer_stolenmem_30m
            : framebuffer_stolenmem_2k;

    DevicePropertiesAccessor.setProperty(model, framebuffer.pciPath, stolenmem);
    if (resolution == null || resolution <= 2560) {
      DevicePropertiesAccessor.setProperty(
          model, framebuffer.pciPath, framebuffer_fbmem);
    } else {
      DevicePropertiesAccessor.removeProperty(
          model, framebuffer.pciPath, framebuffer_fbmem.key!);
    }
    _applyHdmiDefaults(model, framebuffer);
  }

  static void _applyUnifiedMemoryDefault(
    ConfigModel model,
    IgpuPropertyModel framebuffer,
  ) {
    if (!_supportedPlatforms.contains(model.platformCode)) return;
    DevicePropertiesAccessor.setProperty(
      model,
      framebuffer.pciPath,
      framebuffer_unifiedmem_2048,
    );
  }

  static void _applyHdmiDefaults(
    ConfigModel model,
    IgpuPropertyModel framebuffer,
  ) {
    if (model.platformType != PlatformType.desktop &&
            model.platformType != PlatformType.nuc ||
        !_supportedPlatforms.contains(model.platformCode)) {
      return;
    }

    for (final option in selectableIGPUDevicePropertyOptions()
        .where((option) => option.multiSelectGroup == 'hdmi_type_patch')) {
      final prefix = option.items.first.key!.replaceFirst('-enable', '');
      if (framebuffer.propertyItems
          .any((item) => item.key == '$prefix-alldata')) {
        continue;
      }
      for (final item in option.items) {
        DevicePropertiesAccessor.setProperty(model, framebuffer.pciPath, item);
      }
    }
  }

  static void applySurfaceDefault(ConfigModel model) {
    if (model.brand != Brand.microsoft) return;

    final framebuffer = _drivenFramebuffer(model);
    if (framebuffer == null) {
      DevicePropertiesAccessor.replaceIGPUProperties(model, {});
      return;
    }

    _applyUnifiedMemoryDefault(model, framebuffer);

    DevicePropertiesAccessor.setProperty(
      model,
      framebuffer.pciPath,
      framebuffer_stolenmem_30m,
    );
  }

  static IgpuPropertyModel? _drivenFramebuffer(ConfigModel model) {
    if (model.cpuType != CpuType.intel ||
        model.platformType == PlatformType.hedt ||
        !_supportedPlatforms.contains(model.platformCode)) {
      return null;
    }

    IgpuPropertyModel? framebuffer;
    var displays = false;
    for (final device in model.deviceProperties.addList ?? const []) {
      for (final item in device.propertyItems) {
        final key = item.key?.trim().toLowerCase();
        if (key != 'aapl,ig-platform-id' && key != 'aapl,snb-platform-id') {
          continue;
        }
        framebuffer = device;
        displays =
            item.display && item.value?.trim().toUpperCase() != '11223344';
      }
    }
    return displays ? framebuffer : null;
  }

  static int? _screenWidth(MonitorsInfo? monitors) {
    if (monitors == null) return null;

    final entries = monitors.monitors.entries;
    for (final entry in entries) {
      final connector = entry.value.connectorType?.toLowerCase() ?? '';
      final name = entry.key.toLowerCase();
      if (connector.contains('edp') ||
          connector.contains('lvds') ||
          name.contains('built-in') ||
          name.contains('internal')) {
        final width = _resolutionWidth(entry.value.resolution);
        if (width != null) return width;
      }
    }
    for (final monitor in monitors.monitors.values) {
      final width = _resolutionWidth(monitor.resolution);
      if (width != null) return width;
    }
    return null;
  }

  static int? _resolutionWidth(String? resolution) {
    final match =
        RegExp(r'(\d{3,5})\s*[xX×]\s*(\d{3,5})').firstMatch(resolution ?? '');
    if (match == null) return null;
    final first = int.parse(match.group(1)!);
    final second = int.parse(match.group(2)!);
    return first > second ? first : second;
  }
}
