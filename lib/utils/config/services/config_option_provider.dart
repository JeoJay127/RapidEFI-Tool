import 'package:flutter/foundation.dart';
import 'package:rapidefi/utils/config/accessors/nvram/boot_args_accessor.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/models/nvram/boot_arg_model.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/services/config_model_editor.dart';
import 'package:rapidefi/utils/config/services/config_service.dart';
import 'package:rapidefi/utils/config/services/config_session.dart';

class ConfigOptionProvider extends ChangeNotifier {
  final ConfigService _configService = ConfigService();
  late final ConfigModelEditor _editor = ConfigModelEditor(_configService);

  Set<BootArgModel> get selectedBootArgs {
    final model = _configService.configModel;
    _configService.normalizeRuntimeConfigModel();
    return ConfigNvram.bootArgModels
        .where((item) => BootArgsAccessor.contains(model, item.arg))
        .toSet();
  }

  List<KernelKext> get selectedKexts => _configService.selectedKexts();

  void updateBootArgs(Set<BootArgModel> selectedBootArgs) {
    updateBootArgsForOptions(ConfigNvram.bootArgModels, selectedBootArgs);
  }

  void updateBootArgsForOptions(
    Iterable<BootArgModel> options,
    Iterable<BootArgModel> selected,
  ) {
    final model = _configService.configModel;
    for (final option in options) {
      BootArgsAccessor.remove(model, option.arg);
    }
    for (final item in selected) {
      BootArgsAccessor.add(model, item.arg);
    }
    _configService.checkpointConfigScope(ConfigScope.bootArgs);
    notifyListeners();
  }

  void updateKexts(
    Iterable<KernelKext> removableKexts,
    Iterable<KernelKext> selectedKexts,
  ) {
    _editor.replaceKexts(removableKexts, selectedKexts);
    notifyListeners();
  }
}
