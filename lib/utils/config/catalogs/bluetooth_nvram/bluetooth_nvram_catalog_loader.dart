import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'bluetooth_nvram_option.dart';

class BluetoothNvramCatalogLoader {
  static Map<String, List<BluetoothNvramOption>>? _cached;

  BluetoothNvramCatalogLoader._();

  static Future<Map<String, List<BluetoothNvramOption>>> load({
    bool forceReload = false,
  }) async {
    if (_cached != null && !forceReload) {
      return _cached!;
    }
    final jsonString =
        await rootBundle.loadString('assets/data/bluetooth_nvram_catalog.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    _cached = json.map((key, value) {
      final options = value is List<dynamic>
          ? value
              .whereType<Map<String, dynamic>>()
              .map(BluetoothNvramOption.fromJson)
              .toList()
          : <BluetoothNvramOption>[];
      return MapEntry(key, options);
    });
    return _cached!;
  }
}
