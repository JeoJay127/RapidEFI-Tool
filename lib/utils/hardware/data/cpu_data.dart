class CpuCodenameEntry {
  final int family;
  final int model;
  final int stepping;
  final String codename;
  final String? nameHint;

  const CpuCodenameEntry({
    required this.family,
    required this.model,
    this.stepping = -1,
    required this.codename,
    this.nameHint,
  });
}

class CpuSignature {
  final int displayFamily;
  final int displayModel;
  final int stepping;

  const CpuSignature({
    required this.displayFamily,
    required this.displayModel,
    required this.stepping,
  });
}

class CpuInfomation {
  static const List<List<String>> identifier = [
    ["Arrow Lake-S", "Family 6 Model 198 Stepping 2"],
    ["Arrow Lake-H", "Family 6 Model 197 Stepping 2"],
    ["Arrow Lake-HX", "Family 6 Model 198 Stepping 2", "HX"],
    ["Arrow Lake-U", "Family 6 Model 181 Stepping 0"],
    ["Lunar Lake", "Family 6 Model 189 Stepping 1"],
    ["Meteor Lake-H", "Family 6 Model 170 Stepping 4", "H"],
    ["Meteor Lake-U", "Family 6 Model 170 Stepping 4", "U"],
    ["Raptor Lake-S", "Family 6 Model 183 Stepping 1"],
    ["Raptor Lake-S", "Family 6 Model 191 Stepping 2"],
    ["Raptor Lake-S", "Family 6 Model 191 Stepping 5"],
    ["Raptor Lake-E", "Family 6 Model 183 Stepping 1", "E"],
    ["Raptor Lake-HX", "Family 6 Model 183 Stepping 1", "HX"],
    ["Raptor Lake-HX", "Family 6 Model 191 Stepping 2", "HX"],
    ["Raptor Lake-H", "Family 6 Model 186 Stepping 2"],
    ["Raptor Lake-PX", "Family 6 Model 186 Stepping 2", "05H"],
    ["Raptor Lake-P", "Family 6 Model 186 Stepping 2", "P"],
    ["Raptor Lake-U", "Family 6 Model 186 Stepping 3"],
    ["Alder Lake-S", "Family 6 Model 151 Stepping 2"],
    ["Alder Lake-S", "Family 6 Model 151 Stepping 5"],
    ["Alder Lake-HX", "Family 6 Model 151 Stepping 2", "HX"],
    ["Alder Lake-H", "Family 6 Model 154 Stepping 3"],
    ["Alder Lake-P", "Family 6 Model 154 Stepping 3", "P"],
    ["Alder Lake-U", "Family 6 Model 154 Stepping 4"],
    ["Alder Lake-P", "Family 6 Model 154 Stepping 4", "P"],
    ["Alder Lake-N", "Family 6 Model 190 Stepping 0"],
    ["Lakefield", "Family 6 Model 138 Stepping 1"],
    ["Rocket Lake-S", "Family 6 Model 167 Stepping 1"],
    ["Rocket Lake-S", "Family 6 Model 186 Stepping 2", "-11"],
    ["Rocket Lake-E", "Family 6 Model 167 Stepping 1", "Xeon E"],
    ["Tiger Lake-H", "Family 6 Model 141 Stepping 1"],
    ["Tiger Lake-B", "Family 6 Model 141 Stepping 1", "B"],
    ["Tiger Lake-UP3", "Family 6 Model 140 Stepping 2"],
    ["Tiger Lake-H35", "Family 6 Model 140 Stepping 2", "H"],
    ["Tiger Lake-UP3", "Family 6 Model 140 Stepping 1"],
    ["Tiger Lake-H35", "Family 6 Model 140 Stepping 1", "H"],
    ["Tiger Lake-UP4", "Family 6 Model 140 Stepping 1", "0G"],
    ["Ice Lake-U", "Family 6 Model 126 Stepping 5"],
    ["Ice Lake-SP", "Family 6 Model 106 Stepping 6"],
    ["Ice Lake-SP", "Family 6 Model 85 Stepping 0"],
    ["Comet Lake-S", "Family 6 Model 165 Stepping 3"],
    ["Comet Lake-S", "Family 6 Model 165 Stepping 4"],
    ["Comet Lake-S", "Family 6 Model 165 Stepping 5"],
    ["Comet Lake-W", "Family 6 Model 165 Stepping 5", "Xeon W"],
    ["Comet Lake-H", "Family 6 Model 165 Stepping 2"],
    ["Comet Lake-U", "Family 6 Model 142 Stepping 12"],
    ["Comet Lake-U", "Family 6 Model 166 Stepping 0"],
    ["Coffee Lake-S", "Family 6 Model 142 Stepping 10"],
    ["Coffee Lake-S", "Family 6 Model 158 Stepping 10"],
    ["Coffee Lake-S", "Family 6 Model 158 Stepping 11"],
    ["Coffee Lake-S", "Family 6 Model 158 Stepping 12"],
    ["Coffee Lake-S", "Family 6 Model 158 Stepping 13"],
    ["Coffee Lake-E", "Family 6 Model 158 Stepping 10", "Xeon E"],
    ["Coffee Lake-E", "Family 6 Model 158 Stepping 13", "Xeon E"],
    ["Coffee Lake-H", "Family 6 Model 158 Stepping 10", "H"],
    ["Coffee Lake-H", "Family 6 Model 158 Stepping 13", "H"],
    ["Coffee Lake-U", "Family 6 Model 158 Stepping 10", "U"],
    ["Coffee Lake-U", "Family 6 Model 158 Stepping 13"],
    ["Cannon Lake-U", "Family 6 Model 102 Stepping 3"],
    ["Whiskey Lake-U", "Family 6 Model 142 Stepping 11"],
    ["Whiskey Lake-U", "Family 6 Model 142 Stepping 12", "-8"],
    ["Kaby Lake", "Family 6 Model 158 Stepping 9"],
    ["Kaby Lake", "Family 6 Model 142 Stepping 9"],
    ["Kaby Lake", "Family 6 Model 142 Stepping 10", "U"],
    ["Kaby Lake", "Family 6 Model 142 Stepping 10", "-7"],
    ["Kaby Lake-H", "Family 6 Model 158 Stepping 9", "H"],
    ["Kaby Lake-X", "Family 6 Model 158 Stepping 9", "X"],
    ["Kaby Lake-G", "Family 6 Model 158 Stepping 9", "G"],
    ["Amber Lake-Y", "Family 6 Model 142 Stepping 9", "Y"],
    ["Amber Lake-Y", "Family 6 Model 142 Stepping 12", "Y"],
    ["Cascade Lake-X", "Family 6 Model 85 Stepping 7"],
    ["Cascade Lake-P", "Family 6 Model 85 Stepping 7", "Xeon"],
    ["Cascade Lake-W", "Family 6 Model 85 Stepping 7", "Xeon W"],
    ["Skylake", "Family 6 Model 94 Stepping 1"],
    ["Skylake", "Family 6 Model 94 Stepping 3"],
    ["Skylake", "Family 6 Model 78 Stepping 3"],
    ["Skylake-X", "Family 6 Model 85 Stepping 4"],
    ["Broadwell", "Family 6 Model 71 Stepping 1"],
    ["Broadwell", "Family 6 Model 61 Stepping 4"],
    ["Broadwell-H", "Family 6 Model 71 Stepping 1", "H"],
    ["Broadwell-U", "Family 6 Model 61 Stepping 4", "U"],
    ["Broadwell-Y", "Family 6 Model 61 Stepping 4", "Y"],
    ["Broadwell-E", "Family 6 Model 79 Stepping 1"],
    ["Broadwell-E", "Family 6 Model 79 Stepping 0"],
    ["Haswell", "Family 6 Model 60 Stepping 1"],
    ["Haswell", "Family 6 Model 60 Stepping 3"],
    ["Haswell-ULT", "Family 6 Model 69 Stepping 1", "U"],
    ["Haswell-ULX", "Family 6 Model 69 Stepping 1", "Y"],
    ["Haswell-H", "Family 6 Model 60 Stepping 3", "H"],
    ["Haswell-H", "Family 6 Model 60 Stepping 3", "E"],
    ["Haswell-H", "Family 6 Model 70 Stepping 1"],
    ["Haswell-E", "Family 6 Model 60 Stepping 3", "Xeon"],
    ["Haswell-EP", "Family 6 Model 63 Stepping 2"],
    ["Haswell-EX", "Family 6 Model 63 Stepping 4"],
    ["Ivy Bridge", "Family 6 Model 62 Stepping 4"],
    ["Ivy Bridge", "Family 6 Model 58 Stepping 9"],
    ["Ivy Bridge-E", "Family 6 Model 58 Stepping 9", "Xeon"],
    ["Ivy Bridge-E", "Family 6 Model 62 Stepping 4", "Xeon"],
    ["Ivy Bridge-E", "Family 6 Model 62 Stepping 7", "Xeon"],
    ["Sandy Bridge", "Family 6 Model 45 Stepping 7"],
    ["Sandy Bridge", "Family 6 Model 42 Stepping 7"],
    ["Sandy Bridge-E", "Family 6 Model 42 Stepping 7", "Xeon"],
    ["Sandy Bridge-E", "Family 6 Model 45 Stepping 7", "Xeon"],
    ["Summit Ridge", "Family 23 Model 1 Stepping 1"],
    ["Beckton", "Family 6 Model 46 Stepping 6"],
    ["Westmere-EX", "Family 6 Model 47 Stepping 2"],
    ["Gulftown", "Family 6 Model 44 Stepping 2"],
    ["Westmere-EP", "Family 6 Model 44 Stepping 2", "Xeon"],
    ["Clarkdale", "Family 6 Model 37 Stepping 5"],
    ["Arrandale", "Family 6 Model 37 Stepping 5", "U"],
    ["Arrandale", "Family 6 Model 37 Stepping 5", "P"],
    ["Arrandale", "Family 6 Model 37 Stepping 5", "E"],
    ["Arrandale", "Family 6 Model 37 Stepping 5", "M"],
    ["Clarkdale", "Family 6 Model 37 Stepping 2"],
    ["Arrandale", "Family 6 Model 37 Stepping 2", "P"],
    ["Arrandale", "Family 6 Model 37 Stepping 2", "U"],
    ["Lynnfield", "Family 6 Model 30 Stepping 5"],
    ["Harpertown", "Family 6 Model 23 Stepping 10", "Xeon"],
    ["Jasper Forest", "Family 6 Model 30 Stepping 4"],
    ["Clarksfield", "Family 6 Model 30 Stepping 5", "M"],
    ["Gainestown", "Family 6 Model 26 Stepping 5"],
    ["Bloomfield", "Family 6 Model 26 Stepping 5", "Xeon W"],
    ["Bloomfield", "Family 6 Model 26 Stepping 4"],
    ["Whitehaven", "Family 23 Model 1 Stepping 1", "Threadripper"],
    ["Raven Ridge", "Family 23 Model 17 Stepping 0"],
    ["Great Horned Owl", "Family 23 Model 17 Stepping 0", " V1"],
    ["Dali", "Family 23 Model 24 Stepping 1", "Ryzen 3 32"],
    ["Dali", "Family 23 Model 32 Stepping 1", "Ryzen 3 32"],
    ["Banded Kestrel", "Family 23 Model 24 Stepping 1", " R10"],
    ["Banded Kestrel", "Family 23 Model 32 Stepping 1", " R1"],
    ["River Hawk", "Family 23 Model 24 Stepping 1", " R2"],
    ["Pinnacle Ridge", "Family 23 Model 8 Stepping 2"],
    ["Colfax", "Family 23 Model 8 Stepping 2", "Threadripper"],
    ["Picasso", "Family 23 Model 24 Stepping 1"],
    ["Picasso", "Family 23 Model 96 Stepping 1"],
    ["Grey Hawk", "Family 23 Model 96 Stepping 1", " V2"],
    ["Matisse", "Family 23 Model 113 Stepping 0"],
    ["Castle Peak", "Family 23 Model 49 Stepping 0"],
    ["Renoir", "Family 23 Model 132 Stepping 0"],
    ["Renoir", "Family 23 Model 71 Stepping 0"],
    ["Renoir", "Family 23 Model 96 Stepping 1", " 4"],
    ["Lucienne", "Family 23 Model 104 Stepping 1"],
    ["Vermeer", "Family 25 Model 33 Stepping 0"],
    ["Vermeer", "Family 25 Model 33 Stepping 2"],
    ["Cezanne", "Family 25 Model 80 Stepping 0"],
    ["Barcelo", "Family 25 Model 80 Stepping 0", "25"],
    ["Rembrandt", "Family 25 Model 68 Stepping 1"],
    ["Mendocino", "Family 23 Model 160 Stepping 0"],
    ["Barcelo-R", "Family 25 Model 80 Stepping 0", " 7"],
    ["Rembrandt-R", "Family 25 Model 68 Stepping 1", " 7"],
    ["V3000", "Family 25 Model 68 Stepping 1", " V3"],
    ["Chagall", "Family 25 Model 8 Stepping 2"],
    ["Raphael", "Family 25 Model 97 Stepping 2"],
    ["Storm Peak", "Family 25 Model 24 Stepping 1"],
    ["Phoenix", "Family 25 Model 117 Stepping 2"],
    ["Phoenix", "Family 25 Model 120 Stepping 0"],
    ["Phoenix", "Family 25 Model 116 Stepping 1"],
    ["Dragon Range", "Family 25 Model 97 Stepping 2", "45H"],
    ["Hawk Point", "Family 25 Model 117 Stepping 2", " 8"],
    ["Hawk Point", "Family 25 Model 124 Stepping 0"],
    ["Granite Ridge", "Family 26 Model 68 Stepping 0"],
    ["Strix Point", "Family 26 Model 36 Stepping 0"],
    ["Trinity", "Family 21 Model 16 Stepping 1"],
  ];

