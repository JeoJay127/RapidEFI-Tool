Map<String, dynamic> safeMap(dynamic value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<dynamic> safeList(dynamic value) {
  if (value is List) return value;
  if (value == null) return [];
  return [value];
}

Iterable<MapEntry<String, dynamic>> hardwareDevices(dynamic value) {
  return safeMap(value).entries.where((e) => e.value is Map);
}

String safeStr(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String joinNonEmpty(List<String> parts, String separator) {
  return parts.where((p) => p.trim().isNotEmpty).join(separator);
}

dynamic firstOf(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (safeStr(value).isNotEmpty) return value;
  }
  return null;
}

bool isTruthy(dynamic value) {
  final text = safeStr(value).toLowerCase();

  return text == 'enabled' ||
      text == 'enable' ||
      text == 'true' ||
      text == '1' ||
      text == 'on' ||
      text == 'yes' ||
      text == '已启用' ||
      text == '开启';
}

bool? isTruthyOrNull(dynamic value) {
  if (value is bool) return value;

  final text = safeStr(value).toLowerCase();
  if (text.isEmpty) return null;

  if (text == 'enabled' ||
      text == 'enable' ||
      text == 'true' ||
      text == '1' ||
      text == 'on' ||
      text == 'yes') {
    return true;
  }

  if (text == 'disabled' ||
      text == 'disable' ||
      text == 'false' ||
      text == '0' ||
      text == 'off' ||
      text == 'no') {
    return false;
  }

  return null;
}

bool isPciHardware(dynamic value) {
  final device = safeMap(value);

  return safeStr(device['Bus Type']).toUpperCase() == 'PCI' &&
      safeStr(device['Device ID']).isNotEmpty;
}

String deviceDisplayName(String fallback, Map<String, dynamic> device) {
  final desc = safeStr(device['DeviceDesc']);
  if (desc.isNotEmpty) return desc;

  final name = safeStr(device['Name']);
  if (name.isNotEmpty) return name;

  return fallback.trim();
}

String netDisplayType(String type) {
  final n = type.trim();
  return n.toLowerCase() == 'pci wifi' ? 'WiFi' : n;
}

String networkAdapterType({
  String? name,
}) {
  final normalizedName = safeStr(name).toLowerCase();
  if (normalizedName.isEmpty) return '未知';

  if (normalizedName.contains('wi-fi') ||
      normalizedName.contains('802.11') ||
      normalizedName.contains('centrino') ||
      normalizedName.contains('advanced-n') ||
      normalizedName.contains('wlan') ||
      normalizedName.contains('wifi') ||
      normalizedName.contains('wireless')) {
    return 'WiFi';
  }

  return '有线网卡';
}

String deviceIdPart(String deviceId) {
  final value = deviceId.trim().toUpperCase();
  final separator = value.indexOf('-');

  return separator >= 0 ? value.substring(separator + 1) : value;
}

String memType(dynamic value) {
  const types = {
    20: 'DDR',
    21: 'DDR2',
    24: 'DDR3',
    26: 'DDR4',
    27: 'LPDDR',
    28: 'LPDDR2',
    29: 'LPDDR3',
    30: 'LPDDR4',
    34: 'DDR5',
    35: 'LPDDR5',
  };

  final type = value is int ? value : int.tryParse(safeStr(value));

  return types[type] ?? 'Unknown';
}

String fmtDt(DateTime time) {
  String pad(int value) => value.toString().padLeft(2, '0');

  return '${time.year}-${pad(time.month)}-${pad(time.day)} '
      '${pad(time.hour)}:${pad(time.minute)}:${pad(time.second)}';
}

// ============================================================================
// Capacity Format
// ============================================================================
//
// 设计：
// 1. 数字无单位时，默认按 bytes 处理。
// 2. 硬盘展示用十进制 GB/TB/PB。
// 3. 内存展示用二进制 GiB。
// 4. 支持英文单位：B / KB / MB / GB / TB / PB。
// 5. 支持二进制单位：KiB / MiB / GiB / TiB / PiB。
// ============================================================================

const double _bytesPerKB = 1000.0;
const double _bytesPerMB = 1000.0 * 1000.0;
const double _bytesPerGB = 1000.0 * 1000.0 * 1000.0;
const double _bytesPerTB = 1000.0 * 1000.0 * 1000.0 * 1000.0;
const double _bytesPerPB = 1000.0 * 1000.0 * 1000.0 * 1000.0 * 1000.0;

const double _bytesPerKiB = 1024.0;
const double _bytesPerMiB = 1024.0 * 1024.0;
const double _bytesPerGiB = 1024.0 * 1024.0 * 1024.0;
const double _bytesPerTiB = 1024.0 * 1024.0 * 1024.0 * 1024.0;
const double _bytesPerPiB = 1024.0 * 1024.0 * 1024.0 * 1024.0 * 1024.0;

String fmtMem(dynamic value) {
  final gib = toGiB(value);
  if (gib == null || gib <= 0) return '';

  if (gib >= 1) {
    return '${gib.round()}G';
  }

  return '${(gib * 1024).round()}M';
}

String fmtDiskCap(Map<String, dynamic> disk) {
  return fmtDisk(
    firstOf(
      disk,
      const [
        'Size',
        'Capacity',
        'Total Size',
        'TotalSize',
        'Disk Size',
      ],
    ),
  );
}

String fmtDisk(dynamic value, {int frac = 1}) {
  final gb = toGb(value);
  if (gb == null || gb <= 0) return '';

  if (gb >= 1000000) {
    return '${(gb / 1000000).toStringAsFixed(frac)} PB';
  }

  if (gb >= 1000) {
    return '${(gb / 1000).toStringAsFixed(frac)} TB';
  }

  if (gb >= 1) {
    return '${gb.toStringAsFixed(frac)} GB';
  }

  return '${(gb * 1000).toStringAsFixed(0)} MB';
}

double? toGb(dynamic value) {
  final bytes = toBytes(value);
  if (bytes == null || bytes <= 0) return null;

  return bytes / _bytesPerGB;
}

double? toGiB(dynamic value) {
  final bytes = toBytes(value);
  if (bytes == null || bytes <= 0) return null;

  return bytes / _bytesPerGiB;
}

double? toBytes(dynamic value) {
  if (value == null) return null;

  if (value is num) {
    final number = value.toDouble();
    return number > 0 ? number : null;
  }

  final text = value.toString().trim().replaceAll(',', '');
  if (text.isEmpty) return null;

  final match = RegExp(
    r'^([0-9]+(?:\.[0-9]+)?)\s*([a-zA-Z]+)?$',
  ).firstMatch(text);

  if (match == null) return null;

  final number = double.tryParse(match.group(1) ?? '');
  if (number == null || number <= 0) return null;

  final unit = (match.group(2) ?? 'B').toUpperCase();

  switch (unit) {
    case 'B':
    case 'BYTE':
    case 'BYTES':
      return number;

    case 'KB':
      return number * _bytesPerKB;
    case 'MB':
      return number * _bytesPerMB;
    case 'GB':
      return number * _bytesPerGB;
    case 'TB':
      return number * _bytesPerTB;
    case 'PB':
      return number * _bytesPerPB;

    case 'KIB':
      return number * _bytesPerKiB;
    case 'MIB':
      return number * _bytesPerMiB;
    case 'GIB':
      return number * _bytesPerGiB;
    case 'TIB':
      return number * _bytesPerTiB;
    case 'PIB':
      return number * _bytesPerPiB;

    default:
      return null;
  }
}

// ============================================================================
// Bluetooth
// ============================================================================

bool isBtSvcInput(
  Map<String, dynamic> device,
  String deviceId,
  String deviceValue,
  String acpiPath,
  String pciPath,
) {
  if (deviceId.isNotEmpty || acpiPath.isNotEmpty || pciPath.isNotEmpty) {
    return false;
  }

  final bus = safeStr(device['Bus Type']).toLowerCase();
  final type = safeStr(device['Device Type']).toLowerCase();

  if (bus != 'bluetooth' && type != 'bluetooth') {
    return false;
  }

  return RegExp(
    r'^\{[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\}_LOCALMFG&[0-9a-f]+$',
    caseSensitive: false,
  ).hasMatch(deviceValue);
}