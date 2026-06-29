import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/nvram/boot_arg_model.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_add_item.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';

class BootArgsAccessor {
  BootArgsAccessor._();

  static String getBootArgs(ConfigModel model) =>
      _bootArgsItem(model).value ?? '';

  static List<String> getBootArgList(ConfigModel model) {
    return getBootArgs(model)
        .split(RegExp(r'\s+'))
        .where((arg) => arg.trim().isNotEmpty)
        .toList();
  }

  static void setBootArgs(ConfigModel model, Iterable<String> args) {
    _setBootArgList(model, args);
  }

  static bool contains(ConfigModel model, String arg) {
    final args = _splitArgs(arg);
    if (args.isEmpty) return false;

    final bootArgs = getBootArgList(model);
    return args.every(bootArgs.contains);
  }

  static bool containsPrefix(ConfigModel model, String prefix) {
    return getBootArgList(model).any((arg) => arg.startsWith(prefix));
  }

  static void add(ConfigModel model, String arg) {
    final args = _splitArgs(arg);
    if (args.isEmpty || contains(model, arg)) return;

    _setBootArgList(model, [...getBootArgList(model), ...args]);
  }

  static void remove(ConfigModel model, String arg) {
    final args = _splitArgs(arg).toSet();
    if (args.isEmpty) return;

    removeWhere(model, args.contains);
  }

  static void removeWhere(ConfigModel model, bool Function(String arg) test) {
    _setBootArgList(model, getBootArgList(model).where((arg) => !test(arg)));
  }

  static void replaceByPrefix(ConfigModel model, String prefix, String newArg) {
    removeWhere(model, (arg) => arg.startsWith(prefix));
    add(model, newArg);
  }

  static int? getAlcid(ConfigModel model) {
    for (final arg in getBootArgList(model)) {
      if (arg.startsWith('alcid=')) {
        return int.tryParse(arg.substring('alcid='.length));
      }
    }
    return null;
  }

  static void setAlcid(ConfigModel model, int alcid) {
    replaceByPrefix(model, 'alcid=', 'alcid=$alcid');
  }

  static void _setBootArgList(ConfigModel model, Iterable<String> args) {
    final normalized = <String>[];
    for (final arg in args) {
      for (final item in _splitArgs(arg)) {
        if (!normalized.contains(item)) {
          normalized.add(item);
        }
      }
    }
    _bootArgsItem(model).value = normalized.join(' ');
  }

  static List<String> _splitArgs(String args) {
    return args
        .split(RegExp(r'\s+'))
        .where((arg) => arg.trim().isNotEmpty)
        .toList();
  }

  static NvramAddItem _bootArgsItem(ConfigModel model) {
    final addList = model.nvram.nvramAdd.addList ??= {};
    final guid = ConfigNvram.UUID_7C436110_AB2A_4BBB_A880_FE41995C9F82;
    final items = addList[guid] ??= [];
    final existing = items.firstWhere(
      (item) => item.key == ConfigNvram.boot_args.key,
      orElse: () => ConfigNvram.boot_args.copyWith(),
    );
    if (!items.contains(existing)) {
      items.add(existing);
    }
    return existing;
  }
}

extension BootArgsConfigAccess on ConfigModel {
  Set<BootArgModel> get bootArgModels {
    return ConfigNvram.bootArgModels
        .where((item) => BootArgsAccessor.contains(this, item.arg))
        .toSet();
  }

  set bootArgModels(Set<BootArgModel> value) {
    BootArgsAccessor.setBootArgs(this, value.map((item) => item.arg));
  }
}
