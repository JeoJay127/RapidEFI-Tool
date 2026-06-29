import 'package:rapidefi/utils/hardware/analysis/gpu_compatibility_data.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis_models.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_utils.dart';
import 'package:rapidefi/utils/config/support/macos_version.dart';
import 'package:rapidefi/utils/config/services/apple_alc_resolver.dart';
import 'package:rapidefi/utils/hardware/data/alc_data.dart';
import 'package:rapidefi/utils/hardware/data/gpu_codename_data.dart';
import 'package:rapidefi/utils/hardware/data/hardware_device_data.dart';
import 'package:rapidefi/utils/hardware/data/manufacturer_data.dart';

CompatibilityNote? cpuCompatibility(Map<String, dynamic> data) {
  final cpus = safeList(data['CPU']);
  if (cpus.isEmpty) return null;

  final cpu = safeMap(cpus.first);
  final simd = safeStr(cpu['SIMD Features']).toUpperCase();

  if (simd.contains('AVX2')) {
    return CompatibilityNote.supported('兼容');
  }

  if (simd.contains('SSE4')) {
    return CompatibilityNote.limited(
      '有限兼容\n最高支持 macOS Tahoe 26\n缺少 AVX2',
    );
  }

  return CompatibilityNote.unsupported(
    '不兼容\n最高支持 macOS El Capitan 10.11\n缺少 SSE4',
  );
}

String cpuCodename(Map<String, dynamic> cpu) => safeStr(cpu['Codename']);

bool cpuHasAvx2(Map<String, dynamic> data) {
  final cpus = safeList(data['CPU']);
  if (cpus.isEmpty) return false;

  return safeStr(safeMap(cpus.first)['SIMD Features'])
      .toUpperCase()
      .contains('AVX2');
}

bool isEntryIntelCpu(Map<String, dynamic> data) {
  final cpus = safeList(data['CPU']);
  if (cpus.isEmpty) return false;

  final name = safeStr(safeMap(cpus.first)['Name']).toLowerCase();

  return name.contains('celeron') || name.contains('pentium');
}

String? manufacturerBrandName(String manufacturer) {
  if (manufacturer.isEmpty) return null;
  final key = _manufacturerBrandKey(manufacturer);
  if (key == null) return null;
  final nameCN = ManufacturerData.manufacturers[key];
  if (nameCN != null && nameCN.isNotEmpty) return nameCN;
  return null;
}

String manufacturerBrandCode(String manufacturer) {
  if (manufacturer.isEmpty) return '';
  final key = _manufacturerBrandKey(manufacturer);
  if (key == null) {
    return manufacturer.split(RegExp(r'[\s,(\[]+')).first.toUpperCase();
  }
  return ManufacturerData.brandCodes[key] ?? key.toUpperCase();
}

String? _manufacturerBrandKey(String manufacturer) {
  final normalized = manufacturer.toLowerCase().replaceAll('_', ' ').trim();
  if (normalized.isEmpty) return null;

  final keys = ManufacturerData.manufacturers.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final key in keys) {
    final normalizedKey = key.toLowerCase();
    if (normalized == normalizedKey ||
        normalized.startsWith('$normalizedKey ') ||
        normalized.contains(' $normalizedKey ')) {
      return key;
    }
  }

  final firstWord = normalized.split(RegExp(r'[\s,(\[]+')).first;
  return ManufacturerData.manufacturers.containsKey(firstWord)
      ? firstWord
      : null;
}

String chipsetName(Map<String, dynamic> board) {
  return safeStr(board['Chipset']);
}

// ============================================================================
// GPU Compatibility
// ============================================================================

String gpuManufacturer(Map<String, dynamic> gpu) {
  final record = GpuCompatibilityData.findSync(safeStr(gpu['Device ID']));
  if (record != null && record.vendor.isNotEmpty) {
    return record.vendor;
  }

  final mfr = safeStr(gpu['Manufacturer']);
  if (mfr.isNotEmpty) return mfr;

  final id = GpuCompatibilityData.normalizeFullDeviceId(
    safeStr(gpu['Device ID']),
  ).toUpperCase();

  if (id.startsWith('8086-')) return 'Intel';
  if (id.startsWith('1002-') || id.startsWith('1022-')) return 'AMD';
  if (id.startsWith('10DE-')) return 'NVIDIA';

  return '';
}

