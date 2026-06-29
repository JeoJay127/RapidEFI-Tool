import '../pci_ids_parser.dart';

enum GpuResolvedType {
  integrated,
  discrete,
  unknown,
}

extension GpuResolvedTypeLabel on GpuResolvedType {
  String get label {
    switch (this) {
      case GpuResolvedType.integrated:
        return '核心显卡';
      case GpuResolvedType.discrete:
        return '独立显卡';
      case GpuResolvedType.unknown:
        return '未知显卡';
    }
  }
}

class GpuCodenameData {
  static const String _pciIdsAssetPath = 'assets/data/pci.ids';
  static IdsParser? _pciIds;
  static Future<void>? _loadFuture;

  GpuCodenameData._();

  static bool get isLoaded => _pciIds != null;

  static Future<void> ensureLoaded() async {
    if (_pciIds != null) return;
    if (_loadFuture != null) return _loadFuture;

    _loadFuture = () async {
      _pciIds = await IdsParser.load(_pciIdsAssetPath);
    }();

    try {
      return await _loadFuture;
    } finally {
      _loadFuture = null;
    }
  }

  static String? lookupCodename(String deviceId) {
    final normalized = IdsParser.normalizeFullDeviceId(deviceId);
    if (normalized.isEmpty || isIntelGpu(normalized)) return null;

    final deviceName = _pciIds?.deviceNameByFullId(normalized);
    if (deviceName == null || deviceName.isEmpty) return null;

    return IdsParser.extractCodenameFromDeviceName(deviceName);
  }

  static String? lookupDeviceName(String deviceId) {
    final normalized = IdsParser.normalizeFullDeviceId(deviceId);
    if (normalized.isEmpty) return null;

    final name = _pciIds?.deviceNameByFullId(normalized);
    if (name == null || name.trim().isEmpty) return null;

    return name.trim();
  }

  static bool isIntelGpu(String deviceId) {
    return IdsParser.normalizeFullDeviceId(deviceId).startsWith('8086-');
  }

  static bool isAmdGpu(String deviceId) {
    return IdsParser.normalizeFullDeviceId(deviceId).startsWith('1002-');
  }

  static bool isNvidiaGpu(String deviceId) {
    return IdsParser.normalizeFullDeviceId(deviceId).startsWith('10DE-');
  }

  static String? extractCodenameFromBracket(String description) {
    return IdsParser.extractCodenameFromDeviceName(description);
  }

  static const _intelIgpPatterns = [
    'hd graphics',
    'uhd graphics',
    'iris',
    'iris plus',
    'iris pro',
    'iris xe',
    'intel graphics',
    'intel(r) graphics',
    'intel(r) hd graphics',
    'intel(r) uhd graphics',
    'intel(r) iris',
    'intel arc graphics',
  ];

  static const _amdIgpPatterns = [
    'radeon(tm) graphics',
    'radeon(tm) vega',
    'radeon rx vega',
    'radeon vega',
    'vega graphics',
    'amd radeon graphics',
    'radeon graphics',
  ];

  static bool isIntegratedByName(String name) {
    final lower = name.toLowerCase();

    for (final pattern in _intelIgpPatterns) {
      if (lower.contains(pattern)) return true;
    }

    for (final pattern in _amdIgpPatterns) {
      if (lower.contains(pattern)) return true;
    }

    return false;
  }

  static const _discreteNamePatterns = [
    'radeon rx',
    'radeon r9',
    'radeon r7',
    'radeon r5',
    'radeon hd',
    'radeon pro',
    'firepro',
    'firegl',
    'instinct',
    'geforce',
    'quadro',
    'nvidia',
    'rtx',
    'gtx',
    'tesla',
  ];

  static bool isDiscreteByName(String name) {
    final lower = name.toLowerCase();

    for (final pattern in _discreteNamePatterns) {
      if (lower.contains(pattern)) return true;
    }

    // 兼容 “Radeon 550 / Radeon 540 / Radeon 530” 这种没有 RX 的低端独显命名
    if (RegExp(r'\bradeon\s+[0-9]{3,4}\b').hasMatch(lower)) {
      return true;
    }

    return false;
  }

  static const _discreteCodenames = [
    // AMD GCN / Polaris / Vega / Navi / RDNA
    'lexa',
    'baffin',
    'ellesmere',
    'polaris',
    'polaris 10',
    'polaris 11',
    'polaris 12',
    'polaris 20',
    'polaris 21',
    'polaris 22',
    'gfx',
    'verde',
    'pitcairn',
    'tahiti',
    'oland',
    'bonaire',
    'hawaii',
    'tonga',
    'fiji',
    'curacao',
    'cape verde',
    'vega 10',
    'vega 20',
    'navi',
    'navi 10',
    'navi 12',
    'navi 14',
    'navi 21',
    'navi 22',
    'navi 23',
    'navi 24',
    'navi 31',
    'navi 32',
    'navi 33',

    // NVIDIA
    'fermi',
    'kepler',
    'maxwell',
    'pascal',
    'turing',
    'ampere',
    'ada',
    'blackwell',
    'gf',
    'gk',
    'gm',
    'gp',
    'tu',
    'ga',
    'ad',
    'gb',
  ];

