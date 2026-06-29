class IntelConnectorType {
  const IntelConnectorType({
    required this.id,
    required this.label,
    required this.value,
    this.recommended = true,
  });

  final String id;
  final String label;
  final String value;
  final bool recommended;

  static const dp = IntelConnectorType(
    id: 'dp',
    label: 'DP',
    value: '00040000',
  );
  static const lvdsEdp = IntelConnectorType(
    id: 'lvds_edp',
    label: 'LVDS/eDP',
    value: '02000000',
  );
  static const hdmi = IntelConnectorType(
    id: 'hdmi',
    label: 'HDMI',
    value: '00080000',
  );
  static const vga = IntelConnectorType(
    id: 'vga',
    label: 'VGA',
    value: '10000000',
    recommended: false,
  );
  static const dviDual = IntelConnectorType(
    id: 'dvi_dual',
    label: 'DVI 双链',
    value: '04000000',
    recommended: false,
  );
  static const dviSingle = IntelConnectorType(
    id: 'dvi_single',
    label: 'DVI 单链',
    value: '00020000',
    recommended: false,
  );

  static const values = [
    dp,
    lvdsEdp,
    hdmi,
    vga,
    dviDual,
    dviSingle,
  ];

  static IntelConnectorType byValue(String value) {
    final normalized = value.trim().toUpperCase();
    for (final type in values) {
      if (type.value == normalized) {
        return type;
      }
    }
    return dp;
  }
}

class IntelConnectorPatchValue {
  const IntelConnectorPatchValue({
    required this.connectorIndex,
    required this.indexHex,
    required this.busIdHex,
    required this.pipeHex,
    required this.type,
    required this.flagsHex,
    this.auxHex,
    this.format = IntelConnectorPatchFormat.standard,
  });

  final int connectorIndex;
  final String indexHex;
  final String busIdHex;
  final String pipeHex;
  final IntelConnectorType type;
  final String flagsHex;
  final String? auxHex;
  final IntelConnectorPatchFormat format;

  String get allData {
    if (format == IntelConnectorPatchFormat.iceLake) {
      return '${_dword(indexHex)}${_dword(busIdHex)}${_dword(pipeHex)}'
              '${_dword(auxHex ?? '00')}${type.value}$flagsHex'
          .toUpperCase();
    }
    return '$indexHex$busIdHex${pipeHex}00${type.value}$flagsHex'.toUpperCase();
  }

  IntelConnectorPatchValue copyWith({
    int? connectorIndex,
    String? indexHex,
    String? busIdHex,
    String? pipeHex,
    IntelConnectorType? type,
    String? flagsHex,
    String? auxHex,
    IntelConnectorPatchFormat? format,
  }) {
    return IntelConnectorPatchValue(
      connectorIndex: connectorIndex ?? this.connectorIndex,
      indexHex: indexHex ?? this.indexHex,
      busIdHex: busIdHex ?? this.busIdHex,
      pipeHex: pipeHex ?? this.pipeHex,
      type: type ?? this.type,
      flagsHex: flagsHex ?? this.flagsHex,
      auxHex: auxHex ?? this.auxHex,
      format: format ?? this.format,
    );
  }

  static String _dword(String value) {
    final normalized = value.trim().toUpperCase().padLeft(2, '0');
    return '${normalized.substring(normalized.length - 2)}000000';
  }
}

enum IntelConnectorPatchFormat { standard, iceLake }

class IntelConnectorPlatformTemplate {
  IntelConnectorPlatformTemplate({
    required this.platformCode,
    required this.framebufferId,
    required this.indexHexByConnector,
    required this.busIdHexByConnector,
    required this.pipeHexByConnector,
    this.flagsHex = '',
    this.auxHexByConnector = const [],
    this.typeByConnector = const [],
    this.flagsHexByConnector = const [],
    this.portIndexes = standardPortIndexes,
    this.busIdOptions = standardBusIds,
    this.format = IntelConnectorPatchFormat.standard,
    this.supported = true,
    this.preferExternalConnectors = false,
  });

