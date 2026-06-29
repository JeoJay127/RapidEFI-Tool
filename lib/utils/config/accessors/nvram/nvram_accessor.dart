import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_add_item.dart';

class NvramAccessor {
  NvramAccessor._();

  static const appleBootGuid =
      ConfigNvram.UUID_7C436110_AB2A_4BBB_A880_FE41995C9F82;

  static NvramAddItem? getItem(
    ConfigModel model,
    String guid,
    String key,
  ) {
    final items = model.nvram.nvramAdd.addList?[guid];
    if (items == null) return null;
    for (final item in items) {
      if (item.key == key) {
        return item;
      }
    }
    return null;
  }

  static void setItem(
    ConfigModel model,
    String guid,
    NvramAddItem item,
  ) {
    final addList = model.nvram.nvramAdd.addList ??= {};
    final items = addList[guid] ??= [];
    items.removeWhere((entry) => entry.key == item.key);
    items.add(item);
  }

  static void removeItem(
    ConfigModel model,
    String guid,
    String key,
  ) {
    model.nvram.nvramAdd.addList?[guid]?.removeWhere(
      (item) => item.key == key,
    );
  }

  static NvramAddItem? getAppleBootItem(ConfigModel model, String key) {
    return getItem(model, appleBootGuid, key);
  }

  static void setAppleBootItem(ConfigModel model, NvramAddItem item) {
    setItem(model, appleBootGuid, item);
  }

  static void removeAppleBootItem(ConfigModel model, String key) {
    removeItem(model, appleBootGuid, key);
  }
}
