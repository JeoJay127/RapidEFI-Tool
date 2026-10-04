import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/device_properties/device_property_item.dart';
import 'package:rapidefi/utils/config/models/device_properties/igpu_model.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/presets/sections/config_device_properties.dart';
import 'package:rapidefi/utils/config/support/device_id_util.dart';
import 'package:rapidefi/utils/config/support/platform_properties.dart';
import 'package:rapidefi/utils/hardware/analysis/gpu_compatibility_data.dart';

class DevicePropertiesAccessor {
  DevicePropertiesAccessor._();

  static const edidKey = 'AAPL00,override-no-connect';
  static const igPlatformIdKey = 'AAPL,ig-platform-id';
  static const deviceIdKey = 'device-id';
  static const builtInKey = 'built-in';
  static const modelKey = 'model';
  static const int maxIntelConnectorIndex = 3;

  static Set<DevicePropertyItem> selectableIGPUProperties() =>
      selectableIGPUDeviceProperties();

  /// 六代核显用于输出时，按目标系统推荐基础方案，与列表排序无关。
  static List<IgpuPropertyModel>? skylakeDisplayModeForTarget(
    ConfigModel model,
  ) {
    if (model.cpuType != CpuType.intel || model.platformCode != 'skylake') {
      return null;
    }

    final modern = model.darwinMajorVersion >= 22;
    final mode = switch (model.platformType) {
      PlatformType.desktop =>
        modern ? ConfigDp.intel_desktop_6th_1 : ConfigDp.intel_desktop_6th_3,
      PlatformType.laptop =>
        modern ? ConfigDp.intel_laptop_6th_1 : ConfigDp.intel_laptop_6th_2,
      PlatformType.nuc =>
        modern ? ConfigDp.intel_nuc_6th_1 : ConfigDp.intel_nuc_6th_3,
      PlatformType.hedt => null,
    };
    return mode?.map((item) => item.copyWith()).toList();
  }

  /// 在系统版本改变或自动构建初始化时调用，保留随后手动选择的方案。
  static void synchronizeSkylakeDisplayMode(ConfigModel model) {
    final mode = skylakeDisplayModeForTarget(model);
    final devices = model.deviceProperties.addList;
    if (mode == null || devices == null) return;

    for (final device in devices) {
      final outputsDisplay = device.propertyItems.any((item) {
        final value = item.value?.trim().toUpperCase();
        return item.key?.toLowerCase() == igPlatformIdKey.toLowerCase() &&
            item.display &&
            (value?.isNotEmpty ?? false) &&
            value != '11223344' &&
            value != ConfigDp.intel_desktop_computing_id_6th.value;
      });
      if (!outputsDisplay) continue;

      rememberIntelDeviceId(device);
      // 仅替换基础 ID，不改变 PCI 路径、DVMT、接口、EDID 或其他设备。
      device.propertyItems = [
        ...mode.first.propertyItems.map((item) => item.copyWith()),
        ...device.propertyItems.where((item) {
          final key = item.key?.toLowerCase();
          return key != igPlatformIdKey.toLowerCase() && key != deviceIdKey;
        }),
      ];
    }
  }

  static String intelDeviceId(IgpuPropertyModel device) {
    if (device.sourceDeviceId.trim().isNotEmpty) {
      final id = GpuCompatibilityData.normalizeFullDeviceId(
        device.sourceDeviceId.replaceAll(':', '-'),
      ).replaceFirst(RegExp(r'^0X'), '');
      return RegExp(r'^[0-9A-F]{4}$').hasMatch(id) ? '8086-$id' : id;
    }

    for (final item in device.propertyItems) {
      if (item.key?.toLowerCase() != deviceIdKey || item.dataType != 'data') {
        continue;
      }
      final value = item.value?.trim().toUpperCase() ?? '';
      if (!RegExp(r'^[0-9A-F]{4}0000$').hasMatch(value)) return '';
      return '8086-${DeviceIdUtils.reverseDeviceId(value.substring(0, 4))}';
    }
    return '';
  }

  static void rememberIntelDeviceId(IgpuPropertyModel device) {
    if (device.sourceDeviceId.isNotEmpty) return;
    final id = intelDeviceId(device);
    // 兼容性仿冒 ID 不能确定原始硬件；保留原生六代 ID 供后续切换使用。
    if (id.startsWith('8086-19')) device.sourceDeviceId = id;
  }

  static IgpuPropertyModel ensureModel(ConfigModel model, String pciPath) {
    final addList = model.deviceProperties.addList ??= [];
    for (final item in addList) {
      if (item.pciPath == pciPath) {
        return item;
      }
    }
    final item = IgpuPropertyModel(pciPath: pciPath, propertyItems: []);
    addList.add(item);
    return item;
  }

