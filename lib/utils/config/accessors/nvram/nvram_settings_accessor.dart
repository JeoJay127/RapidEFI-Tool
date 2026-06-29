import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_add_item.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';

class NvramSettingsAccessor {
  NvramSettingsAccessor._();

  static CsrSetting getCsrSetting(ConfigModel model) {
    final value = _item(
      model,
      ConfigNvram.UUID_7C436110_AB2A_4BBB_A880_FE41995C9F82,
      ConfigNvram.csr_active_config,
    ).value;
    return CsrSetting.values.firstWhere(
      (setting) => setting.nvramValue == value,
      orElse: () => CsrSetting.none,
    );
  }

  static void setCsrSetting(ConfigModel model, CsrSetting setting) {
    _item(
      model,
      ConfigNvram.UUID_7C436110_AB2A_4BBB_A880_FE41995C9F82,
      ConfigNvram.csr_active_config,
    ).value = setting.nvramValue;
  }

  static UIScale getUiScale(ConfigModel model) {
    final item = _findItem(
      model,
      ConfigNvram.UUID_4D1EDE05_38C7_4A6A_9CC6_4BCCA8B38C14,
      ConfigNvram.ui_scale,
    );
    if (item == null) {
      return UIScale.scale00;
    }

    final value = item.value;
    return UIScale.values.firstWhere(
      (scale) => scale.nvramValue == value,
      orElse: () => UIScale.scale00,
    );
  }

  static void setUiScale(ConfigModel model, UIScale scale) {
    const guid = ConfigNvram.UUID_4D1EDE05_38C7_4A6A_9CC6_4BCCA8B38C14;
    if (scale == UIScale.scale00) {
      _removeItems(model, guid, ConfigNvram.ui_scale.key);
      model.uefi.uefiOutput.uIScale = 0;
      return;
    }

    model.uefi.uefiOutput.uIScale = -1;
    final items = _items(model, guid);
    items.removeWhere((item) => item.key == ConfigNvram.ui_scale.key);
    items.add(ConfigNvram.ui_scale.copyWith(value: scale.nvramValue));
  }

  static void normalizeUiScale(ConfigModel model) {
    const guid = ConfigNvram.UUID_4D1EDE05_38C7_4A6A_9CC6_4BCCA8B38C14;
    final item = _findItem(model, guid, ConfigNvram.ui_scale);
    if (item == null) {
      model.uefi.uefiOutput.uIScale = 0;
      return;
    }

    final scale = UIScale.values.where(
      (scale) => scale.nvramValue == item.value,
    );
    if (scale.isNotEmpty) {
      setUiScale(model, scale.first);
    }
  }

  static String getCustomCpuName(ConfigModel model) {
    final items = model.nvram.nvramAdd
        .addList?[ConfigNvram.UUID_4D1FDA02_38C7_4A6A_9CC6_4BCCA8B30102];
    final item = items?.firstWhere(
      (item) => item.key == ConfigNvram.revcpuname.key,
      orElse: () => NvramAddItem(key: '', dataType: '', value: ''),
    );
    return item?.value?.toString() ?? '';
  }

  static void setCustomCpuName(ConfigModel model, String cpuName) {
    final items = _items(
      model,
      ConfigNvram.UUID_4D1FDA02_38C7_4A6A_9CC6_4BCCA8B30102,
    );
    items.removeWhere((item) => item.key == ConfigNvram.revcpuname.key);
    if (cpuName.isNotEmpty) {
      items.add(ConfigNvram.revcpuname.copyWith(value: cpuName));
    }
  }

  static NvramAddItem _item(
    ConfigModel model,
    String guid,
    NvramAddItem template,
  ) {
    final addList = model.nvram.nvramAdd.addList ??= {};
    final items = addList[guid] ??= [];
    final existing = items.firstWhere(
      (item) => item.key == template.key,
      orElse: () => template.copyWith(),
    );
    if (!items.contains(existing)) {
      items.add(existing);
    }
    return existing;
  }

  static NvramAddItem? _findItem(
    ConfigModel model,
    String guid,
    NvramAddItem template,
  ) {
    final items = model.nvram.nvramAdd.addList?[guid];
    if (items == null) return null;
    for (final item in items) {
      if (item.key == template.key) {
        return item;
      }
    }
    return null;
  }

  static List<NvramAddItem> _items(ConfigModel model, String guid) {
    final addList = model.nvram.nvramAdd.addList ??= {};
    return addList[guid] ??= [];
  }

  static void _removeItems(ConfigModel model, String guid, String? key) {
    if (key == null) return;
    model.nvram.nvramAdd.addList?[guid]?.removeWhere((item) => item.key == key);
  }
}

extension NvramSettingsConfigAccess on ConfigModel {
  UIScale get uiScale => NvramSettingsAccessor.getUiScale(this);
  set uiScale(UIScale value) => NvramSettingsAccessor.setUiScale(this, value);

  CsrSetting get csrsetting => NvramSettingsAccessor.getCsrSetting(this);
  set csrsetting(CsrSetting value) =>
      NvramSettingsAccessor.setCsrSetting(this, value);
}
