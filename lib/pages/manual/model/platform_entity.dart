class PlatformEntity {
  final String architecture;
  final String socket;
  final int generation;
  final String year;
  final bool legacy;
  final List<String> motherboard;
  final String initialSupport;
  final String lastSupported;
  final String oclpSupported;
  final List<String> note;
  final PlatformConfig config;

  const PlatformEntity({
    this.architecture = '',
    this.socket = '',
    this.generation = 0,
    this.year = '',
    this.legacy = false,
    this.motherboard = const [],
    this.initialSupport = '',
    this.lastSupported = '',
    this.oclpSupported = '',
    this.note = const [],
    this.config = const PlatformConfig(),
  });

  factory PlatformEntity.fromJson(Map<String, dynamic> json) {
    return PlatformEntity(
      architecture: json['architecture']?.toString() ?? '',
      socket: json['socket']?.toString() ?? '',
      generation: _toInt(json['generation']),
      year: json['year']?.toString() ?? '',
      legacy: json['legacy'] == true,
      motherboard: _toStringList(json['motherboard']),
      initialSupport: json['initial_support']?.toString() ?? '',
      lastSupported: json['last_supported']?.toString() ?? '',
      oclpSupported: json['oclp_supported']?.toString() ?? '',
      note: _toStringList(json['note']),
      config: json['config'] is Map<String, dynamic>
          ? PlatformConfig.fromJson(json['config'] as Map<String, dynamic>)
          : const PlatformConfig(),
    );
  }

}

class PlatformConfig {
  final String refer;
  final PlatformBiosConfig bios;

  const PlatformConfig({
    this.refer = '',
    this.bios = const PlatformBiosConfig(),
  });

  factory PlatformConfig.fromJson(Map<String, dynamic> json) {
    return PlatformConfig(
      refer: json['refer']?.toString() ?? '',
      bios: json['bios'] is Map<String, dynamic>
          ? PlatformBiosConfig.fromJson(json['bios'] as Map<String, dynamic>)
          : const PlatformBiosConfig(),
    );
  }
}

class PlatformBiosConfig {
  final PlatformBiosOption disable;
  final PlatformBiosOption enable;
  final List<String> custom;

  const PlatformBiosConfig({
    this.disable = const PlatformBiosOption(),
    this.enable = const PlatformBiosOption(),
    this.custom = const [],
  });

  factory PlatformBiosConfig.fromJson(Map<String, dynamic> json) {
    return PlatformBiosConfig(
      disable: json['disable'] is Map<String, dynamic>
          ? PlatformBiosOption.fromJson(json['disable'] as Map<String, dynamic>)
          : const PlatformBiosOption(),
      enable: json['enable'] is Map<String, dynamic>
          ? PlatformBiosOption.fromJson(json['enable'] as Map<String, dynamic>)
          : const PlatformBiosOption(),
      custom: _toStringList(json['custom']),
    );
  }
}

class PlatformBiosOption {
  final List<String> en;
  final List<String> ch;

  const PlatformBiosOption({
    this.en = const [],
    this.ch = const [],
  });

  factory PlatformBiosOption.fromJson(Map<String, dynamic> json) {
    return PlatformBiosOption(
      en: _toStringList(json['en']),
      ch: _toStringList(json['ch']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const [];
}
