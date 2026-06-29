import 'dart:convert';

import 'package:flutter/services.dart';

class GpuCompatibilityData {
  static const String assetPath = 'assets/data/gpu_compatibility.json';

  static Map<String, dynamic>? _vendors;
  static Future<void>? _loadFuture;

  const GpuCompatibilityData._();

  static Future<void> ensureLoaded() async {
    if (_vendors != null) return;
    if (_loadFuture != null) return _loadFuture;

    _loadFuture = () async {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _vendors = Map<String, dynamic>.from(json['vendors'] as Map);
    }();

    try {
      return await _loadFuture;
    } finally {
      _loadFuture = null;
    }
  }

  static bool get isLoaded => _vendors != null;

  static GpuCompatibilityRecord? findSync(String? rawDeviceId) {
    if (_vendors == null) return null;
    final vendors = _requireVendors();

    final id = normalizeFullDeviceId(rawDeviceId);
    if (id.isEmpty || !id.contains('-')) return null;

    final vendorId = id.split('-').first;
    final vendorRaw = vendors[vendorId];
    if (vendorRaw is! Map) return null;

    final vendor = Map<String, dynamic>.from(vendorRaw);
    final groupsRaw = vendor['groups'];
    if (groupsRaw is! Map) return null;

    final groups = Map<String, dynamic>.from(groupsRaw);

    for (final groupEntry in groups.entries) {
      final groupRaw = groupEntry.value;
      if (groupRaw is! Map) continue;

      final group = Map<String, dynamic>.from(groupRaw);
      final devicesRaw = group['devices'];
      if (devicesRaw is! Map) continue;

      final devices = Map<String, dynamic>.from(devicesRaw);
      final deviceRaw = devices[id];
      if (deviceRaw is! Map) continue;

      return _recordFromRaw(
        id: id,
        vendorId: vendorId,
        groupName: groupEntry.key,
        vendor: vendor,
        group: group,
        device: Map<String, dynamic>.from(deviceRaw),
      );
    }

    return null;
  }

  static List<GpuCompatibilityRecord> identityOverrideRecordsSync() {
    final vendors = _requireVendors();
    final records = <GpuCompatibilityRecord>[];
    var sourceIndex = 0;

    for (final vendorEntry in vendors.entries) {
      final vendorRaw = vendorEntry.value;
      if (vendorRaw is! Map) continue;

      final vendor = Map<String, dynamic>.from(vendorRaw);
      final groupsRaw = vendor['groups'];
      if (groupsRaw is! Map) continue;

      final groups = Map<String, dynamic>.from(groupsRaw);
      for (final groupEntry in groups.entries) {
        final groupRaw = groupEntry.value;
        if (groupRaw is! Map) continue;

        final group = Map<String, dynamic>.from(groupRaw);
        final devicesRaw = group['devices'];
        if (devicesRaw is! Map) continue;

        final devices = Map<String, dynamic>.from(devicesRaw);
        for (final deviceEntry in devices.entries) {
          final deviceRaw = deviceEntry.value;
          if (deviceRaw is! Map) continue;

          final device = Map<String, dynamic>.from(deviceRaw);
          device['_sortIndex'] = sourceIndex;

          final record = _recordFromRaw(
            id: normalizeFullDeviceId(deviceEntry.key),
            vendorId: vendorEntry.key,
            groupName: groupEntry.key,
            vendor: vendor,
            group: group,
            device: device,
          );
          if (record.requiresSpoof) {
            records.add(record);
            sourceIndex++;
          }
        }
      }
    }

    records.sort((a, b) => a.id.compareTo(b.id));
    return records;
  }

  static List<GpuCompatibilityRecord> amdIdentityOverrideRecordsSync() {
    final records = identityOverrideRecordsSync()
        .where((record) => record.vendorId.toUpperCase() == '1002')
        .toList();
    records.sort(_compareAmdIdentityOverrideRecords);
    return records;
  }

