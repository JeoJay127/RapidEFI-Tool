import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/enums/processor_type_enum.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi_generic.dart';

class PlatformInfoAccessor {
  PlatformInfoAccessor._();

  static const int defaultProcessorTypeValue = 0;

  static PlatformInfoGeneric ensureGeneric(ConfigModel model) {
    return model.platformInfo.generic ??= PlatformInfoGeneric();
  }

  /// 读取真实结构：

  static int _getProcessorTypeValue(ConfigModel model) {
    return model.platformInfo.generic?.processorType ??
        defaultProcessorTypeValue;
  }

  /// 写入真实结构：

  static void _setProcessorTypeValue(ConfigModel model, int value) {
    ensureGeneric(model).processorType = value;
  }

  static ProcessorType getProcessorType(ConfigModel model) {
    final value = _getProcessorTypeValue(model);

    return ProcessorType.values.firstWhere(
      (item) => item.value == value,
      orElse: () => ProcessorType.none,
    );
  }

  static void setProcessorType(ConfigModel model, ProcessorType value) {
    _setProcessorTypeValue(model, value.value);
  }
}

extension PlatformInfoConfigAccess on ConfigModel {
  ProcessorType get processorType =>
      PlatformInfoAccessor.getProcessorType(this);
  set processorType(ProcessorType value) =>
      PlatformInfoAccessor.setProcessorType(this, value);
}