  factory IntelConnectorPlatformTemplate.fromAllData({
    required String framebufferId,
    required List<String> values,
    IntelConnectorPatchFormat format = IntelConnectorPatchFormat.standard,
    List<String>? portIndexes,
    List<String>? busIdOptions,
  }) {
    final parsedValues = values
        .map((value) => _parseAllData(value, format: format))
        .whereType<IntelConnectorPatchValue>()
        .toList();

    final busIds = {
      if (format == IntelConnectorPatchFormat.iceLake) ...iceLakeBusIds,
      if (format == IntelConnectorPatchFormat.standard) ...standardBusIds,
      ...parsedValues.map((value) => value.busIdHex),
    }.toList()
      ..sort();
    final indexes = {
      if (format == IntelConnectorPatchFormat.iceLake) ...iceLakePortIndexes,
      if (format == IntelConnectorPatchFormat.standard) ...standardPortIndexes,
      ...parsedValues.map((value) => value.indexHex),
    }.toList()
      ..sort();

    return IntelConnectorPlatformTemplate(
      platformCode: '',
      framebufferId: framebufferId,
      indexHexByConnector:
          parsedValues.map((value) => value.indexHex).toList(),
      busIdHexByConnector:
          parsedValues.map((value) => value.busIdHex).toList(),
      pipeHexByConnector:
          parsedValues.map((value) => value.pipeHex).toList(),
      auxHexByConnector: format == IntelConnectorPatchFormat.iceLake
          ? parsedValues.map((value) => value.auxHex ?? '00').toList()
          : const [],
      typeByConnector: parsedValues.map((value) => value.type).toList(),
      flagsHexByConnector:
          parsedValues.map((value) => value.flagsHex).toList(),
      portIndexes: portIndexes ?? indexes,
      busIdOptions: busIdOptions ?? busIds,
      format: format,
    );
  }

  final String platformCode;
  final String framebufferId;
  final List<String> indexHexByConnector;
  final List<String> busIdHexByConnector;
  final List<String> pipeHexByConnector;
  final String flagsHex;
  final List<String> auxHexByConnector;
  final List<IntelConnectorType> typeByConnector;
  final List<String> flagsHexByConnector;
  final List<String> portIndexes;
  final List<String> busIdOptions;
  final IntelConnectorPatchFormat format;
  final bool supported;
  final bool preferExternalConnectors;

  static const allConnectorIndexes = [0, 1, 2, 3];

  List<int> get connectorIndexes {
    return List.generate(indexHexByConnector.length, (index) => index);
  }

  static const standardBusIds = ['01', '02', '03', '04', '05', '06'];
  static const iceLakeBusIds = [
    '00',
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '0A',
    '0B',
    '0C',
  ];
  static const standardPortIndexes = ['01', '02', '03', '04', '05', '06'];
  static const iceLakePortIndexes = ['00', '02', '03', '04', '05'];

  List<String> get busIds {
    return busIdOptions;
  }

  static IntelConnectorPlatformTemplate forConfig({
    required String platformCode,
    required String? igPlatformId,
    bool preferExternalConnectors = false,
  }) {
    final normalizedPlatform = platformCode.trim().toLowerCase();
    final normalizedFramebuffer = _normalizeFramebufferId(igPlatformId);
    final template = _templatesByFramebufferId[normalizedFramebuffer];
    if (template != null) {
      return template._copyForPlatform(
        normalizedPlatform,
        preferExternalConnectors: preferExternalConnectors,
      );
    }

    if (normalizedFramebuffer.isNotEmpty) {
      return IntelConnectorPlatformTemplate.unsupported(
        platformCode: normalizedPlatform,
        framebufferId: normalizedFramebuffer,
        preferExternalConnectors: preferExternalConnectors,
      );
    }

    return forPlatform(
      normalizedPlatform,
      preferExternalConnectors: preferExternalConnectors,
    );
  }

