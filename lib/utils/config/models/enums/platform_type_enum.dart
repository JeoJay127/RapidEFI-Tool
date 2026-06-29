import 'enum_meta.dart';
import 'enum_codec.dart';

enum PlatformType {
  desktop(
    text: EnumText(
      title: '台式机',
    ),
  ),
  laptop(
    text: EnumText(
      title: '笔记本',
    ),
  ),
  nuc(
    text: EnumText(
      title: '迷你主机',
    ),
  ),
  hedt(
    text: EnumText(
      title: '服务器',
    ),
  );

  const PlatformType({
    required this.text,
  });

  final EnumText text;

  String get value => text.title;

  static PlatformType fromJson(Object? raw) {
    return EnumCodec.decode(
      raw,
      values,
      fallback: PlatformType.desktop,
      ignoreCase: true,
    );
  }

  String toJson() => EnumCodec.encode(this);
}
