import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_code_registry.dart';
import 'package:rapidefi/utils/hardware/config/hardware_config_build_context.dart';
import 'package:rapidefi/utils/hardware/data/gpu_codename_data.dart';
import 'package:rapidefi/utils/hardware/model/gpu.dart';

class HardwarePlatformSelection {
  const HardwarePlatformSelection({
    required this.cpuType,
    required this.platformType,
    required this.platformCode,
  });

  final CpuType cpuType;
  final PlatformType platformType;
  final String platformCode;
}

class HardwarePlatformResolver {
  const HardwarePlatformResolver();

  HardwarePlatformSelection resolve(HardwareConfigBuildContext context) {
    final cpuType = _resolveCpuType(context);
    final platformType = _resolvePlatformType(context);
    final platformCode = _resolvePlatformCode(
      context,
      cpuType: cpuType,
      platformType: platformType,
    );

    return HardwarePlatformSelection(
      cpuType: cpuType,
      platformType: platformType,
      platformCode: platformCode,
    );
  }

  CpuType _resolveCpuType(HardwareConfigBuildContext context) {
    final optionCpuType = context.options.cpuType;
    if (optionCpuType != null && optionCpuType != CpuType.unknown) {
      return optionCpuType;
    }

    for (final cpu in context.cpus) {
      final manufacturer = _lower(cpu.manufacturer);
      final name = _lower(cpu.name);

      if (manufacturer.contains('intel') || name.contains('intel')) {
        return CpuType.intel;
      }

      if (manufacturer.contains('amd') ||
          manufacturer.contains('authenticamd') ||
          name.contains('amd') ||
          name.contains('ryzen') ||
          name.contains('threadripper') ||
          name.contains('epyc')) {
        return CpuType.amd;
      }
    }

    throw UnsupportedError('无法根据 CPU 信息识别平台类型');
  }

  PlatformType _resolvePlatformType(HardwareConfigBuildContext context) {
    final optionPlatformType = context.options.platformType;
    if (optionPlatformType != null) {
      return optionPlatformType;
    }

    final text = _motherboardText(context);

    if (_containsAny(text, const ['laptop', 'notebook', 'portable', '笔记本'])) {
      return PlatformType.laptop;
    }

    if (_containsAny(text, const ['nuc', 'mini pc', 'mini-pc', '迷你主机'])) {
      return PlatformType.nuc;
    }

    if (_containsAny(text, const ['hedt', 'workstation', 'server', '工作站'])) {
      return PlatformType.hedt;
    }

    if (_looksLikeHedtText(text) ||
        _intelHedtCpuCandidates(_cpuText(context)).isNotEmpty) {
      return PlatformType.hedt;
    }

    return PlatformType.desktop;
  }

  String _resolvePlatformCode(
    HardwareConfigBuildContext context, {
    required CpuType cpuType,
    required PlatformType platformType,
  }) {
    final optionCode = context.options.platformCode;
    if (optionCode != null && optionCode.trim().isNotEmpty) {
      if (PlatformCodeRegistry.contains(cpuType, platformType, optionCode)) {
        return optionCode;
      }
      throw UnsupportedError('当前 CPU/平台类型不支持指定的平台代号: $optionCode');
    }

    final code = _platformCodeFromCpu(context, cpuType, platformType) ??
        _platformCodeFromIntegratedGpu(context, cpuType, platformType) ??
        _platformCodeFromMotherboard(context, cpuType, platformType);

    if (code != null) {
      return code;
    }

    throw UnsupportedError('无法根据 CPU、主板、核显确定平台代号');
  }

  String? _platformCodeFromCpu(
    HardwareConfigBuildContext context,
    CpuType cpuType,
    PlatformType platformType,
  ) {
    final candidates = <String>[];

    for (final cpu in context.cpus) {
      final codename = _lower(cpu.codename);
      final name = _lower(cpu.name);
      final text = '$codename $name';

      candidates.addAll(_platformCodeCandidatesForCpuText(
        text,
        cpuType: cpuType,
        platformType: platformType,
      ));
    }

    return _firstSupportedCode(cpuType, platformType, candidates);
  }