  static IntelConnectorPlatformTemplate forPlatform(
    String platformCode, {
    bool preferExternalConnectors = false,
  }) {
    final normalized = platformCode.trim().toLowerCase();
    return switch (normalized) {
      'skylake' => _templatesByFramebufferId['19120000']!._copyForPlatform(
          normalized,
          preferExternalConnectors: preferExternalConnectors,
        ),
      'kaby_lake' => _templatesByFramebufferId['59120000']!._copyForPlatform(
          normalized,
          preferExternalConnectors: preferExternalConnectors,
        ),
      'coffee_lake_8th' ||
      'coffee_lake_9th' ||
      'comet_lake' =>
        _templatesByFramebufferId['3E9B0007']!._copyForPlatform(
          normalized,
          preferExternalConnectors: preferExternalConnectors,
        ),
      'ice_lake' => _templatesByFramebufferId['8A520000']!._copyForPlatform(
          normalized,
          preferExternalConnectors: preferExternalConnectors,
        ),
      _ => IntelConnectorPlatformTemplate.unsupported(
          platformCode: normalized,
          framebufferId: '',
          preferExternalConnectors: preferExternalConnectors,
        ),
    };
  }

  factory IntelConnectorPlatformTemplate.unsupported({
    required String platformCode,
    required String framebufferId,
    bool preferExternalConnectors = false,
  }) {
    return IntelConnectorPlatformTemplate(
      platformCode: platformCode,
      framebufferId: framebufferId,
      indexHexByConnector: const [],
      busIdHexByConnector: const [],
      pipeHexByConnector: const [],
      supported: false,
      preferExternalConnectors: preferExternalConnectors,
    );
  }

  IntelConnectorPlatformTemplate _copyForPlatform(
    String platformCode, {
    bool preferExternalConnectors = false,
  }) {
    final source = preferExternalConnectors
        ? _withoutLeadingInternalConnector()
        : this;
    return IntelConnectorPlatformTemplate(
      platformCode: platformCode,
      framebufferId: framebufferId,
      indexHexByConnector: source.indexHexByConnector,
      busIdHexByConnector: source.busIdHexByConnector,
      pipeHexByConnector: source.pipeHexByConnector,
      flagsHex: source.flagsHex,
      auxHexByConnector: source.auxHexByConnector,
      typeByConnector: source.typeByConnector,
      flagsHexByConnector: source.flagsHexByConnector,
      portIndexes: source.portIndexes,
      busIdOptions: source.busIdOptions,
      format: source.format,
      supported: source.supported,
      preferExternalConnectors: preferExternalConnectors,
    );
  }

  IntelConnectorPlatformTemplate _withoutLeadingInternalConnector() {
    if (typeByConnector.isEmpty ||
        typeByConnector.first != IntelConnectorType.lvdsEdp) {
      return this;
    }

    return IntelConnectorPlatformTemplate(
      platformCode: platformCode,
      framebufferId: framebufferId,
      indexHexByConnector: indexHexByConnector.skip(1).toList(),
      busIdHexByConnector: busIdHexByConnector.skip(1).toList(),
      pipeHexByConnector: pipeHexByConnector.skip(1).toList(),
      flagsHex: flagsHex,
      auxHexByConnector:
          auxHexByConnector.isEmpty ? const [] : auxHexByConnector.skip(1).toList(),
      typeByConnector: typeByConnector.skip(1).toList(),
      flagsHexByConnector: flagsHexByConnector.isEmpty
          ? const []
          : flagsHexByConnector.skip(1).toList(),
      portIndexes: portIndexes,
      busIdOptions: busIdOptions,
      format: format,
      supported: supported,
      preferExternalConnectors: preferExternalConnectors,
    );
  }

  IntelConnectorPatchValue defaultValue(
    int connectorIndex, {
    Iterable<String> usedBusIds = const [],
  }) {
    if (!connectorIndexes.contains(connectorIndex)) {
      throw ArgumentError.value(connectorIndex, 'connectorIndex');
    }
    final safeIndex = connectorIndex;
    final used = usedBusIds.map((item) => item.toUpperCase()).toSet();
    final recommendedBusId = busIdHexByConnector[safeIndex];
    final busId = used.contains(recommendedBusId)
        ? busIds.firstWhere(
            (item) => !used.contains(item),
            orElse: () => recommendedBusId,
          )
        : recommendedBusId;

    var connectorType = typeByConnector.isEmpty
        ? IntelConnectorType.hdmi
        : typeByConnector[safeIndex];
    if (preferExternalConnectors &&
        connectorType == IntelConnectorType.lvdsEdp) {
      connectorType = IntelConnectorType.hdmi;
    }

    return IntelConnectorPatchValue(
      connectorIndex: safeIndex,
      indexHex: indexHexByConnector[safeIndex],
      busIdHex: busId,
      pipeHex: pipeHexByConnector[safeIndex],
      type: connectorType,
      flagsHex:
          flagsHexByConnector.isEmpty ? flagsHex : flagsHexByConnector[safeIndex],
      auxHex: auxHexByConnector.isEmpty ? null : auxHexByConnector[safeIndex],
      format: format,
    );
  }