  static IgpuPropertyModel? getModel(ConfigModel model, String pciPath) {
    final addList = model.deviceProperties.addList;
    if (addList == null) return null;
    for (final item in addList) {
      if (item.pciPath == pciPath) {
        return item;
      }
    }
    return null;
  }

  static DevicePropertyItem? getProperty(
    ConfigModel model,
    String pciPath,
    String key,
  ) {
    final propertyModel = getModel(model, pciPath);
    if (propertyModel == null) return null;
    for (final item in propertyModel.propertyItems) {
      if (item.key == key) {
        return item;
      }
    }
    return null;
  }

  static void setProperty(
    ConfigModel model,
    String pciPath,
    DevicePropertyItem item,
  ) {
    final propertyModel = ensureModel(model, pciPath);
    final propertyItem = item.copyWith();
    final index = propertyModel.propertyItems.indexWhere(
      (entry) => entry.key == propertyItem.key,
    );
    if (index == -1) {
      propertyModel.propertyItems.add(propertyItem);
    } else {
      propertyModel.propertyItems[index] = propertyItem;
    }
  }

  static void setPropertyIfAbsent(
    ConfigModel model,
    String pciPath,
    DevicePropertyItem item,
  ) {
    if (pciPath.trim().isEmpty ||
        getProperty(model, pciPath, item.key ?? '') != null) {
      return;
    }
    setProperty(model, pciPath, item);
  }

  static void markBuiltInDevice(
    ConfigModel model, {
    required String? pciPath,
    required String displayName,
  }) {
    final path = pciPath?.trim() ?? '';
    if (path.isEmpty) return;

    final name = displayName.trim();

    setPropertyIfAbsent(
      model,
      path,
      DevicePropertyItem(
        key: builtInKey,
        value: '01',
        dataType: 'data',
      ),
    );

    if (name.isEmpty) return;

    setPropertyIfAbsent(
      model,
      path,
      DevicePropertyItem(
        key: modelKey,
        value: name,
        dataType: 'string',
      ),
    );
  }

  static void removeProperty(ConfigModel model, String pciPath, String key) {
    final propertyModel = getModel(model, pciPath);
    propertyModel?.propertyItems.removeWhere(
      (item) => item.key == key,
    );
    removeModelIfEmpty(model, pciPath);
  }

  static void removeModelIfEmpty(ConfigModel model, String pciPath) {
    final addList = model.deviceProperties.addList;
    if (addList == null) return;

    addList.removeWhere(
      (item) => item.pciPath == pciPath && item.propertyItems.isEmpty,
    );
    if (addList.isEmpty) {
      model.deviceProperties.addList = null;
    }
  }

  static Set<DevicePropertyItem> selectedIGPUProperties(ConfigModel model) {
    final igpuModel = getModel(model, ConfigDp.pciPath);
    if (igpuModel == null) return {};
    final customConnectors = getIntelConnectorAllData(model).keys;

    return selectableIGPUProperties()
        .where(
          (candidate) => !_isIgnoredConnectorPresetItem(
            candidate,
            customConnectors,
          ),
        )
        .where((candidate) => igpuModel.propertyItems.any(
              (item) => _sameProperty(item, candidate),
            ))
        .toSet();
  }

  static void replaceIGPUProperties(
    ConfigModel model,
    Set<DevicePropertyItem> selectedItems,
  ) {
    final customConnectors = getIntelConnectorAllData(model);
    final explicitlySelectedConnectors =
        _connectorIndexesFromItems(selectedItems);
    final customConnectorsToProtect = customConnectors.keys
        .where((index) => !explicitlySelectedConnectors.contains(index))
        .toSet();
    final selectableKeys = _expandedConnectorConflictKeys(
      selectableIGPUProperties()
          .where(
            (item) => !_isIgnoredConnectorPresetItem(
              item,
              customConnectorsToProtect,
            ),
          )
          .map((item) => item.key)
          .toSet(),
    );
    final existingModel = getModel(model, ConfigDp.pciPath);

    if (selectedItems.isEmpty) {
      existingModel?.propertyItems.removeWhere(
        (item) => selectableKeys.contains(item.key),
      );
      removeModelIfEmpty(model, ConfigDp.pciPath);
      return;
    }

    final igpuModel = existingModel ?? ensureModel(model, ConfigDp.pciPath);
    final edidValue = getEdid(model).trim().toUpperCase();
    igpuModel.propertyItems.removeWhere(
      (item) => selectableKeys.contains(item.key),
    );
    addIGPUProperties(
      model,
      selectedItems
          .where(
            (item) => !_isIgnoredConnectorPresetItem(
              item,
              customConnectorsToProtect,
            ),
          )
          .where(
            (item) => !_isEdidOverrideKey(item.key) || edidValue.isNotEmpty,
          )
          .map(
            (item) => _isEdidOverrideKey(item.key)
                ? item.copyWith(value: edidValue, dataType: 'data')
                : item,
          ),
    );
  }

