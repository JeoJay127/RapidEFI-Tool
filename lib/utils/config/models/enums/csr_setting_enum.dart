import 'enum_meta.dart';
import 'enum_codec.dart';

enum CsrSetting {
  none(
    nvramValue: '',
    text: EnumText(
      title: '',
    ),
  ),
  enabled(
    nvramValue: '00000000',
    text: EnumText(
      title: '开启SIP增强系统安全性,通常不需要使用OCLP打显卡，WiFi等驱动时,推荐勾选',
    ),
  ),
  partialDisabled(
    nvramValue: '03080000',
    text: EnumText(
      title: '禁用SIP方案一',
      description: '非彻底禁用SIP,通常在BigSur等以上系统需要使用OCLP打显卡,WiFi等驱动时,建议勾选',
    ),
  ),
  fullyDisabled(
    nvramValue: 'FF0F0000',
    text: EnumText(
      title: '禁用SIP方案二',
      description: '彻底禁用SIP,通常在BigSur等以上系统需要使用OCLP打显卡,WiFi等驱动时,优先选择此项',
    ),
  );

  const CsrSetting({
    required this.nvramValue,
    required this.text,
  });

  final String nvramValue;
  final EnumText text;

  String get value {
    if (this == CsrSetting.none) return '';

    if (text.description.isEmpty) {
      return text.title;
    }

    if (text.description.isEmpty) {
      return text.title;
    }

    return '${text.title}(${text.description})';
  }

  bool get needsAmfiBypass {
    return this == CsrSetting.partialDisabled ||
        this == CsrSetting.fullyDisabled;
  }

  static CsrSetting fromJson(Object? raw) {
    return EnumCodec.decode(
      raw,
      values,
      fallback: CsrSetting.none,
      ignoreCase: true,
      aliases: {
        'CsrSetting.none': CsrSetting.none,
        'CSRSETTING.nil': CsrSetting.none,
        'nil': CsrSetting.none,
        'CsrSetting.enabled': CsrSetting.enabled,
        'CSRSETTING.CSR00000000': CsrSetting.enabled,
        'CSR00000000': CsrSetting.enabled,
        'CsrSetting.partialDisabled': CsrSetting.partialDisabled,
        'CSRSETTING.CSR03080000': CsrSetting.partialDisabled,
        'CSR03080000': CsrSetting.partialDisabled,
        'CsrSetting.fullyDisabled': CsrSetting.fullyDisabled,
        'CSRSETTING.CSRFF0F0000': CsrSetting.fullyDisabled,
        'CSRFF0F0000': CsrSetting.fullyDisabled,
      },
    );
  }

  String toJson() => EnumCodec.encode(this);
}
