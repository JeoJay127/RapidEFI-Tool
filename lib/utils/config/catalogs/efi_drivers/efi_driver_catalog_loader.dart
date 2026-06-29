import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'efi_driver_option.dart';

class EfiDriverCatalogLoader {
  static List<EfiDriverOption>? _cached;

  EfiDriverCatalogLoader._();

  static Future<List<EfiDriverOption>> load({bool forceReload = false}) async {
    if (_cached != null && !forceReload) {
      return _cached!;
    }
    final jsonString =
        await rootBundle.loadString('assets/data/efi_driver_catalog.json');
    final json = jsonDecode(jsonString);
    final list = json is List<dynamic>
        ? json
        : (json as Map<String, dynamic>).values.expand((value) {
            return value is List<dynamic> ? value : const <dynamic>[];
          }).toList();
    _cached = list
        .whereType<Map<String, dynamic>>()
        .map(EfiDriverOption.fromJson)
        .toList();
    return _cached!;
  }
}
