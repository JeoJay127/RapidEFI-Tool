import 'dart:convert';

import 'package:flutter/services.dart';

import 'applealc_option.dart';

class AppleALCCodecCatalogLoader {
  AppleALCCodecCatalogLoader._();

  static AppleALCOption? _cached;

  static Future<AppleALCOption> load({
    bool forceReload = false,
  }) async {
    if (_cached != null && !forceReload) {
      return _cached!;
    }

    final jsonString = await rootBundle.loadString(
      'assets/data/alc_codec.json',
    );

    final json = jsonDecode(jsonString);

    if (json is! Map<String, dynamic>) {
      throw const FormatException(
        'alc_codec.json 格式错误：根节点必须是 Map<String, dynamic>',
      );
    }

    _cached = AppleALCOption.fromJson(json);
    return _cached!;
  }

  static Future<List<AppleALCVendor>> loadVendors({
    bool forceReload = false,
  }) async {
    final option = await load(forceReload: forceReload);
    return option.vendors;
  }

  static Future<List<AppleALCCodec>> loadCodecs({
    bool forceReload = false,
  }) async {
    final option = await load(forceReload: forceReload);
    return option.allCodecs;
  }

  static Future<AppleALCCodec?> findCodec(
    String codecName, {
    bool forceReload = false,
  }) async {
    final option = await load(forceReload: forceReload);
    return option.findCodec(codecName);
  }

  static Future<List<int>> layoutIdsFor(
    String codecName, {
    bool forceReload = false,
  }) async {
    final option = await load(forceReload: forceReload);
    return option.layoutIdsFor(codecName);
  }

  static Future<Map<String, List<AppleALCCodec>>> loadCatalogByVendor({
    bool forceReload = false,
  }) async {
    final option = await load(forceReload: forceReload);

    return {
      for (final vendor in option.vendors) vendor.name: vendor.codecs,
    };
  }

  static void clearCache() {
    _cached = null;
  }
}