  static void addIGPUProperties(
    ConfigModel model,
    Iterable<DevicePropertyItem> items,
  ) {
    for (final item in items) {
      setProperty(model, ConfigDp.pciPath, item.copyWith());
    }
  }

  static Map<int, String> getIntelConnectorAllData(ConfigModel model) {
    final igpuModel = getModel(model, ConfigDp.pciPath);
    if (igpuModel == null) return const {};

    final values = <int, String>{};
    for (var index = 0; index <= maxIntelConnectorIndex; index++) {
      final key = _connectorAllDataKey(index);
      final item = igpuModel.propertyItems.firstWhere(
        (property) => property.key == key,
        orElse: () => DevicePropertyItem(
          key: key,
          dataType: 'data',
          value: '',
        ),
      );
      final value = item.value?.trim() ?? '';
      if (value.isNotEmpty) {
        values[index] = value;
      }
    }
    return values;
  }

  static String getIntelIgPlatformId(ConfigModel model) {
    return getProperty(model, ConfigDp.pciPath, igPlatformIdKey)?.value ?? '';
  }

  static void setIntelConnectorAllData(
    ConfigModel model,
    int connectorIndex,
    String value,
  ) {
    if (connectorIndex < 0 || connectorIndex > maxIntelConnectorIndex) {
      return;
    }

    final normalizedValue = value.trim().toUpperCase();
    final keys = _connectorConflictKeys(connectorIndex);
    final igpuModel = ensureModel(model, ConfigDp.pciPath);
    igpuModel.propertyItems.removeWhere(
      (item) => keys.contains(item.key),
    );

    if (normalizedValue.isNotEmpty) {
      igpuModel.propertyItems.add(
        DevicePropertyItem(
          key: _connectorEnableKey(connectorIndex),
          dataType: 'data',
          value: '01000000',
          comment: '启用 Intel 核显 con$connectorIndex 接口定制',
        ),
      );
      igpuModel.propertyItems.add(
        DevicePropertyItem(
          key: _connectorAllDataKey(connectorIndex),
          dataType: 'data',
          value: normalizedValue,
          comment: 'Intel 核显 con$connectorIndex 接口定制',
        ),
      );
    }

    removeModelIfEmpty(model, ConfigDp.pciPath);
  }

  static bool _sameProperty(
    DevicePropertyItem item,
    DevicePropertyItem candidate,
  ) {
    if (_isEdidOverrideKey(item.key) && item.key == candidate.key) {
      return item.dataType == candidate.dataType;
    }
    return item.key == candidate.key &&
        item.value == candidate.value &&
        item.dataType == candidate.dataType;
  }

  static String _connectorAllDataKey(int connectorIndex) {
    return 'framebuffer-con$connectorIndex-alldata';
  }

  static String _connectorEnableKey(int connectorIndex) {
    return 'framebuffer-con$connectorIndex-enable';
  }

  static Set<String> _connectorConflictKeys(int connectorIndex) {
    final prefix = 'framebuffer-con$connectorIndex';
    return {
      _connectorEnableKey(connectorIndex),
      '$prefix-type',
      '$prefix-index',
      '$prefix-busid',
      '$prefix-pipe',
      '$prefix-flags',
      '$prefix-alldata',
    };
  }

  static Set<int> _connectorIndexesFromItems(
    Iterable<DevicePropertyItem> items,
  ) {
    return items
        .map((item) => _connectorIndexFromKey(item.key ?? ''))
        .whereType<int>()
        .toSet();
  }

  static int? _connectorIndexFromKey(String key) {
    final match = RegExp(r'^framebuffer-con(\d+)-').firstMatch(key);
    if (match == null) return null;
    final index = int.tryParse(match.group(1) ?? '');
    if (index == null || index < 0 || index > maxIntelConnectorIndex) {
      return null;
    }
    return index;
  }

  static Set<String> _expandedConnectorConflictKeys(Set<String?> keys) {
    final result = keys.whereType<String>().toSet();
    for (var index = 0; index <= maxIntelConnectorIndex; index++) {
      final prefix = 'framebuffer-con$index';
      final hasConnectorKey = result.any((key) => key.startsWith(prefix));
      if (hasConnectorKey) {
        result.addAll(_connectorConflictKeys(index));
      }
    }
    return result;
  }

  static bool _isIgnoredConnectorPresetItem(
    DevicePropertyItem item,
    Iterable<int> customConnectorIndexes,
  ) {
    final key = item.key ?? '';
    for (final connectorIndex in customConnectorIndexes) {
      if (_connectorConflictKeys(connectorIndex).contains(key)) {
        return true;
      }
    }
    return false;
  }