  static String normalizeFullDeviceId(String? value) {
    if (value == null) return '';

    final text = value.trim().toUpperCase();
    if (text.isEmpty) return '';

    if (text.contains('-')) {
      final parts = text.split('-');
      if (parts.length >= 2) {
        return '${parts[0]}-${parts[1]}';
      }
    }

    if (text.startsWith('PCI\\VEN_')) {
      final ven = RegExp(r'VEN_([0-9A-Fa-f]{4})').firstMatch(text)?.group(1);
      final dev = RegExp(r'DEV_([0-9A-Fa-f]{4})').firstMatch(text)?.group(1);
      if (ven != null && dev != null) {
        return '${ven.toUpperCase()}-${dev.toUpperCase()}';
      }
    }

    return text;
  }

  static String deviceIdPart(String? value) {
    final id = normalizeFullDeviceId(value);
    if (id.contains('-')) return id.split('-').last;
    return id;
  }

  static Map<String, dynamic> _requireVendors() {
    final vendors = _vendors;
    if (vendors == null) {
      throw StateError(
        'GpuCompatibilityData not loaded. Call GpuCompatibilityData.ensureLoaded() first.',
      );
    }
    return vendors;
  }

  static GpuCompatibilityRecord _recordFromRaw({
    required String id,
    required String vendorId,
    required String groupName,
    required Map<String, dynamic> vendor,
    required Map<String, dynamic> group,
    required Map<String, dynamic> device,
  }) {
    return GpuCompatibilityRecord(
      id: id,
      vendorId: vendorId,
      groupName: groupName,
      vendor: _str(group['vendor'], fallback: _str(vendor['vendor'])),
      name: _str(device['name']),
      codename: _str(device['codename'], fallback: _str(group['codename'])),
      minDarwin: _str(group['minDarwin']),
      maxDarwin: _str(group['maxDarwin']),
      minOclp: _nullableStr(group['minOclp']),
      maxOclp: _nullableStr(group['maxOclp']),
      avx2Limited: _bool(device['avx2Limited']) || _bool(group['avx2Limited']),
      vgaLimited: _bool(device['vgaLimited']) || _bool(group['vgaLimited']),
      spoofId: _nullableStr(device['spoofId']) ??
          _nullableStr(group['spoofId']),
      sortIndex: _int(device['_sortIndex']),
    );
  }

