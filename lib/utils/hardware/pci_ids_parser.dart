import 'dart:convert';

import 'package:flutter/services.dart';

class IdsDeviceEntry {
  final String id;
  final String name;
  final Map<String, String> subsystems;

  IdsDeviceEntry(
      {required this.id, required this.name, Map<String, String>? subsystems})
      : subsystems = subsystems ?? {};
}

class IdsVendorEntry {
  final String id;
  final String name;
  final Map<String, IdsDeviceEntry> devices;

  IdsVendorEntry(
      {required this.id,
      required this.name,
      Map<String, IdsDeviceEntry>? devices})
      : devices = devices ?? {};
}

class IdsParser {
  final Map<String, IdsVendorEntry> _vendors = {};

  Map<String, IdsVendorEntry> get vendors => _vendors;

  static Future<IdsParser> load(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final content =
        utf8.decode(bytes.buffer.asUint8List(), allowMalformed: true);
    return IdsParser._().._parse(content);
  }

  static IdsParser parse(String content) {
    return IdsParser._().._parse(content);
  }

  IdsParser._();

  void _parse(String content) {
    final lines = content.split('\n');
    IdsVendorEntry? currentVendor;
    IdsDeviceEntry? currentDevice;

    for (final line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;

      final indent = _getIndent(line);
      final content = line.substring(_leadingWhitespaceLength(line));
      final parts = _splitLine(content);

      if (indent == 0) {
        if (parts.length < 2 || !_isHexId(parts[0])) continue;
        currentVendor = IdsVendorEntry(
          id: _normalizeShortId(parts[0]),
          name: parts.sublist(1).join(' '),
        );
        _vendors[currentVendor.id] = currentVendor;
        currentDevice = null;
        continue;
      }

      if (indent == 1 && currentVendor != null) {
        if (parts.length >= 2) {
          currentDevice = IdsDeviceEntry(
            id: _normalizeShortId(parts[0]),
            name: parts.sublist(1).join(' '),
          );
          currentVendor.devices[currentDevice.id] = currentDevice;
        }
      } else if (indent >= 2 && currentDevice != null) {
        if (parts.length >= 3) {
          final key =
              '${_normalizeShortId(parts[0])}_${_normalizeShortId(parts[1])}';
          currentDevice.subsystems[key] = parts.sublist(2).join(' ');
        }
      }
    }
  }

  int _getIndent(String line) {
    if (line.startsWith('\t\t')) return 2;
    if (line.startsWith('\t')) return 1;

    final spaces = line.length - line.trimLeft().length;
    if (spaces >= 4) return 2;
    if (spaces > 0) return 1;
    return 0;
  }

  int _leadingWhitespaceLength(String line) {
    var count = 0;
    while (count < line.length && (line[count] == '\t' || line[count] == ' ')) {
      count++;
    }
    return count;
  }

  List<String> _splitLine(String line) {
    return line.trim().split(RegExp(r'\s{2,}'));
  }

  static bool _isHexId(String value) =>
      RegExp(r'^[0-9A-Fa-f]{4}$').hasMatch(value);

  static String _normalizeShortId(String value) {
    final match = RegExp(r'[0-9A-Fa-f]{4}').firstMatch(value.trim());
    return match?.group(0)?.toUpperCase() ?? value.trim().toUpperCase();
  }

  static String normalizeFullDeviceId(String? value) {
    if (value == null) return '';

    final text = value.trim().toUpperCase();
    if (text.isEmpty) return '';

    final pciVen = RegExp(r'VEN_([0-9A-F]{4})').firstMatch(text)?.group(1);
    final pciDev = RegExp(r'DEV_([0-9A-F]{4})').firstMatch(text)?.group(1);
    if (pciVen != null && pciDev != null) return '$pciVen-$pciDev';

    final pair = RegExp(r'([0-9A-F]{4})[-:_]([0-9A-F]{4})').firstMatch(text);
    if (pair != null) return '${pair.group(1)}-${pair.group(2)}';

    return text;
  }

  static String? extractCodenameFromDeviceName(String name) {
    final text = name.trim();
    if (text.isEmpty) return null;

    final explicit = RegExp(
      r'codename:\s*([^,\)]+)',
      caseSensitive: false,
    ).firstMatch(text);
    final explicitCodename = explicit?.group(1)?.trim();
    if (explicitCodename != null && explicitCodename.isNotEmpty) {
      return explicitCodename;
    }

    final bracket = text.indexOf('[');
    if (bracket > 0) {
      final prefix = text.substring(0, bracket).trim();
      if (_looksLikeCodename(prefix)) return prefix;
    }

    if (_looksLikeCodename(text)) return text;

    return null;
  }

  static bool _looksLikeCodename(String value) {
    if (value.isEmpty) return false;
    final lower = value.toLowerCase();
    if (lower.contains('dummy function')) return false;
    if (lower.contains('upstream port') || lower.contains('downstream port')) {
      return false;
    }
    if (lower.contains(' usb')) return false;
    if (lower.endsWith('bridge')) return false;
    if (lower.endsWith('controller')) return false;
    if (lower.endsWith('audio')) return false;
    if (lower.contains('hdmi') || lower.contains('displayport')) return false;
    return RegExp(r'[A-Za-z]').hasMatch(value);
  }

  String? vendorName(String vendorId) =>
      _vendors[_normalizeShortId(vendorId)]?.name;

  String? deviceName(String vendorId, String deviceId) =>
      device(vendorId, deviceId)?.name;

  String? deviceNameByFullId(String deviceId) {
    final parts = normalizeFullDeviceId(deviceId).split('-');
    if (parts.length != 2) return null;
    return deviceName(parts[0], parts[1]);
  }

  IdsDeviceEntry? device(String vendorId, String deviceId) =>
      _vendors[_normalizeShortId(vendorId)]
          ?.devices[_normalizeShortId(deviceId)];
}