  String? _platformCodeFromMotherboard(
    HardwareConfigBuildContext context,
    CpuType cpuType,
    PlatformType platformType,
  ) {
    final text = _motherboardText(context);

    if (text.isEmpty) return null;

    // 这里保留主板信息辅助判断，是为了修正
    // 仅靠 CPU 信息得出的结果，尤其是 HEDT、笔记本和 NUC 平台。
    return _firstSupportedCode(
      cpuType,
      platformType,
      _platformCodeCandidatesForCpuText(
        text,
        cpuType: cpuType,
        platformType: platformType,
      ),
    );
  }

  String? _platformCodeFromIntegratedGpu(
    HardwareConfigBuildContext context,
    CpuType cpuType,
    PlatformType platformType,
  ) {
    final candidates = <String>[];

    final entries =
        context.hardwareInfo.graphicsInfoList?.graphicsCards?.entries ??
            const <MapEntry<String, GraphicsCard>>[];

    for (final entry in entries) {
      final gpu = entry.value;
      if (!_isIntegratedGpu(gpu)) continue;

      final codenameFromDeviceId =
          GpuCodenameData.lookupCodename(gpu.deviceID ?? '');
      final text = _lower(
        [
          entry.key,
          gpu.codename,
          codenameFromDeviceId,
          gpu.manufacturer,
          gpu.deviceID,
          gpu.deviceType,
        ].whereType<String>().join(' '),
      );

      candidates.addAll(_platformCodeCandidatesForCpuText(
        text,
        cpuType: cpuType,
        platformType: platformType,
      ));
    }

    return _firstSupportedCode(cpuType, platformType, candidates);
  }

  List<String> _platformCodeCandidatesForCpuText(
    String text, {
    required CpuType cpuType,
    required PlatformType platformType,
  }) {
    if (text.isEmpty) return const <String>[];

    if (cpuType == CpuType.amd) {
      return _amdPlatformCodeCandidates(text, platformType);
    }

    if (cpuType != CpuType.intel) {
      return const <String>[];
    }

    if (platformType == PlatformType.hedt) {
      final hedtCandidates = _intelHedtCpuCandidates(text);
      if (hedtCandidates.isNotEmpty) return hedtCandidates;

      if (_containsAny(text, const ['cascade lake'])) {
        return const ['cascade_lake_x_w', 'skylake_x_w'];
      }
      if (_containsAny(text, const [
        'skylake-x',
        'skylake x',
        'skylake-w',
        'skylake-s',
      ])) {
        return const ['skylake_x_w'];
      }
      if (_containsAny(text, const ['broadwell-e', 'broadwell e'])) {
        return const ['broadwell_e'];
      }
      if (_containsAny(text, const ['haswell-e', 'haswell e'])) {
        return const ['haswell_e'];
      }
      if (_containsAny(text, const ['ivy bridge-e', 'ivy bridge e'])) {
        return const ['ivy_bridge_e'];
      }
      if (_containsAny(text, const ['sandy bridge-e', 'sandy bridge e'])) {
        return const ['sandy_bridge_e'];
      }
      if (_containsAny(text, const [
        'nehalem',
        'westmere',
        'bloomfield',
        'gulftown',
      ])) {
        return const ['nehalem_westmere'];
      }
    }

    final generationCandidates = _intelGenerationCandidates(text, platformType);
    if (generationCandidates.isNotEmpty) return generationCandidates;

    final integratedGpuCandidates = _intelIntegratedGpuCandidates(text);
    if (integratedGpuCandidates.isNotEmpty) return integratedGpuCandidates;

    final chipsetCandidates = _intelChipsetCandidates(text, platformType);
    if (chipsetCandidates.isNotEmpty) return chipsetCandidates;

    if (_containsAny(text, const ['arrow lake'])) {
      return const ['arrow_lake'];
    }
    if (_containsAny(text, const ['raptor lake refresh'])) {
      return const ['raptor_lake_refresh', 'raptor_lake'];
    }
    if (_containsAny(text, const ['raptor lake'])) {
      return const ['raptor_lake'];
    }
    if (_containsAny(text, const ['alder lake'])) {
      return const ['alder_lake'];
    }
    if (_containsAny(text, const ['rocket lake'])) {
      return const ['rocket_lake'];
    }
    if (_containsAny(text, const ['tiger lake'])) {
      return const ['tiger_lake'];
    }
    if (_containsAny(text, const ['ice lake'])) {
      return const ['ice_lake'];
    }
    if (_containsAny(text, const ['comet lake'])) {
      return const ['comet_lake'];
    }
    if (_containsAny(text, const ['coffee lake', 'whiskey lake'])) {
      return const ['coffee_lake_8th', 'coffee_lake_9th'];
    }
    if (_containsAny(text, const ['kaby lake', 'amber lake'])) {
      return const ['kaby_lake'];
    }
    if (_containsAny(text, const ['skylake'])) {
      return const ['skylake'];
    }
    if (_containsAny(text, const ['broadwell'])) {
      return const ['broadwell'];
    }
    if (_containsAny(text, const ['haswell'])) {
      return const ['haswell'];
    }
    if (_containsAny(text, const ['ivy bridge'])) {
      return const ['ivy_bridge'];
    }
    if (_containsAny(text, const ['sandy bridge'])) {
      return const ['sandy_bridge'];
    }
    if (_containsAny(text, const ['clarksfield', 'arrandale'])) {
      return const ['clarksfield_arrandale', 'lynnfield'];
    }
    if (_containsAny(text, const ['lynnfield', 'clarkdale'])) {
      return const ['lynnfield'];
    }
    if (_containsAny(text, const ['penryn', 'wolfdale', 'yorkfield'])) {
      return const ['penryn'];
    }

    return const <String>[];
  }

