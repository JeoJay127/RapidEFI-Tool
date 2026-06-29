import 'enum_meta.dart';
import 'enum_codec.dart';

enum Brand {
  none(
    text: EnumText(
      title: '',
    ),
  ),
  asus(
    text: EnumText(
      title: '华硕',
      description: 'ASUS',
    ),
  ),
  gigabyte(
    text: EnumText(
      title: '技嘉',
      description: 'GIGABYTE',
    ),
  ),
  asrock(
    text: EnumText(
      title: '华擎',
      description: 'ASRock',
    ),
  ),
  msi(
    text: EnumText(
      title: '微星',
      description: 'MSI',
    ),
  ),
  dell(
    text: EnumText(
      title: '戴尔',
      description: 'Dell',
    ),
  ),
  vaio(
    text: EnumText(
      title: '索尼',
      description: 'VAIO',
    ),
  ),
  hp(
    text: EnumText(
      title: '惠普',
      description: 'HP',
    ),
  ),
  chrome(
    text: EnumText(
      title: '谷歌',
      description: 'Chromebook',
    ),
  ),
  microsoft(
    text: EnumText(
      title: '微软',
      description: 'Microsoft Surface',
    ),
  );

  const Brand({
    required this.text,
  });

  final EnumText text;

  String get value {
    if (text.title.isEmpty) return '';
    if (text.description.isEmpty) return text.title;
    return '${text.title}(${text.description})';
  }

  static Brand fromJson(Object? raw) {
    return EnumCodec.decode(
      raw,
      values,
      fallback: Brand.none,
      ignoreCase: true,
      aliases: {
        'nil': Brand.none,
        'Brand.nil': Brand.none,
        'none': Brand.none,
        'Brand.none': Brand.none,
        'Brand.asus': Brand.asus,
        'Brand.Gigabyte': Brand.gigabyte,
        'Gigabyte': Brand.gigabyte,
        'Brand.AsRock': Brand.asrock,
        'AsRock': Brand.asrock,
        'Brand.msi': Brand.msi,
        'Brand.dell': Brand.dell,
        'Brand.vaio': Brand.vaio,
        'Brand.hp': Brand.hp,
        'Brand.chrome': Brand.chrome,
        'Brand.Microsoft': Brand.microsoft,
        'Microsoft': Brand.microsoft,
        '华硕(ASUS)': Brand.asus,
        '技嘉(GIGABYTE)': Brand.gigabyte,
        '华擎(ASRock)': Brand.asrock,
        '微星(MSI)': Brand.msi,
        '戴尔(Dell)': Brand.dell,
        '索尼(VAIO)': Brand.vaio,
        '惠普(HP)': Brand.hp,
        '谷歌(Chromebook)': Brand.chrome,
        '微软(Microsoft Surface)': Brand.microsoft,
      },
    );
  }

  String toJson() => EnumCodec.encode(this);
}