  IntelConnectorPatchValue? parse(int connectorIndex, String allData) {
    return _parseAllData(allData, connectorIndex: connectorIndex);
  }

  static IntelConnectorPatchValue? _parseAllData(
    String allData, {
    int connectorIndex = 0,
    IntelConnectorPatchFormat? format,
  }) {
    final normalized =
        allData.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    if (normalized.length == 48 &&
        (format == null || format == IntelConnectorPatchFormat.iceLake)) {
      return IntelConnectorPatchValue(
        connectorIndex: connectorIndex,
        indexHex: _byteFromDword(normalized.substring(0, 8)),
        busIdHex: _byteFromDword(normalized.substring(8, 16)),
        pipeHex: _byteFromDword(normalized.substring(16, 24)),
        auxHex: _byteFromDword(normalized.substring(24, 32)),
        type: IntelConnectorType.byValue(normalized.substring(32, 40)),
        flagsHex: normalized.substring(40, 48),
        format: IntelConnectorPatchFormat.iceLake,
      );
    }

    if (normalized.length == 24 &&
        (format == null || format == IntelConnectorPatchFormat.standard)) {
      return IntelConnectorPatchValue(
        connectorIndex: connectorIndex,
        indexHex: normalized.substring(0, 2),
        busIdHex: normalized.substring(2, 4),
        pipeHex: normalized.substring(4, 6),
        type: IntelConnectorType.byValue(normalized.substring(8, 16)),
        flagsHex: normalized.substring(16, 24),
      );
    }

    return null;
  }

  static String _byteFromDword(String value) {
    final normalized = value.trim().toUpperCase().padLeft(8, '0');
    return normalized.substring(0, 2);
  }

  static String _normalizeFramebufferId(String? value) {
    final raw = (value ?? '').replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (raw.length < 8) return '';
    final normalized = raw.substring(0, 8).toUpperCase();
    final reversed = _reverseDword(normalized);
    if (_templatesByFramebufferId.containsKey(reversed)) {
      return reversed;
    }
    return normalized;
  }

  static String _reverseDword(String value) {
    return '${value.substring(6, 8)}${value.substring(4, 6)}'
            '${value.substring(2, 4)}${value.substring(0, 2)}'
        .toUpperCase();
  }
}