String gpuCodename(Map<String, dynamic> gpu) {
  final record = GpuCompatibilityData.findSync(safeStr(gpu['Device ID']));
  if (record != null && record.codename.isNotEmpty) {
    return record.codename;
  }

  return safeStr(gpu['Codename']);
}

String gpuDisplayName(String fallbackName, Map<String, dynamic> gpu) {
  final record = GpuCompatibilityData.findSync(safeStr(gpu['Device ID']));

  if (record != null && record.name.isNotEmpty && record.name != record.id) {
    return record.name;
  }

  return deviceDisplayName(fallbackName, gpu);
}

bool isIntelGpuRecord(GpuCompatibilityRecord record) {
  return record.vendorId == '8086' ||
      record.vendor.toLowerCase().contains('intel');
}

bool hasOnlyVgaDisplays(Map<String, dynamic> data, String gpuName) {
  var hasMatched = false;

  for (final entry in hardwareDevices(data['Monitor'])) {
    final monitor = safeMap(entry.value);

    if (safeStr(monitor['Connected GPU']).toLowerCase() !=
        gpuName.toLowerCase()) {
      continue;
    }

    hasMatched = true;

    if (safeStr(monitor['Connector Type']).toUpperCase() != 'VGA') {
      return false;
    }
  }

  return hasMatched;
}

CompatibilityNote gpuEntryCompatibility(
  Map<String, dynamic> data,
  String name,
  Map<String, dynamic> gpu,
) {
  final facts = _readGpuSupportFacts(data, name, gpu);
  final decision = _decideGpuSupport(facts);
  final hint = _gpuSupportHint(decision);
  final output = _gpuSupportOutput(hint);
  return _toGpuSupportNote(output);
}

_GpuSupportFacts _readGpuSupportFacts(
  Map<String, dynamic> data,
  String name,
  Map<String, dynamic> gpu,
) {
  final rawId = safeStr(gpu['Device ID']);
  return _GpuSupportFacts(
    data: data,
    name: name,
    rawId: rawId,
    record: GpuCompatibilityData.findSync(rawId),
    isNootedRedApu: _isNootedRedSupportedIntegratedGpu(name, gpu),
    isDataReady: GpuCompatibilityData.isLoaded,
  );
}

_GpuSupportDecision _decideGpuSupport(
  _GpuSupportFacts evidence,
) {
  if (evidence.rawId.isEmpty) {
    return const _GpuSupportDecision(
      level: CompatibilityLevel.unsupported,
      message: '缺少设备 ID',
    );
  }

  if (evidence.isNootedRedApu) {
    return const _GpuSupportDecision(
      level: CompatibilityLevel.supported,
      message: 'NootedRed 支持',
    );
  }

  if (!evidence.isDataReady) {
    return const _GpuSupportDecision(
      level: CompatibilityLevel.limited,
      message: '兼容性加载中',
    );
  }

  final record = evidence.record;
  if (record == null) {
    return const _GpuSupportDecision(
      level: CompatibilityLevel.unsupported,
      message: '不兼容',
    );
  }

  if (isIntelGpuRecord(record)) {
    if (isEntryIntelCpu(evidence.data)) {
      return const _GpuSupportDecision(
        level: CompatibilityLevel.unsupported,
        message: '低端 Intel CPU 核显不支持',
      );
    }

    if (record.vgaLimited && hasOnlyVgaDisplays(evidence.data, evidence.name)) {
      return const _GpuSupportDecision(
        level: CompatibilityLevel.unsupported,
        message: 'VGA 输出不支持',
      );
    }
  }

  final hasAvx2Limit = record.avx2Limited && !cpuHasAvx2(evidence.data);
  final effectiveMaxDarwin = _effectiveMaxDarwin(record, hasAvx2Limit);
  final supportsLatest =
      DarwinVersion(effectiveMaxDarwin) >= DarwinVersion.latest;
  final detail = _gpuSupportDetail(
    record: record,
    effectiveMaxDarwin: effectiveMaxDarwin,
    hasAvx2Limit: hasAvx2Limit,
  );

  if (supportsLatest && !hasAvx2Limit) {
    return _GpuSupportDecision(
      level: CompatibilityLevel.supported,
      message: detail,
    );
  }

  return _GpuSupportDecision(
    level: CompatibilityLevel.limited,
    message: detail,
  );
}