  static final List<CpuCodenameEntry> _intelEntries = [];
  static final List<CpuCodenameEntry> _amdEntries = [];
  static bool _initialized = false;

  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    final descRegex = RegExp(
      r'Family\s+(\d+)\s+Model\s+(\d+)\s+Stepping\s+(\d+)',
      caseSensitive: false,
    );

    for (final entry in identifier) {
      final codename = entry[0];
      final desc = entry[1];
      final nameHint = entry.length > 2 ? entry[2] : null;

      final match = descRegex.firstMatch(desc);
      if (match == null) continue;

      final family = int.parse(match.group(1)!);
      final model = int.parse(match.group(2)!);
      final stepping = int.parse(match.group(3)!);

      final entry_ = CpuCodenameEntry(
        family: family,
        model: model,
        stepping: stepping,
        codename: codename,
        nameHint: nameHint,
      );

      if (family == 6) {
        _intelEntries.add(entry_);
      } else {
        _amdEntries.add(entry_);
      }
    }
  }

  static CpuSignature? parseProcessorSignature(String processorId) {
    final cleaned = processorId.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (cleaned.length < 8) return null;

    final eaxStr = cleaned.substring(cleaned.length - 8);
    final eax = int.tryParse(eaxStr, radix: 16);
    if (eax == null) return null;

    final baseStepping = eax & 0xF;
    final baseModel = (eax >> 4) & 0xF;
    final baseFamily = (eax >> 8) & 0xF;
    final extendedModel = (eax >> 16) & 0xF;
    final extendedFamily = (eax >> 20) & 0xFF;

    final displayFamily =
        baseFamily == 0xF ? baseFamily + extendedFamily : baseFamily;
    final displayModel = (baseFamily == 0x6 || baseFamily == 0xF)
        ? baseModel + (extendedModel << 4)
        : baseModel;

    if (displayFamily <= 0) return null;

    return CpuSignature(
      displayFamily: displayFamily,
      displayModel: displayModel,
      stepping: baseStepping,
    );
  }

  static CpuSignature? parseCpuIdentifier(String identifier) {
    final pattern = RegExp(
      r'Family\s+(\d+)\s+Model\s+(\d+)\s+Stepping\s+(\d+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(identifier);
    if (match == null) return null;

    final family = int.parse(match.group(1)!);
    final model = int.parse(match.group(2)!);
    final stepping = int.parse(match.group(3)!);

    if (family <= 0 || model < 0 || stepping < 0) return null;

    return CpuSignature(
      displayFamily: family,
      displayModel: model,
      stepping: stepping,
    );
  }

  static bool cpuNameMatchesHint(String cpuName, String hint) {
    const skuSuffixes = {
      'U',
      'Y',
      'H',
      'P',
      'E',
      'B',
      'M',
      'X',
      'G',
      'HX',
      'HK',
    };

    if (skuSuffixes.contains(hint.toUpperCase())) {
      final escaped = RegExp.escape(hint);
      final suffixPattern = RegExp(
        '(?:\\d+[A-Z0-9]*$escaped\\b|\\b$escaped\\b)',
        caseSensitive: false,
      );
      return suffixPattern.hasMatch(cpuName);
    }

    return cpuName.toLowerCase().contains(hint.toLowerCase());
  }

  static String? _lookupIntelCodename(CpuSignature sig, String cpuName) {
    String? fallback;
    for (final entry in _intelEntries) {
      if (entry.family != sig.displayFamily ||
          entry.model != sig.displayModel) {
        continue;
      }
      if (entry.stepping >= 0 && entry.stepping != sig.stepping) continue;

      if (entry.nameHint != null) {
        if (cpuNameMatchesHint(cpuName, entry.nameHint!)) {
          return entry.codename;
        }
      } else {
        fallback ??= entry.codename;
      }
    }
    return fallback;
  }

  static String? _lookupAmdCodename(CpuSignature sig, String cpuName) {
    String? fallback;
    final familyHex = sig.displayFamily.toRadixString(16).toUpperCase();
    for (final entry in _amdEntries) {
      if (entry.family != sig.displayFamily ||
          entry.model != sig.displayModel) {
        continue;
      }
      if (entry.stepping >= 0 && entry.stepping != sig.stepping) continue;

      if (entry.nameHint != null) {
        if (cpuNameMatchesHint(cpuName, entry.nameHint!)) {
          return '${entry.codename} (${familyHex}h)';
        }
      } else {
        fallback ??= entry.codename;
      }
    }
    return fallback != null ? '$fallback (${familyHex}h)' : null;
  }

  static bool isIntelCpu(String? manufacturer, String? name) {
    final m = (manufacturer ?? '').toLowerCase();
    final n = (name ?? '').toLowerCase();
    return m.contains('intel') || n.contains('intel');
  }

  static bool isAmdCpu(String? manufacturer, String? name) {
    final m = (manufacturer ?? '').toLowerCase();
    final n = (name ?? '').toLowerCase();
    return m.contains('amd') ||
        m.contains('authenticamd') ||
        n.contains('amd') ||
        n.contains('ryzen') ||
        n.contains('threadripper') ||
        n.contains('epyc');
  }

  static String? computeCpuCodename({
    required String processorId,
    required String description,
    required String caption,
    required String name,
    required String manufacturer,
  }) {
    _ensureInitialized();

    CpuSignature? sig = parseProcessorSignature(processorId);

    sig ??= parseCpuIdentifier(description);
    sig ??= parseCpuIdentifier(caption);

    if (sig == null) return null;

    if (isIntelCpu(manufacturer, name)) {
      return _lookupIntelCodename(sig, name);
    }
    if (isAmdCpu(manufacturer, name)) {
      return _lookupAmdCodename(sig, name);
    }

    return _lookupIntelCodename(sig, name) ?? _lookupAmdCodename(sig, name);
  }
}
