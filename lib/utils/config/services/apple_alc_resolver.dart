import 'package:rapidefi/utils/config/catalogs/applealc/applealc_option.dart';
import 'package:rapidefi/utils/config/catalogs/applealc/appleallc_catallog_loader.dart';

class AppleALCResolver {
  AppleALCResolver._();

  static bool _initialized = false;

  static AppleALCOption? _option;

  /// 扁平查询缓存：
  static final Map<String, List<int>> _layoutCache = {};

  static List<Map<String, List<int>>>? _codecDataCache;
  /// 级联查询缓存
  static List<Map<String, List<Map<String, List<int>>>>>? _pickerDataCache;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _layoutCache.clear();
    _codecDataCache = null;
    _pickerDataCache = null;

    _option = await AppleALCCodecCatalogLoader.load();
    final vendors = _option!.vendors;

    for (final vendor in vendors) {
      for (final codec in vendor.codecs) {
        final key = normalizeCodecName(codec.name);
        if (key.isEmpty) {
          continue;
        }

        _layoutCache[key] = List<int>.unmodifiable(codec.layoutIds);
      }
    }

    _pickerDataCache = vendors.map((vendor) {
      return {
        vendor.name: vendor.codecs.map((codec) {
          return {
            codec.name: List<int>.unmodifiable(codec.layoutIds),
          };
        }).toList(growable: false),
      };
    }).toList(growable: false);

    _initialized = true;
  }

  static String get version {
    _ensureInitialized();
    return _option?.version ?? '';
  }

  static String get published {
    _ensureInitialized();
    return _option?.published ?? '';
  }

  /// 扁平数据。
  static List<Map<String, List<int>>> loadCodecData() {
    _ensureInitialized();

    if (_codecDataCache != null) {
      return _codecDataCache!;
    }

    _codecDataCache = _layoutCache.entries.map((entry) {
      return {
        entry.key: List<int>.unmodifiable(entry.value),
      };
    }).toList(growable: false);

    return _codecDataCache!;
  }

  static List<Map<String, List<Map<String, List<int>>>>> loadPickerData() {
    _ensureInitialized();

    final pickerData = _pickerDataCache;

    if (pickerData == null) {
      throw StateError(
        'AppleALC picker cache is empty. '
        'Please call await AppleALCResolver.initialize() before loadPickerData().',
      );
    }

    return pickerData;
  }

  static List<int> findLayoutsByModelSync(String model) {
    _ensureInitialized();

    final codecName = extractCodecName(model);

    if (codecName == null) {
      return const [];
    }

    return findLayoutsByCodecSync(codecName);
  }

  static List<int> findLayoutsByCodecSync(String codecName) {
    _ensureInitialized();

    final normalized = normalizeCodecName(codecName);

    if (normalized.isEmpty) {
      return const [];
    }

    return _layoutCache[normalized] ?? const [];
  }

  static Future<List<int>> findLayoutsByModel(String model) async {
    await initialize();
    return findLayoutsByModelSync(model);
  }

  static Future<List<int>> findLayoutsByCodec(String codecName) async {
    await initialize();
    return findLayoutsByCodecSync(codecName);
  }

  static String? extractCodecName(String model) {
    final normalized = model.trim().toUpperCase();

    if (normalized.isEmpty) {
      return null;
    }

    final match = RegExp(
      r'\b(ALC[A-Z0-9]+|ALCS[A-Z0-9]+|AD[0-9A-Z]+|CA[0-9A-Z]+|CS[0-9A-Z]+|CX[0-9A-Z]+|IDT[0-9A-Z/]+|VT[0-9A-Z]+|STAC[0-9A-Z]+)\b',
      caseSensitive: false,
    ).firstMatch(normalized);

    return match?.group(1)?.toUpperCase();
  }

  static String normalizeCodecName(String codecName) {
    return codecName.trim().toUpperCase();
  }

  static List<int> findAlcidPosition(int alcid) {
    final data = loadPickerData();

    for (var v = 0; v < data.length; v++) {
      final vendorMap = data[v];

      if (vendorMap.isEmpty) {
        continue;
      }

      final codecs = vendorMap.values.first;

      for (var c = 0; c < codecs.length; c++) {
        final codecMap = codecs[c];

        if (codecMap.isEmpty) {
          continue;
        }

        final layouts = codecMap.values.first;

        for (var l = 0; l < layouts.length; l++) {
          if (layouts[l] == alcid) {
            return [v, c, l];
          }
        }
      }
    }

    return const [0, 0, 0];
  }

  static List<int> findAlcidPositionBySelection(
    List<Object>? selection,
    int fallbackAlcid,
  ) {
    if (selection == null || selection.length != 3) {
      return findAlcidPosition(fallbackAlcid);
    }

    final vendorName = selection[0];
    final codecName = selection[1];
    final layoutId = selection[2];
    if (vendorName is! String || codecName is! String || layoutId is! int) {
      return findAlcidPosition(fallbackAlcid);
    }

    final data = loadPickerData();
    for (var v = 0; v < data.length; v++) {
      final vendorMap = data[v];
      if (!vendorMap.containsKey(vendorName)) {
        continue;
      }

      final codecs = vendorMap[vendorName]!;
      for (var c = 0; c < codecs.length; c++) {
        final codecMap = codecs[c];
        if (!codecMap.containsKey(codecName)) {
          continue;
        }

        final layouts = codecMap[codecName]!;
        final layoutIndex = layouts.indexOf(layoutId);
        if (layoutIndex >= 0) {
          return [v, c, layoutIndex];
        }
      }
    }

    return findAlcidPosition(fallbackAlcid);
  }

  static List<Object>? selectionFromPickerValues(List values) {
    if (values.length != 3) {
      return null;
    }

    final vendorName = values[0]?.toString();
    final codecName = values[1]?.toString();
    final layoutId = int.tryParse(values[2].toString());
    if (vendorName == null || codecName == null || layoutId == null) {
      return null;
    }

    return [vendorName, codecName, layoutId];
  }

  static List<Object>? selectionForModelLayout(String model, int layoutId) {
    final codecName = extractCodecName(model);
    if (codecName == null) {
      return null;
    }

    final normalizedCodec = normalizeCodecName(codecName);
    final data = loadPickerData();

    for (final vendorMap in data) {
      for (final vendorEntry in vendorMap.entries) {
        for (final codecMap in vendorEntry.value) {
          for (final codecEntry in codecMap.entries) {
            if (normalizeCodecName(codecEntry.key) != normalizedCodec) {
              continue;
            }
            if (!codecEntry.value.contains(layoutId)) {
              continue;
            }

            return [vendorEntry.key, codecEntry.key, layoutId];
          }
        }
      }
    }

    return null;
  }

  static void clearCache() {
    _initialized = false;
    _layoutCache.clear();
    _codecDataCache = null;
    _pickerDataCache = null;
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'AppleALCResolver is not initialized. '
        'Please call await AppleALCResolver.initialize() first.',
      );
    }
  }
}