_GpuSupportHint _gpuSupportHint(
  _GpuSupportDecision conclusion,
) {
  return _GpuSupportHint(
    level: conclusion.level,
    configMessage: conclusion.message,
  );
}

_GpuSupportOutput _gpuSupportOutput(
  _GpuSupportHint advice,
) {
  return _GpuSupportOutput(
    level: advice.level,
    userMessage: advice.configMessage,
  );
}

CompatibilityNote _toGpuSupportNote(
  _GpuSupportOutput action,
) {
  return switch (action.level) {
    CompatibilityLevel.supported => CompatibilityNote.supported(
        action.userMessage,
      ),
    CompatibilityLevel.limited => CompatibilityNote.limited(
        action.userMessage,
      ),
    CompatibilityLevel.unsupported => CompatibilityNote.unsupported(
        action.userMessage,
      ),
  };
}

class _GpuSupportFacts {
  const _GpuSupportFacts({
    required this.data,
    required this.name,
    required this.rawId,
    required this.record,
    required this.isNootedRedApu,
    required this.isDataReady,
  });

  final Map<String, dynamic> data;
  final String name;
  final String rawId;
  final GpuCompatibilityRecord? record;
  final bool isNootedRedApu;
  final bool isDataReady;
}

class _GpuSupportDecision {
  const _GpuSupportDecision({
    required this.level,
    required this.message,
  });

  final CompatibilityLevel level;
  final String message;
}

class _GpuSupportHint {
  const _GpuSupportHint({
    required this.level,
    required this.configMessage,
  });

  final CompatibilityLevel level;
  final String configMessage;
}

class _GpuSupportOutput {
  const _GpuSupportOutput({
    required this.level,
    required this.userMessage,
  });

  final CompatibilityLevel level;
  final String userMessage;
}

bool _isNootedRedSupportedIntegratedGpu(
  String name,
  Map<String, dynamic> gpu,
) {
  if (!HardwareDeviceData.isNootedRedSupportedDeviceId(
    safeStr(gpu['Device ID']),
  )) {
    return false;
  }

  final rawType = safeStr(gpu['Device Type']).toLowerCase();
  if (rawType.contains('discrete') || rawType.contains('独立')) {
    return false;
  }
  if (rawType.contains('integrated') || rawType.contains('核心')) {
    return true;
  }

  final displayName = [
    name,
    safeStr(gpu['Name']),
    safeStr(gpu['DeviceDesc']),
    safeStr(gpu['Device Description']),
    safeStr(gpu['Description']),
  ].where((value) => value.trim().isNotEmpty).join(' ');

  final resolvedType = GpuCodenameData.resolveGpuType(
    name: displayName,
    deviceId: safeStr(gpu['Device ID']),
    rawDeviceType: gpu['Device Type'],
    acpiPath: safeStr(gpu['ACPI Path']),
    pciPath: safeStr(gpu['PCI Path']),
    codename: safeStr(gpu['Codename']),
  );
  if (resolvedType == GpuResolvedType.discrete) return false;

  return true;
}

String _gpuSupportDetail({
  required GpuCompatibilityRecord record,
  required String effectiveMaxDarwin,
  required bool hasAvx2Limit,
}) {
  final details = <String>[];

  if (record.name.isNotEmpty && record.name != record.id) {
    details.add(record.name);
  }

  final supportPrefix = record.requiresSpoof
      ? '仿冒支持'
      : '原生支持';

  details.add(
    '$supportPrefix ${_macOSRangeFromDarwin(record.minDarwin, effectiveMaxDarwin)}',
  );

  if (record.hasOclpRange) {
    details.add(
      'OCLP支持 ${_macOSRangeFromDarwin(record.minOclp!, record.maxOclp!)}',
    );
  }

  if (hasAvx2Limit) {
    details.add('缺少 AVX2 指令集');
  }

  return details.join('\n');
}

String _effectiveMaxDarwin(
  GpuCompatibilityRecord record,
  bool hasAvx2Limit,
) {
  if (!hasAvx2Limit) return record.maxDarwin;

  final current = DarwinVersion(record.maxDarwin);

  if (current > DarwinVersion.montereyMax) {
    return DarwinVersion.montereyMax.raw;
  }

  return record.maxDarwin;
}