  List<String> _amdPlatformCodeCandidates(
    String text,
    PlatformType platformType,
  ) {
    if (_containsAny(text, const [
      'bulldozer',
      'jaguar',
      'trinity',
      'richland',
      'kaveri',
      'carrizo',
      'bristol',
    ])) {
      return const ['bulldozer_jaguar'];
    }

    if (platformType == PlatformType.hedt ||
        platformType == PlatformType.desktop ||
        _containsAny(text, const [
          'threadripper',
          'whitehaven',
          'colfax',
          'castle peak',
          'chagall',
          'storm peak',
        ])) {
      return const ['ryzen_threadripper'];
    }

    return const ['ryzen'];
  }

  String? _firstSupportedCode(
    CpuType cpuType,
    PlatformType platformType,
    Iterable<String> candidates,
  ) {
    for (final code in candidates) {
      if (PlatformCodeRegistry.contains(cpuType, platformType, code)) {
        return code;
      }
    }
    return null;
  }

  bool _isIntegratedGpu(GraphicsCard gpu) {
    final type = _lower(gpu.deviceType);
    final manufacturer = _lower(gpu.manufacturer);
    final deviceId = _upper(gpu.deviceID);

    return type.contains('核心') ||
        type.contains('integrated') ||
        type.contains('internal') ||
        (manufacturer.contains('intel') && deviceId.startsWith('8086-'));
  }

  bool _containsAny(String text, Iterable<String> values) {
    return values.any((value) => text.contains(value));
  }

  String _cpuText(HardwareConfigBuildContext context) {
    return _lower(
      context.cpus
          .map((cpu) => [
                cpu.manufacturer,
                cpu.name,
                cpu.codename,
              ].whereType<String>().join(' '))
          .join(' '),
    );
  }