  static bool isDiscreteByCodename(String codename) {
    final lower = codename.toLowerCase().trim();
    if (lower.isEmpty) return false;

    for (final pattern in _discreteCodenames) {
      if (lower.contains(pattern)) return true;
    }

    // NVIDIA 常见核心：GA104、TU106、AD103、GB202 等
    if (RegExp(r'^(gf|gk|gm|gp|tu|ga|ad|gb)[0-9]{2,4}$').hasMatch(lower)) {
      return true;
    }

    return false;
  }

  static GpuResolvedType typeFromRawDeviceType(dynamic value) {
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text.isEmpty) return GpuResolvedType.unknown;

    if (text == 'discrete' || text == 'discrete gpu' || text.contains('独立')) {
      return GpuResolvedType.discrete;
    }

    if (text == 'integrated' ||
        text == 'integrated gpu' ||
        text.contains('核心') ||
        text.contains('核显') ||
        text.contains('集成')) {
      return GpuResolvedType.integrated;
    }

    return GpuResolvedType.unknown;
  }

  static GpuResolvedType typeFromAcpiPath(String acpiPath) {
    final path = acpiPath.toUpperCase().trim();
    if (path.isEmpty) return GpuResolvedType.unknown;

    // IGPU/GFX0 常见于核显
    if (path.contains('IGPU') ||
        path.endsWith('.GFX0') ||
        path.contains('.GFX0')) {
      return GpuResolvedType.integrated;
    }

    // PEG/PEGP 常见于 PCIe 独显通道
    if (path.contains('PEG') || path.contains('PEGP')) {
      return GpuResolvedType.discrete;
    }

    return GpuResolvedType.unknown;
  }

  static GpuResolvedType typeFromPciPath(String pciPath) {
    final path = pciPath.toUpperCase().trim();
    if (path.isEmpty) return GpuResolvedType.unknown;

    // PciRoot(0x0)/Pci(0x2,0x0) 常见 Intel 核显路径
    if (path.contains('PCI(0X2,0X0)')) {
      return GpuResolvedType.integrated;
    }

    // PciRoot(0x0)/Pci(0x1,0x0)、Pci(0x3,0x0) 常见 PEG 独显入口
    if (path.contains('PCI(0X1,0X0)') || path.contains('PCI(0X3,0X0)')) {
      return GpuResolvedType.discrete;
    }

    return GpuResolvedType.unknown;
  }

  static GpuResolvedType typeFromName(String name) {
    if (isIntegratedByName(name)) return GpuResolvedType.integrated;
    if (isDiscreteByName(name)) return GpuResolvedType.discrete;
    return GpuResolvedType.unknown;
  }

  static GpuResolvedType typeFromDeviceId(String deviceId) {
    final normalized = IdsParser.normalizeFullDeviceId(deviceId);
    if (normalized.isEmpty) return GpuResolvedType.unknown;

    // NVIDIA 消费级/专业卡基本都按独显处理
    if (isNvidiaGpu(normalized)) {
      return GpuResolvedType.discrete;
    }

    // AMD 1002 既可能是独显，也可能是 APU 核显，不能只靠 vendor ID 直接判定
    // Intel 8086 也既可能是核显，也可能是 Arc 独显，所以这里只做弱判断，不直接返回
    return GpuResolvedType.unknown;
  }

  /// 综合判断 GPU 类型。
  ///
  /// 优先级：
  /// 1. 原始 Device Type
  /// 2. 名称
  /// 3. ACPI Path
  /// 4. PCI Path
  /// 5. Codename
  /// 6. Device ID 厂商
  static GpuResolvedType resolveGpuType({
    required String name,
    required String deviceId,
    dynamic rawDeviceType,
    String acpiPath = '',
    String pciPath = '',
    String codename = '',
    String? pciIdsDeviceName,
  }) {
    final rawType = typeFromRawDeviceType(rawDeviceType);
    if (rawType != GpuResolvedType.unknown) return rawType;

    final byName = typeFromName(name);
    if (byName != GpuResolvedType.unknown) return byName;

    if (pciIdsDeviceName != null && pciIdsDeviceName.trim().isNotEmpty) {
      final byPciIdsName = typeFromName(pciIdsDeviceName);
      if (byPciIdsName != GpuResolvedType.unknown) return byPciIdsName;
    }

    final byAcpiPath = typeFromAcpiPath(acpiPath);
    if (byAcpiPath != GpuResolvedType.unknown) return byAcpiPath;

    final byPciPath = typeFromPciPath(pciPath);
    if (byPciPath != GpuResolvedType.unknown) return byPciPath;

    final finalCodename = codename.trim().isNotEmpty
        ? codename
        : (lookupCodename(deviceId) ?? '');

    if (isDiscreteByCodename(finalCodename)) {
      return GpuResolvedType.discrete;
    }

    final byDeviceId = typeFromDeviceId(deviceId);
    if (byDeviceId != GpuResolvedType.unknown) return byDeviceId;

    return GpuResolvedType.unknown;
  }

  static String resolveGpuTypeLabel({
    required String name,
    required String deviceId,
    dynamic rawDeviceType,
    String acpiPath = '',
    String pciPath = '',
    String codename = '',
    String? pciIdsDeviceName,
  }) {
    return resolveGpuType(
      name: name,
      deviceId: deviceId,
      rawDeviceType: rawDeviceType,
      acpiPath: acpiPath,
      pciPath: pciPath,
      codename: codename,
      pciIdsDeviceName: pciIdsDeviceName,
    ).label;
  }
}