String macOSLabelFromDarwinVersion(String darwinVersion) {
  final majorText = darwinVersion.trim().split('.').first;
  final major = int.tryParse(majorText);
  if (major == null) return 'Darwin $darwinVersion';

  final label = MacOSVersions.labelFromDarwinMajor(major);
  if (label.toLowerCase().startsWith('macos')) return label;
  return 'macOS $label';
}

String _macOSRangeFromDarwin(String minDarwin, String maxDarwin) {
  return '${macOSLabelFromDarwinVersion(minDarwin)} ~ '
      '${macOSLabelFromDarwinVersion(maxDarwin)}';
}

CompatibilityNote? gpuCompatibility(Map<String, dynamic> data) {
  final notes = <CompatibilityNote>[];

  for (final entry in hardwareDevices(data['GPU'])) {
    notes.add(
      gpuEntryCompatibility(
        data,
        entry.key,
        safeMap(entry.value),
      ),
    );
  }

  return mergeNotes(notes);
}

// ============================================================================
// Network
// ============================================================================

CompatibilityNote networkEntryCompatibility(
  String name,
  Map<String, dynamic> network,
) {
  final category = HardwareDeviceData.supportedNetworkCategory(
    safeStr(network['Device ID']),
  );

  if (category.isNotEmpty) {
    return CompatibilityNote.supported('兼容');
  }

  final role = networkAdapterType(
    name: name,
  );

  if (role == 'WiFi' && safeStr(network['Bus Type']).toLowerCase() == 'usb') {
    return CompatibilityNote.limited('USB WiFi');
  }

  return CompatibilityNote.unsupported('不兼容');
}

bool isForceAquantiaEthernetKext(String kextName) {
  return kextName.trim().toLowerCase() == 'appleethernetaquantiaaqtion.kext';
}

List<NetworkEntryAnalysis> networkEntries(Map<String, dynamic> data) {
  return hardwareDevices(data['Network']).where((entry) {
    final device = safeMap(entry.value);
    final deviceId = safeStr(device['Device ID']);

    if (deviceId.isEmpty) return false;

    return isPciHardware(entry.value) ||
        HardwareDeviceData.supportedNetworkCategory(deviceId).isNotEmpty;
  }).map((entry) {
    final device = safeMap(entry.value);
    final deviceId = safeStr(device['Device ID']);

    final category = HardwareDeviceData.supportedNetworkCategory(deviceId);

    final type = category.isNotEmpty
        ? category
        : networkAdapterType(
            name: entry.key,
          );

    final displayType = netDisplayType(type);
    final kext = HardwareDeviceData.supportedNetworkKext(deviceId);
    final name = deviceDisplayName(entry.key, device);

    return NetworkEntryAnalysis(
      name: name,
      deviceId: deviceId,
      displayType: displayType,
      isWireless: displayType == 'WiFi' || displayType == 'USB WiFi',
      requiresForceAquantiaEthernet: isForceAquantiaEthernetKext(kext),
      kext: kext,
      rawDevice: device,
      compatibility: networkEntryCompatibility(entry.key, device),
    );
  }).toList();
}

CompatibilityNote? networkCompatibility(Map<String, dynamic> data) {
  return mergeNotes(
    networkEntries(data).map((entry) => entry.compatibility).toList(),
  );
}

// ============================================================================
// Bluetooth
// ============================================================================

CompatibilityNote bluetoothEntryCompatibility(Map<String, dynamic> device) {
  return HardwareDeviceData.isSupportedBluetooth(safeStr(device['Device ID']))
      ? CompatibilityNote.supported('兼容')
      : CompatibilityNote.unsupported('不兼容');
}

List<BluetoothEntryAnalysis> bluetoothEntries(Map<String, dynamic> data) {
  return hardwareDevices(data['Bluetooth']).where((entry) {
    final device = safeMap(entry.value);
    return safeStr(device['Device ID']).isNotEmpty;
  }).map((entry) {
    final device = safeMap(entry.value);
    final deviceId = safeStr(device['Device ID']);

    return BluetoothEntryAnalysis(
      name: deviceDisplayName(entry.key, device),
      deviceId: deviceId,
      busType: safeStr(device['Bus Type']),
      supportedType: HardwareDeviceData.supportedBluetoothType(deviceId),
      rawDevice: device,
      compatibility: bluetoothEntryCompatibility(device),
    );
  }).toList();
}