  String _motherboardText(HardwareConfigBuildContext context) {
    final board = context.hardwareInfo.motherBoard;
    final rawBoard = context.rawSection('Motherboard');
    final rawFields = <String>[];

    if (rawBoard is Map) {
      for (final key in const [
        'Chipset',
        'Product',
        'Model',
        'Name',
        'DeviceDesc',
        'Device ID',
        'Platform',
      ]) {
        final value = rawBoard[key];
        if (value != null) rawFields.add(value.toString());
      }
    }

    return _lower(
      [
        board?.chipset,
        board?.product,
        board?.model,
        board?.name,
        board?.platform,
        board?.deviceID,
        ...rawFields,
      ].whereType<String>().join(' '),
    );
  }

  bool _looksLikeHedtText(String text) {
    return _containsAny(text, const [
      'x58',
      'x79',
      'x99',
      'x299',
      'c602',
      'c604',
      'c606',
      'c612',
      'c621',
      'workstation',
      'server',
      'hedt',
    ]);
  }

  List<String> _intelGenerationCandidates(
    String text,
    PlatformType platformType,
  ) {
    final generation = _intelGenerationFromText(text);
    if (generation == null) {
      if (RegExp(r'\bcore\s+ultra\s+2\d{2}', caseSensitive: false)
          .hasMatch(text)) {
        return const ['arrow_lake'];
      }
      return const <String>[];
    }

    switch (generation) {
      case 11:
        return platformType == PlatformType.desktop
            ? const ['rocket_lake']
            : const ['tiger_lake'];
      case 12:
        return const ['alder_lake'];
      case 13:
        return const ['raptor_lake'];
      case 14:
        return const ['raptor_lake_refresh', 'raptor_lake'];
      case 15:
        return const ['arrow_lake'];
      default:
        return const <String>[];
    }
  }

  int? _intelGenerationFromText(String text) {
    final ordinalMatch = RegExp(
      r'\b(11|12|13|14|15)(?:th|st|nd|rd)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (ordinalMatch != null) {
      return int.tryParse(ordinalMatch.group(1)!);
    }

    final coreMatch = RegExp(
      r'\b(?:core\s+)?i[3579][-\s]?(\d{5})[a-z0-9]*\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (coreMatch != null) {
      return int.tryParse(coreMatch.group(1)!.substring(0, 2));
    }

    return null;
  }