final _templatesByFramebufferId = <String, IntelConnectorPlatformTemplate>{
  '01660003': _standardTemplate('01660003', [
    '050300000200000030000000',
    '020500000004000007040000',
    '030400000004000081000000',
  ]),
  '01660004': _standardTemplate('01660004', [
    '050300000200000030020000',
  ]),
  '01660009': _standardTemplate('01660009', [
    '010000000200000030000000',
    '020500000004000007010000',
    '030400000004000007010000',
  ]),
  '0166000A': _standardTemplate('0166000A', [
    '020500000004000007010000',
    '030400000004000007010000',
    '040600000008000006000000',
  ]),
  '0166000B': _standardTemplate('0166000B', [
    '020500000004000007010000',
    '030400000004000007010000',
    '040600000008000006000000',
  ]),
  '0A260005': _standardTemplate('0A260005', [
    '000008000200000030000000',
    '010509000004000087000000',
    '020409000004000087000000',
  ]),
  '0A260006': _standardTemplate('0A260006', [
    '000008000200000030000000',
    '010509000004000087000000',
    '020409000004000087000000',
  ]),
  '0D220003': _standardTemplate('0D220003', [
    '010509000004000087000000',
    '02040A000004000087000000',
    '030608000004000011000000',
  ]),
  '16120003': _standardTemplate('16120003', [
    '000008000200000030020000',
    '01050B000004000007050000',
    '02040B000004000007050000',
    '030603000008000006000000',
  ]),
  '16220007': _standardTemplate('16220007', [
    '010509000004000007050000',
    '02040A000004000007050000',
    '030608000004000011000000',
  ]),
  '16260002': _standardTemplate('16260002', [
    '000008000200000030020000',
    '010509000004000007050000',
    '02040A000004000007050000',
  ]),
  '16260006': _standardTemplate('16260006', [
    '000008000200000030020000',
    '01050B000004000007050000',
    '02040B000004000007050000',
  ]),
  '162B0000': _standardTemplate('162B0000', [
    '000008000200000030020000',
    '010509000400000004000000',
    '020409000008000082000000',
  ]),
  '19120000': _standardTemplate('19120000', [
    'FF0000000100000020000000',
    '010509000004000087010000',
    '02040A000004000087010000',
  ]),
  '19160000': _standardTemplate('19160000', [
    '000008000200000098000000',
    '010509000004000087010000',
    '02040A000004000087010000',
  ]),
  '19160002': _standardTemplate('19160002', [
    '000008000200000098040000',
    '0105090000040000C7030000',
    '02040A0000040000C7030000',
  ]),
  '191B0000': _standardTemplate('191B0000', [
    '000008000200000098000000',
    '010509000004000087010000',
    '02040A000004000087010000',
  ]),
  '191E0000': _standardTemplate('191E0000', [
    '000008000200000098000000',
    '010509000004000087010000',
    '02040A000004000087010000',
  ]),
  '19260002': _standardTemplate('19260002', [
    '000008000200000098040000',
    '0105090000040000C7030000',
    '02040A0000040000C7030000',
  ]),
  '193B0005': _standardTemplate('193B0005', [
    '000008000200000098000000',
    '0105090000040000C7010000',
    '02040A0000040000C7010000',
  ]),
  '59120000': _standardTemplate('59120000', [
    '010509000004000087010000',
    '02040A000004000087010000',
    '03060A000004000087010000',
  ]),
  '59160000': _standardTemplate('59160000', [
    '000008000200000098000000',
    '010509000004000087010000',
    '02040A000008000087010000',
  ]),
  '591B0000': _standardTemplate('591B0000', [
    '000008000200000098000000',
    '02040A000008000087010000',
    '03060A000004000087010000',
  ]),
  '591E0000': _standardTemplate('591E0000', [
    '000008000200000098000000',
    '010509000004000087010000',
    '02040A000004000087010000',
  ]),
  '59260002': _standardTemplate('59260002', [
    '000008000200000098040000',
    '0105090000040000C7030000',
    '02040A0000040000C7030000',
  ]),
  '87C00000': _standardTemplate('87C00000', [
    '000008000200000098000000',
    '010509000004000087010000',
    '02040A000004000087010000',
  ]),
  '3E9B0000': _standardTemplate('3E9B0000', [
    '000008000200000098000000',
    '010509000004000087010000',
    '02040A000004000087010000',
  ]),
  '3E9B0007': _standardTemplate('3E9B0007', [
    '0105090000040000C7030000',
    '02040A0000040000C7030000',
    '0306080000040000C7030000',
  ]),
  '3EA50000': _standardTemplate('3EA50000', [
    '000008000200000098000000',
    '010509000004000087010000',
    '02040A000004000087010000',
  ]),
  '3EA50004': _standardTemplate('3EA50004', [
    '000008000200000098040000',
    '0105090000040000C7030000',
    '02040A0000040000C7030000',
  ]),
  '3EA50009': _standardTemplate('3EA50009', [
    '000008000200000098000000',
    '0105090000040000C7010000',
    '02040A0000040000C7010000',
  ]),
  '8A520000': IntelConnectorPlatformTemplate.fromAllData(
    framebufferId: '8A520000',
    values: [
      '000000000000000000000000000000000200000018000000',
      '010000000200000001000000000000000004000081020000',
      '020000000900000001000000010000000004000081020000',
    ],
    format: IntelConnectorPatchFormat.iceLake,
  ),
};

IntelConnectorPlatformTemplate _standardTemplate(
  String framebufferId,
  List<String> values,
) {
  return IntelConnectorPlatformTemplate.fromAllData(
    framebufferId: framebufferId,
    values: values,
  );
}