CompatibilityNote? bluetoothCompatibility(Map<String, dynamic> data) {
  return mergeNotes(
    bluetoothEntries(data).map((entry) => entry.compatibility).toList(),
  );
}

// ============================================================================
// Audio
// ============================================================================

bool isIntelSstAudio(String deviceId) {
  return HardwareDeviceData.isIntelSstAudio(deviceId);
}

AudioCodecLookup audioCodecForDeviceId(String codecDeviceId) {
  final buffer = StringBuffer();

  for (final unit in codecDeviceId.runes) {
    final char = String.fromCharCode(unit);

    if (RegExp(r'[0-9a-fA-F]').hasMatch(char)) {
      buffer.write(char.toUpperCase());
    }
  }

  var normalized = buffer.toString();

  if (normalized.length < 8) {
    return const AudioCodecLookup();
  }

  normalized = normalized.substring(normalized.length - 8);

  final key = '${normalized.substring(0, 4)}-${normalized.substring(4)}';

  final supported = AlcData.sound_card_table_supported[key];
  if (supported != null) {
    return AudioCodecLookup(
      model: supported,
      known: true,
      supported: true,
    );
  }

  final unsupported = AlcData.sound_card_table_unsupported[key];
  if (unsupported != null) {
    return AudioCodecLookup(
      model: unsupported,
      known: true,
      supported: false,
    );
  }

  final vendor = AlcData.sound_vendor_table[key.substring(0, 4)];
  if (vendor != null) {
    return AudioCodecLookup(model: vendor);
  }

  return const AudioCodecLookup();
}

Map<String, dynamic> audioControllerForDevice(
  Map<String, dynamic> device,
  Map<String, dynamic> controllers,
) {
  final ctrlId = safeStr(device['Controller Device ID']).toUpperCase();

  if (ctrlId.isNotEmpty) {
    for (final item in controllers.entries) {
      final c = safeMap(item.value);

      if (safeStr(c['Device ID']).toUpperCase() == ctrlId) {
        return c;
      }
    }
  }

  final ctrlName = safeStr(device['Controller']);

  if (ctrlName.isNotEmpty) {
    final c = safeMap(controllers[ctrlName]);

    if (c.isNotEmpty) return c;
  }

  return {};
}

Map<String, dynamic> audioControllerForDeviceInData(
  Map<String, dynamic> data,
  Map<String, dynamic> device,
) {
  final controllerSources = [
    safeMap(data['Audio Controllers']),
    safeMap(data['Storage Controllers']),
    safeMap(data['System Devices']),
    safeMap(data['Others']),
  ];

  for (final controllers in controllerSources) {
    if (controllers.isEmpty) continue;

    final controller = audioControllerForDevice(device, controllers);
    if (controller.isNotEmpty) return controller;
  }

  return {};
}

bool isDisplayAudioDevice(
  String name,
  String deviceId,
  Map<String, dynamic> device, [
  Map<String, dynamic> controller = const {},
]) {
  final text = [
    name,
    safeStr(device['DeviceDesc']),
    safeStr(controller['DeviceDesc']),
  ].join(' ').toLowerCase();

  final isDisplay = text.contains('hdmi') ||
      text.contains('displayport') ||
      text.contains('dp audio');

  final isVendor = deviceId.trim().toUpperCase().startsWith('1002-') ||
      deviceId.trim().toUpperCase().startsWith('10DE-') ||
      deviceId.trim().toUpperCase().startsWith('8086-');

  return isDisplay && isVendor;
}