  List<String> _intelHedtCpuCandidates(String text) {
    if (text.isEmpty) return const <String>[];

    if (RegExp(
      r'\b(i7[-\s]?(920|930|940|950|960|965|970|975|980x?))\b|\b(w35[2-8]0|w36[7-9]0|x56[3-9]0|l56(09|18|30|38|40))\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return const ['nehalem_westmere'];
    }

    if (RegExp(
      r'\be5[-\s]?(16\d{2}|26\d{2})\s*v4\b|\bi7[-\s]?69\d{2}x?\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return const ['broadwell_e'];
    }

    if (RegExp(
      r'\be5[-\s]?[12]\d{3}\s*v3\b|\bi7[-\s]?5\d{3}x?\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return const ['haswell_e'];
    }

    if (RegExp(
      r'\be5[-\s]?(16\d{2}|26\d{2})\s*v2\b|\bi7[-\s]?(4960x|4930k|4820k)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return const ['ivy_bridge_e'];
    }

    if (RegExp(
      r'\be5[-\s]?(16\d{2}|26\d{2})\b(?!\s*v[2-9])|\bi7[-\s]?(3960x|3970x|3930k|3820)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return const ['sandy_bridge_e'];
    }

    if (RegExp(
      r'\b(i9[-\s]?(7|9|10)\d{3}(x|xe?)?)\b|\b(i9[-\s]?78\d{2}xe?)\b|\bxeon\s+(w|silver|bronze)\s+\d{4}\b|\b(w[-\s]?\d{4}|w\d{4}|silver\s+\d{4}|bronze\s+\d{4})\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return const ['skylake_x_w'];
    }

    return const <String>[];
  }

  List<String> _intelChipsetCandidates(
    String text,
    PlatformType platformType,
  ) {
    if (platformType == PlatformType.hedt) {
      if (_containsAny(text, const ['x299', 'c621', 'c422'])) {
        return const ['skylake_x_w'];
      }
      if (_containsAny(text, const ['x99', 'c612'])) {
        return const ['haswell_e', 'broadwell_e'];
      }
      if (_containsAny(text, const ['x79', 'c602', 'c604', 'c606'])) {
        return const ['sandy_bridge_e', 'ivy_bridge_e'];
      }
      if (_containsAny(text, const ['x58'])) {
        return const ['nehalem_westmere'];
      }
    }

    if (_containsAny(text, const ['z890', 'h870', 'b860'])) {
      return const ['arrow_lake'];
    }
    if (_containsAny(text, const ['z790', 'h770', 'b760'])) {
      return const ['raptor_lake_refresh', 'raptor_lake'];
    }
    if (_containsAny(text, const ['z690', 'h670', 'b660', 'h610'])) {
      return const ['alder_lake'];
    }
    if (_containsAny(
      text,
      const ['z590', 'h570', 'b560', 'h510', 'q570', 'w580'],
    )) {
      return const ['rocket_lake'];
    }
    if (_containsAny(text, const ['z490', 'h470', 'b460', 'h410'])) {
      return const ['comet_lake'];
    }
    if (_containsAny(text, const ['z390', 'z370', 'h370', 'b360', 'h310'])) {
      return const ['coffee_lake_9th', 'coffee_lake_8th'];
    }
    if (_containsAny(text, const ['z270', 'h270', 'b250'])) {
      return const ['kaby_lake'];
    }
    if (_containsAny(text, const ['z170', 'h170', 'b150', 'h110'])) {
      return const ['skylake'];
    }
    if (_containsAny(text, const ['z97', 'z87', 'h97', 'h87', 'b85', 'h81'])) {
      return const ['haswell'];
    }
    if (_containsAny(text, const ['z77', 'h77', 'b75','q75','q77'])) {
      return const ['ivy_bridge'];
    }
    if (_containsAny(text, const ['z68', 'p67', 'q67','h67', 'h61'])) {
      return const ['sandy_bridge'];
    }

    return const <String>[];
  }

  List<String> _intelIntegratedGpuCandidates(String text) {
    if (_containsAny(text, const ['iris xe', 'uhd graphics xe'])) {
      return const ['tiger_lake'];
    }
    if (_containsAny(text, const ['uhd graphics 730', 'uhd graphics 770'])) {
      return const ['alder_lake', 'raptor_lake', 'raptor_lake_refresh'];
    }
    if (_containsAny(text, const ['uhd graphics 750'])) {
      return const ['rocket_lake'];
    }
    if (_containsAny(text, const ['iris plus graphics', 'uhd graphics g'])) {
      return const ['ice_lake'];
    }
    if (_containsAny(text, const ['uhd graphics 630'])) {
      return const ['coffee_lake_8th', 'coffee_lake_9th', 'kaby_lake'];
    }
    if (_containsAny(text, const ['uhd graphics 620', 'hd graphics 630'])) {
      return const ['kaby_lake'];
    }
    if (_containsAny(text, const ['hd graphics 530', 'iris pro 580'])) {
      return const ['skylake'];
    }
    if (_containsAny(text, const [
      'hd graphics 5500',
      'hd graphics 6000',
      'iris graphics 6100',
      'iris pro graphics 6200',
    ])) {
      return const ['broadwell'];
    }
    if (_containsAny(text, const [
      'hd graphics 4200',
      'hd graphics 4400',
      'hd graphics 4600',
      'hd graphics 5000',
      'iris graphics 5100',
      'iris pro graphics 5200',
      'p4600',
      'p4700',
    ])) {
      return const ['haswell'];
    }
    if (_containsAny(text, const [
      'hd graphics 2500',
      'hd graphics 4000',
    ])) {
      return const ['ivy_bridge'];
    }
    if (_containsAny(text, const [
      'hd graphics 2000',
      'hd graphics 3000',
    ])) {
      return const ['sandy_bridge'];
    }

    return const <String>[];
  }

  String _lower(String? value) => value?.trim().toLowerCase() ?? '';

  String _upper(String? value) => value?.trim().toUpperCase() ?? '';
}
