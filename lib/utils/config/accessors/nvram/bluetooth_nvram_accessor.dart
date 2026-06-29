import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/accessors/nvram/nvram_accessor.dart';
import 'package:rapidefi/utils/config/catalogs/bluetooth_nvram/bluetooth_nvram_option.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_add_item.dart';

class BluetoothNvramAccessor {
  BluetoothNvramAccessor._();

  static const key = 'bluetoothInternalControllerInfo';

  static BluetoothNvramOption? selectedOption(
    ConfigModel model,
    List<BluetoothNvramOption> options,
  ) {
    final item = NvramAccessor.getAppleBootItem(model, key);
    if (item == null) return null;
    for (final option in options) {
      if (option.value.toLowerCase() == item.value?.toLowerCase()) {
        return option;
      }
    }
    return null;
  }

  static void setOption(
    ConfigModel model,
    BluetoothNvramOption option,
  ) {
    NvramAccessor.setAppleBootItem(
      model,
      ConfigNvram.bluetoothExternalDongleFailed.copyWith(),
    );
    NvramAccessor.setAppleBootItem(
      model,
      NvramAddItem(
        key: option.key,
        dataType: option.dataType,
        value: option.value,
        comment: option.comment,
      ),
    );
  }

  static void removeOption(ConfigModel model) {
    NvramAccessor.removeAppleBootItem(model, key);
    NvramAccessor.removeAppleBootItem(
      model,
      ConfigNvram.bluetoothExternalDongleFailed.key ?? '',
    );
  }
}