List<AudioEntry> audioEntries(Map<String, dynamic> data) {
  final audio = safeMap(data['Audio']);
  final controllers = safeMap(data['Audio Controllers']);
  final entries = <AudioEntry>[];
  final usedCtrlIds = <String>{};

  for (final item in audio.entries) {
    final device = safeMap(item.value);
    if (device.isEmpty) continue;

    final controller = audioControllerForDeviceInData(data, device);

    var deviceId = safeStr(device['Device ID']);
    if (deviceId.isEmpty) {
      deviceId = safeStr(controller['Device ID']);
    }

    var codecId = safeStr(device['Codec Device ID']);
    if (codecId.isEmpty) {
      codecId = safeStr(controller['Codec Device ID']);
    }

    if (deviceId.isEmpty) continue;

    final normCtrlId = safeStr(controller['Device ID']).toUpperCase();

    if (normCtrlId.isNotEmpty) {
      usedCtrlIds.add(normCtrlId);
    }

    final codec = audioCodecForDeviceId(codecId);
    final deviceIdCodec = audioCodecForDeviceId(deviceId);

    var codecKnown = codec.known;
    var codecSupported = codec.supported;
    var model = codec.known ? codec.model : '';

    if (codecId.isEmpty && deviceIdCodec.model.isNotEmpty) {
      model = deviceIdCodec.model;

      if (!codecKnown) {
        codecKnown = deviceIdCodec.known;
        codecSupported = deviceIdCodec.supported;
      }
    }

    final name = safeStr(device['DeviceDesc'], fallback: item.key);

    if (!codecKnown &&
        isDisplayAudioDevice(name, deviceId, device, controller)) {
      codecKnown = true;
      codecSupported = true;
    }

    entries.add(
      AudioEntry(
        name: name,
        deviceId: deviceId,
        codecDeviceId: codecId,
        model: model,
        busType: safeStr(
          device['Bus Type'],
          fallback: safeStr(controller['Bus Type']),
        ),
        acpiPath: safeStr(controller['ACPI Path']),
        pciPath: safeStr(controller['PCI Path']),
        codecKnown: codecKnown,
        codecSupported: codecSupported,
      ),
    );
  }

  for (final item in controllers.entries) {
    final controller = safeMap(item.value);
    if (controller.isEmpty) continue;

    var deviceId = safeStr(controller['Device ID']);
    final codecId = safeStr(controller['Codec Device ID']);
    final normCtrlId = deviceId.toUpperCase();

    if (normCtrlId.isNotEmpty && usedCtrlIds.contains(normCtrlId)) {
      continue;
    }

    Map<String, dynamic> matchedDevice = {};
    String matchedName = '';

    for (final audioItem in audio.entries) {
      final device = safeMap(audioItem.value);
      final ctrlDeviceId =
          safeStr(device['Controller Device ID']).toUpperCase();
      final ctrlName = safeStr(device['Controller']);

      if ((normCtrlId.isNotEmpty && ctrlDeviceId == normCtrlId) ||
          (ctrlName.isNotEmpty && ctrlName == item.key)) {
        matchedDevice = device;
        matchedName = audioItem.key;
        break;
      }
    }

    if (deviceId.isEmpty && codecId.isEmpty && matchedDevice.isEmpty) {
      continue;
    }

    final codec = audioCodecForDeviceId(codecId);

    var codecKnown = codec.known;
    var codecSupported = codec.supported;
    var model = codec.known ? codec.model : '';

    var name = safeStr(controller['DeviceDesc']);
    if (name.isEmpty) name = safeStr(matchedDevice['DeviceDesc']);
    if (name.isEmpty) name = matchedName;
    if (name.isEmpty) name = item.key;

    if (deviceId.isEmpty) {
      deviceId = safeStr(matchedDevice['Device ID']);
    }

    if (!codecKnown && isDisplayAudioDevice(name, deviceId, controller, {})) {
      codecKnown = true;
      codecSupported = true;
    }

    entries.add(
      AudioEntry(
        name: name,
        deviceId: deviceId,
        codecDeviceId: codecId,
        model: model,
        busType: safeStr(
          matchedDevice['Bus Type'],
          fallback: safeStr(controller['Bus Type']),
        ),
        acpiPath: safeStr(controller['ACPI Path']),
        pciPath: safeStr(controller['PCI Path']),
        codecKnown: codecKnown,
        codecSupported: codecSupported,
      ),
    );
  }

  return entries;
}

// ============================================================================
// Audio 兼容性
// ============================================================================

