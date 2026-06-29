import 'package:rapidefi/utils/config/accessors/amd_settings_accessor.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/misc/misc.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_add.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_delete.dart';
import 'package:rapidefi/utils/config/presets/sections/config_misc.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';

mixin AmdConfigBase {
  static Misc commonMisc() {
    return Misc(
      miscBoot: ConfigMisc.commonMiscBoot.copyWith(),
      miscSecurity: ConfigMisc.commonMiscSecurity.copyWith(),
      miscToolsItems: ConfigMisc.commoMiscToolsItems
          .map((item) => item.copyWith())
          .toList(),
    );
  }

  static NVRAM commonNvram() {
    return NVRAM(
      nvramAdd: NvramAdd(
        addList: ConfigNvram.createAddList(),
      ),
      nvramDelete: NvramDelete(
        deleteList: ConfigNvram.createDeleteList(),
      ),
    );
  }

  static void applyAmdDefaults(
    ConfigModel model, {
    required String core,
    bool useRyzenGpu = false,
  }) {
    AmdSettingsAccessor.setAmdCore(model, core);
    AmdSettingsAccessor.setUsesRyzenGpu(model, useRyzenGpu);
  }
}
