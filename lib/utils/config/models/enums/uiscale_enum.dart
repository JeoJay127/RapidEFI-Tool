import 'enum_meta.dart';
import 'enum_codec.dart';

enum UIScale {
  scale00(
    nvramValue: '00',
    text: EnumText(
      title: '',
      description: '自适应显示器,根据显示器分辨率自动调整 OpenCore 引导界面的显示比例',
    ),
  ),
  scale01(
    nvramValue: '01',
    text: EnumText(
      title: '',
      description: '标准分辨率显示器,适用于 720p、1080p、1440p 等标准分辨率显示器',
    ),
  ),
  scale02(
    nvramValue: '02',
    text: EnumText(
      title: '',
      description: '高分辨率显示器,适用于 4K、5K 等高分辨率显示器(可以有效改善高分屏OpenCore引导页面UI元素过小的问题)',
    ),
  );

  const UIScale({
    required this.nvramValue,
    required this.text,
  });

  final String nvramValue;
  final EnumText text;

  static UIScale fromJson(Object? raw) {
    return EnumCodec.decode(
      raw,
      values,
      fallback: UIScale.scale00,
      ignoreCase: true,
      aliases: {
        '0': UIScale.scale00,
        '00': UIScale.scale00,
        'UIScale00': UIScale.scale00,
        '1': UIScale.scale01,
        '01': UIScale.scale01,
        'UIScale01': UIScale.scale01,
        'UIScale.scale01': UIScale.scale01,
        '2': UIScale.scale02,
        '02': UIScale.scale02,
        'UIScale02': UIScale.scale02,
        'UIScale.scale02': UIScale.scale02,
      },
    );
  }

  String toJson() => EnumCodec.encode(this);
}