  static String _str(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableStr(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool _bool(Object? value) => value == true;

  static int _int(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _compareAmdIdentityOverrideRecords(
    GpuCompatibilityRecord a,
    GpuCompatibilityRecord b,
  ) {
    final generationCompare =
        _amdIdentityOverrideGenerationRank(b)
            .compareTo(_amdIdentityOverrideGenerationRank(a));
    if (generationCompare != 0) return generationCompare;

    final sourceOrderCompare = b.sortIndex.compareTo(a.sortIndex);
    if (sourceOrderCompare != 0) return sourceOrderCompare;

    final modelCompare =
        _amdIdentityOverrideModelNumber(b)
            .compareTo(_amdIdentityOverrideModelNumber(a));
    if (modelCompare != 0) return modelCompare;

    return a.id.compareTo(b.id);
  }

  static int _amdIdentityOverrideGenerationRank(
    GpuCompatibilityRecord record,
  ) {
    final group = record.groupName.toLowerCase();

    if (group.contains('navi')) return 900;
    if (group.contains('vega')) return 800;
    if (group.contains('polaris')) return 700;
    if (group.contains('gcn_9000')) return 600;
    if (group.contains('gcn_8000')) return 500;
    if (group.contains('gcn_7000')) return 400;
    if (group.contains('terascale_2')) return 300;
    if (group.contains('terascale_1')) return 200;
    if (group.contains('r500')) return 100;

    final text = '${record.codename} ${record.name}'.toLowerCase();
    if (text.contains('navi') || text.contains('rdna')) return 900;
    if (text.contains('vega')) return 800;
    if (text.contains('polaris') || text.contains('ellesmere')) return 700;
    if (text.contains('gcn 3') ||
        text.contains('tonga') ||
        text.contains('fiji')) {
      return 600;
    }
    if (text.contains('gcn 2') ||
        text.contains('bonaire') ||
        text.contains('hawaii')) {
      return 500;
    }
    if (text.contains('gcn 1') ||
        text.contains('pitcairn') ||
        text.contains('tahiti')) {
      return 400;
    }
    if (text.contains('terascale 2')) return 300;
    if (text.contains('terascale 1')) return 200;
    if (text.contains('r500')) return 100;

    return 0;
  }

  static int _amdIdentityOverrideModelNumber(GpuCompatibilityRecord record) {
    final text = '${record.name} ${record.codename} ${record.id}'.toLowerCase();
    final matches = RegExp(r'\b(?:rx|r9|r7|r5|hd|wx|w)\s*-?\s*(\d{3,4})')
        .allMatches(text);

    var best = 0;
    for (final match in matches) {
      final value = int.tryParse(match.group(1) ?? '') ?? 0;
      if (value > best) best = value;
    }

    return best;
  }
}

class GpuCompatibilityRecord {
  final String id;
  final String vendorId;
  final String groupName;
  final String vendor;
  final String name;
  final String codename;

  final String minDarwin;
  final String maxDarwin;
  final String? minOclp;
  final String? maxOclp;

  final bool avx2Limited;
  final bool vgaLimited;

  final String? spoofId;
  final int sortIndex;

  const GpuCompatibilityRecord({
    required this.id,
    required this.vendorId,
    required this.groupName,
    required this.vendor,
    required this.name,
    required this.codename,
    required this.minDarwin,
    required this.maxDarwin,
    required this.minOclp,
    required this.maxOclp,
    required this.avx2Limited,
    required this.vgaLimited,
    required this.spoofId,
    this.sortIndex = 0,
  });

  bool get requiresSpoof => spoofId != null && spoofId!.isNotEmpty;

  String? get spoofDeviceIdPart =>
      GpuCompatibilityData.deviceIdPart(spoofId);

  bool get hasNativeLatest => DarwinVersion(maxDarwin) >= DarwinVersion.latest;

  bool get hasOclpRange =>
      minOclp != null &&
      minOclp!.isNotEmpty &&
      maxOclp != null &&
      maxOclp!.isNotEmpty;
}

class DarwinVersion implements Comparable<DarwinVersion> {
  static final latest = DarwinVersion('25.99.99');
  static final montereyMax = DarwinVersion('21.99.99');

  final String raw;
  final int major;
  final int minor;
  final int patch;

  const DarwinVersion._({
    required this.raw,
    required this.major,
    required this.minor,
    required this.patch,
  });

  factory DarwinVersion(String value) {
    final parts = value.trim().split('.');
    int read(int index, int fallback) {
      if (index >= parts.length) return fallback;
      return int.tryParse(parts[index]) ?? fallback;
    }

    return DarwinVersion._(
      raw: value,
      major: read(0, 0),
      minor: read(1, 0),
      patch: read(2, 0),
    );
  }

  @override
  int compareTo(DarwinVersion other) {
    final majorCompare = major.compareTo(other.major);
    if (majorCompare != 0) return majorCompare;

    final minorCompare = minor.compareTo(other.minor);
    if (minorCompare != 0) return minorCompare;

    return patch.compareTo(other.patch);
  }

  bool operator <(DarwinVersion other) => compareTo(other) < 0;

  bool operator <=(DarwinVersion other) => compareTo(other) <= 0;

  bool operator >(DarwinVersion other) => compareTo(other) > 0;

  bool operator >=(DarwinVersion other) => compareTo(other) >= 0;

  @override
  String toString() => raw;
}