CompatibilityNote audioEntryCompatibility(AudioEntry entry) {
  final deviceId = entry.deviceId.toUpperCase();

  if (entry.busType.toUpperCase().contains('USB')) {
    return CompatibilityNote.supported('兼容');
  }

  if (entry.codecKnown && entry.codecSupported) {
    return CompatibilityNote.supported('兼容');
  }

  if (deviceId.startsWith('1002-')) {
    return CompatibilityNote.supported('兼容');
  }

  if (deviceId.startsWith('8086-') && !isIntelSstAudio(deviceId)) {
    return CompatibilityNote.supported('兼容');
  }

  if (isIntelSstAudio(deviceId)) {
    return CompatibilityNote.unsupported('不兼容');
  }

  return CompatibilityNote.unsupported('不兼容');
}

AudioLayoutAnalysis? audioLayoutAnalysis(
  Map<String, dynamic> data, {
  int? preferredLayout,
}) {
  for (final entry in audioEntries(data)) {
    if (!entry.codecKnown || !entry.codecSupported || entry.model.isEmpty) {
      continue;
    }

    final layouts = AppleALCResolver.findLayoutsByModelSync(entry.model);
    if (layouts.isEmpty) continue;

    return AudioLayoutAnalysis(
      model: entry.model,
      layouts: layouts,
      selectedLayout:
          preferredLayout != null && layouts.contains(preferredLayout)
              ? preferredLayout
              : layouts.first,
    );
  }

  return null;
}

CompatibilityNote? audioCompatibility(Map<String, dynamic> data) {
  final notes = <CompatibilityNote>[];

  for (final entry in audioEntries(data)) {
    notes.add(audioEntryCompatibility(entry));
  }

  return mergeNotes(notes);
}

// ============================================================================
// Storage / Disk 兼容性
// ============================================================================

Set<String> unsupportedDiskControllerIds(Map<String, dynamic> data) {
  final ids = <String>{};

  for (final entry in storageControllerEntries(data)) {
    if (entry.compatibility.level == CompatibilityLevel.unsupported) {
      ids.add(entry.deviceId.toUpperCase());
    }
  }

  for (final item in safeList(data['Disk'])) {
    final id = safeStr(safeMap(item)['Controller Device ID']).toUpperCase();

    if (isUnsupportedNvmeDiskId(id)) {
      ids.add(id);
    }
  }

  return ids;
}

bool isUnsupportedNvmeDiskId(String deviceId) {
  return HardwareDeviceData.isUnsupportedNvmeDisk(deviceId);
}

bool isNvmeDisk(Map<String, dynamic> disk) {
  final text = [
    safeStr(disk['BusType']),
    safeStr(disk['Bus Type']),
    safeStr(disk['Interface']),
    safeStr(disk['MediaType']),
  ].join(' ').toLowerCase();

  return text.contains('nvme') || text.contains('non-volatile memory');
}

bool isUnsupportedDisk(
  Map<String, dynamic> disk,
  Set<String> unsupportedControllerIds,
) {
  final ctrlId = safeStr(disk['Controller Device ID']).toUpperCase();
  if (ctrlId.isNotEmpty && unsupportedControllerIds.contains(ctrlId)) {
    return true;
  }

  return isNvmeDisk(disk) &&
      HardwareDeviceData.isUnsupportedDiskModel(safeStr(disk['Model']));
}

bool isNvmeStorageController(String name, Map<String, dynamic> device) {
  final text = [
    name,
    safeStr(device['DeviceDesc']),
    safeStr(device['Device']),
  ].join(' ').toLowerCase();

  return text.contains('nvme') || text.contains('non-volatile memory');
}

CompatibilityNote storageControllerEntryCompatibility(
  Map<String, dynamic> device,
) {
  return isUnsupportedNvmeDiskId(safeStr(device['Device ID']))
      ? CompatibilityNote.unsupported('不兼容')
      : CompatibilityNote.supported('兼容');
}

List<StorageControllerEntryAnalysis> storageControllerEntries(
  Map<String, dynamic> data,
) {
  return hardwareDevices(data['Storage Controllers'])
      .where((entry) => isPciHardware(entry.value))
      .map((entry) {
    final device = safeMap(entry.value);

    return StorageControllerEntryAnalysis(
      name: deviceDisplayName(entry.key, device),
      deviceId: safeStr(device['Device ID']),
      isNvme: isNvmeStorageController(entry.key, device),
      rawDevice: device,
      compatibility: storageControllerEntryCompatibility(device),
    );
  }).toList();
}