  static String getEdid(ConfigModel model) {
    for (var index = 0; index <= maxIntelConnectorIndex; index++) {
      final value =
          getProperty(model, ConfigDp.pciPath, edidOverrideKey(index))?.value ??
              '';
      if (value.trim().isNotEmpty) return value;
    }
    return '';
  }

  static void setEdid(ConfigModel model, String value) {
    final existingKeys = getEdidOverrides(model).keys.toList();
    if (existingKeys.isEmpty) {
      setEdidOverride(model, 0, value);
      return;
    }

    for (final index in existingKeys) {
      setEdidOverride(model, index, value);
    }
  }

  static Map<int, String> getEdidOverrides(ConfigModel model) {
    final igpuModel = getModel(model, ConfigDp.pciPath);
    if (igpuModel == null) return const {};

    final values = <int, String>{};
    for (var index = 0; index <= maxIntelConnectorIndex; index++) {
      final key = edidOverrideKey(index);
      if (igpuModel.propertyItems.any((item) => item.key == key)) {
        values[index] = getProperty(model, ConfigDp.pciPath, key)?.value ?? '';
      }
    }
    return values;
  }

  static void setEdidOverride(
    ConfigModel model,
    int connectorIndex,
    String value,
  ) {
    if (connectorIndex < 0 || connectorIndex > maxIntelConnectorIndex) {
      return;
    }

    final normalizedValue = value.trim().toUpperCase();
    final key = edidOverrideKey(connectorIndex);
    if (normalizedValue.isEmpty) {
      removeProperty(model, ConfigDp.pciPath, key);
      return;
    }

    setProperty(
      model,
      ConfigDp.pciPath,
      DevicePropertyItem(
        key: key,
        value: normalizedValue,
        dataType: 'data',
        comment: '向AAPL0$connectorIndex接口注入显示器EDID',
      ),
    );
  }

  static void setEdidOverrides(
    ConfigModel model,
    String value,
  ) {
    for (var index = 0; index <= maxIntelConnectorIndex; index++) {
      setEdidOverride(model, index, value);
    }
  }

  static String edidOverrideKey(int connectorIndex) {
    return 'AAPL0$connectorIndex,override-no-connect';
  }

  static bool _isEdidOverrideKey(String? key) {
    if (key == null) return false;
    return RegExp(r'^AAPL0[0-2],override-no-connect$').hasMatch(key);
  }

  static String getDgpuFakeId(ConfigModel model, String pciPath) {
    final value = getProperty(model, pciPath, deviceIdKey)?.value ?? '';
    if (value.length != 4) return value;
    return DeviceIdUtils.reverseDeviceId(value);
  }

  static void setDgpuFakeId(
    ConfigModel model,
    String pciPath,
    String fakeId,
  ) {
    final path = pciPath.trim();
    final normalizedFakeId = fakeId.trim().toUpperCase();
    if (path.isEmpty) return;

    final propertyModel = ensureModel(model, path);
    propertyModel.propertyItems.removeWhere(
      (item) => item.key == deviceIdKey,
    );
    if (!RegExp(r'^[0-9A-F]{4}$').hasMatch(normalizedFakeId)) {
      return;
    }

    setProperty(
      model,
      path,
      DevicePropertyItem(
        key: deviceIdKey,
        value: DeviceIdUtils.reverseDeviceId(normalizedFakeId),
        dataType: 'data',
      ),
    );
  }

  static String getDgpuPath(ConfigModel model) {
    final addList = model.deviceProperties.addList ?? [];
    var emptyDgpuPath = '';
    for (final propertyModel in addList) {
      if (propertyModel.pciPath == ConfigDp.pciPath) continue;
      if (propertyModel.propertyItems.any((item) => item.key == deviceIdKey)) {
        return propertyModel.pciPath;
      }
      if (emptyDgpuPath.isEmpty && propertyModel.propertyItems.isEmpty) {
        emptyDgpuPath = propertyModel.pciPath;
      }
    }
    return emptyDgpuPath;
  }

  static String getDgpuFakeIdFromModel(ConfigModel model) {
    final path = getDgpuPath(model);
    return path.isEmpty ? '' : getDgpuFakeId(model, path);
  }

  static void removeDgpuFakeId(ConfigModel model, String pciPath) {
    removeProperty(model, pciPath, deviceIdKey);
  }
}

extension DevicePropertiesConfigAccess on ConfigModel {
  String get edid => DevicePropertiesAccessor.getEdid(this);
  set edid(String value) => DevicePropertiesAccessor.setEdid(this, value);

  String get dgpuPath => DevicePropertiesAccessor.getDgpuPath(this);

  String get dgpuFakeID =>
      DevicePropertiesAccessor.getDgpuFakeIdFromModel(this);
}
