class AppleALCOption {
  final String name;
  final String version;
  final String repo;
  final String author;
  final String published;
  final List<AppleALCVendor> vendors;

  const AppleALCOption({
    this.name = '',
    this.version = '',
    this.repo = '',
    this.author = '',
    this.published = '',
    this.vendors = const [],
  });

  factory AppleALCOption.fromJson(Map<String, dynamic> json) {
    return AppleALCOption(
      name: json['name']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      repo: json['repo']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      published: json['published']?.toString() ?? '',
      vendors: _parseVendors(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'repo': repo,
      'author': author,
      'published': published,
      'data': vendors.map((e) => e.toJson()).toList(),
    };
  }

  AppleALCOption copyWith({
    String? name,
    String? version,
    String? repo,
    String? author,
    String? published,
    List<AppleALCVendor>? vendors,
  }) {
    return AppleALCOption(
      name: name ?? this.name,
      version: version ?? this.version,
      repo: repo ?? this.repo,
      author: author ?? this.author,
      published: published ?? this.published,
      vendors: vendors ?? this.vendors,
    );
  }

  List<AppleALCCodec> get allCodecs {
    return vendors.expand((vendor) => vendor.codecs).toList();
  }

  AppleALCCodec? findCodec(String name) {
    final target = name.trim().toUpperCase();

    for (final codec in allCodecs) {
      if (codec.name.toUpperCase() == target) {
        return codec;
      }
    }

    return null;
  }

  List<int> layoutIdsFor(String codecName) {
    return findCodec(codecName)?.layoutIds ?? const [];
  }

  static List<AppleALCVendor> _parseVendors(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final result = <AppleALCVendor>[];

    for (final item in value) {
      if (item is! Map) {
        continue;
      }

      item.forEach((vendorName, codecList) {
        result.add(
          AppleALCVendor(
            name: vendorName.toString(),
            codecs: AppleALCVendor.parseCodecs(codecList),
          ),
        );
      });
    }

    return result;
  }
}

class AppleALCVendor {
  final String name;
  final List<AppleALCCodec> codecs;

  const AppleALCVendor({
    this.name = '',
    this.codecs = const [],
  });

  factory AppleALCVendor.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return const AppleALCVendor();
    }

    final entry = json.entries.first;

    return AppleALCVendor(
      name: entry.key,
      codecs: parseCodecs(entry.value),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      name: codecs.map((e) => e.toJson()).toList(),
    };
  }

  AppleALCVendor copyWith({
    String? name,
    List<AppleALCCodec>? codecs,
  }) {
    return AppleALCVendor(
      name: name ?? this.name,
      codecs: codecs ?? this.codecs,
    );
  }

  static List<AppleALCCodec> parseCodecs(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final result = <AppleALCCodec>[];

    for (final item in value) {
      if (item is! Map) {
        continue;
      }

      item.forEach((codecName, layoutIds) {
        result.add(
          AppleALCCodec(
            name: codecName.toString(),
            layoutIds: _toIntList(layoutIds),
          ),
        );
      });
    }

    return result;
  }
}

class AppleALCCodec {
  final String name;
  final List<int> layoutIds;

  const AppleALCCodec({
    this.name = '',
    this.layoutIds = const [],
  });

  factory AppleALCCodec.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return const AppleALCCodec();
    }

    final entry = json.entries.first;

    return AppleALCCodec(
      name: entry.key,
      layoutIds: _toIntList(entry.value),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      name: layoutIds,
    };
  }

  AppleALCCodec copyWith({
    String? name,
    List<int>? layoutIds,
  }) {
    return AppleALCCodec(
      name: name ?? this.name,
      layoutIds: layoutIds ?? this.layoutIds,
    );
  }
}

List<int> _toIntList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((e) {
        if (e is int) return e;
        if (e is num) return e.toInt();
        return int.tryParse(e.toString());
      })
      .whereType<int>()
      .toList();
}