CompatibilityNote? diskCompatibility(Map<String, dynamic> data) {
  final unsupportedIds = unsupportedDiskControllerIds(data);
  final disks = safeList(data['Disk']);

  if (disks.isEmpty) return null;

  var supported = 0;
  var unsupported = 0;

  for (final item in disks) {
    final disk = safeMap(item);

    if (isUnsupportedDisk(disk, unsupportedIds)) {
      unsupported++;
    } else {
      supported++;
    }
  }

  return statusNote(supported, unsupported);
}

CompatibilityNote? storageCompatibility(Map<String, dynamic> data) {
  final entries = storageControllerEntries(data);

  if (entries.isEmpty) return null;

  var supported = 0;
  var unsupported = 0;

  for (final entry in entries) {
    if (entry.compatibility.level == CompatibilityLevel.supported) {
      supported++;
    } else {
      unsupported++;
    }
  }

  return statusNote(supported, unsupported);
}

// ============================================================================
// SD Card
// ============================================================================

List<MapEntry<String, dynamic>> qtSdEntries(Map<String, dynamic> data) {
  final seen = <String>{};

  return hardwareDevices(data['SD Controller']).where((entry) {
    final device = safeMap(entry.value);
    final id =
        '${entry.key}|${safeStr(device['Device ID'])}|${safeStr(device['PCI Path'])}';

    return device.isNotEmpty && seen.add(id);
  }).toList();
}

CompatibilityNote sdEntryCompatibility(Map<String, dynamic> device) {
  return HardwareDeviceData.supportedSdCardReaderName(
    safeStr(device['Device ID']),
  ).isNotEmpty
      ? CompatibilityNote.supported('兼容')
      : CompatibilityNote.unsupported('不兼容');
}

List<SdCardEntryAnalysis> sdCardEntries(Map<String, dynamic> data) {
  return qtSdEntries(data).map((entry) {
    final device = safeMap(entry.value);
    final deviceId = safeStr(device['Device ID']);

    return SdCardEntryAnalysis(
      name: deviceDisplayName(entry.key, device),
      deviceId: deviceId,
      device: safeStr(device['Device']),
      manufacturer: safeStr(device['Manufacturer']),
      readerName: HardwareDeviceData.supportedSdCardReaderName(deviceId),
      builtIn: safeStr(device['Built-In']),
      serialNumber: safeStr(device['SerialNumber']),
      rawDevice: device,
      compatibility: sdEntryCompatibility(device),
    );
  }).toList();
}

CompatibilityNote? sdCompatibility(Map<String, dynamic> data) {
  final entries = sdCardEntries(data);

  if (entries.isEmpty) return null;

  var supported = 0;
  var unsupported = 0;

  for (final entry in entries) {
    if (entry.compatibility.level == CompatibilityLevel.supported) {
      supported++;
    } else {
      unsupported++;
    }
  }

  return statusNote(supported, unsupported);
}

// ============================================================================
// Common
// ============================================================================

CompatibilityNote? mergeNotes(List<CompatibilityNote> notes) {
  if (notes.isEmpty) return null;

  final supported =
      notes.where((n) => n.level == CompatibilityLevel.supported).length;

  final limited =
      notes.where((n) => n.level == CompatibilityLevel.limited).length;

  final unsupported =
      notes.where((n) => n.level == CompatibilityLevel.unsupported).length;

  if (limited > 0 || (supported > 0 && unsupported > 0)) {
    final limitedDetails = notes
        .where((n) => n.level == CompatibilityLevel.limited)
        .map((n) => n.detailText)
        .where((t) => t.isNotEmpty)
        .take(3)
        .join('\n');

    return CompatibilityNote.limited(
      limitedDetails.isEmpty ? '有限兼容' : '有限兼容\n$limitedDetails',
    );
  }

  if (unsupported > 0) {
    return CompatibilityNote.unsupported('不兼容');
  }

  return CompatibilityNote.supported('兼容');
}

CompatibilityNote? statusNote(int supported, int unsupported) {
  if (supported > 0 && unsupported == 0) {
    return CompatibilityNote.supported('兼容');
  }

  if (supported > 0 && unsupported > 0) {
    return CompatibilityNote.limited('有限兼容');
  }

  if (supported == 0 && unsupported > 0) {
    return CompatibilityNote.unsupported('不兼容');
  }

  return null;
}
