import 'enum_meta.dart';
import 'enum_codec.dart';

enum ProcessorType {
  none(
    value: 0,
    text: EnumText(
      title: '不修改 ProcessorType',
      description: '保持系统默认 CPU 类型显示',
    ),
  ),
  type1537(
    value: 1537,
    text: EnumText(
      title: 'ProcessorType: 1537',
      description: 'Intel 及 AMD 平台 CPU 名称修改方案一(通常适用于 6 核心及以下 CPU)',
    ),
  ),
  type3841(
    value: 3841,
    text: EnumText(
      title: 'ProcessorType: 3841',
      description: 'Intel 及 AMD 平台 CPU 名称修改方案二(通常适用于 8 核心及以上 CPU)',
    ),
  ),
  type3842(
    value: 3842,
    text: EnumText(
      title: 'ProcessorType: 3842',
      description: 'Intel 及 AMD 平台 CPU 名称修改备选方案(通常适用于 8 核心及以上 i7、i9 系列 CPU)',
    ),
  );

  const ProcessorType({
    required this.value,
    required this.text,
  });

  final int value;
  final EnumText text;

  static ProcessorType fromJson(Object? raw) {
    return EnumCodec.decode(
      raw,
      values,
      fallback: ProcessorType.none,
      ignoreCase: true,
      aliases: {
        'nil': ProcessorType.none,
        'ProcessorType.nil': ProcessorType.none,
        'Type1537': ProcessorType.type1537,
        'ProcessorType.Type1537': ProcessorType.type1537,
        'Type3841': ProcessorType.type3841,
        'ProcessorType.Type3841': ProcessorType.type3841,
        'Type3842': ProcessorType.type3842,
        'ProcessorType.Type3842': ProcessorType.type3842,
      },
    );
  }

  String toJson() => EnumCodec.encode(this);
}
