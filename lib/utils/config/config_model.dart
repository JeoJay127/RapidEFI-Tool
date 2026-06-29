import 'package:rapidefi/utils/config/accessors/acpi_patch_accessor.dart';
import 'package:rapidefi/utils/config/accessors/amd_settings_accessor.dart';
import 'package:rapidefi/utils/config/accessors/booter_mmio_accessor.dart';
import 'package:rapidefi/utils/config/accessors/device_properties_accessor.dart';
import 'package:rapidefi/utils/config/accessors/kext_accessor.dart';
import 'package:rapidefi/utils/config/accessors/nvram/boot_args_accessor.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi.dart';
import 'package:rapidefi/utils/config/models/device_properties/device_property_item.dart';
import 'package:rapidefi/utils/config/models/enums/brand_enum.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/models/kernel/kext_group.dart';
import 'package:rapidefi/utils/config/models/misc/misc.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_code_registry.dart';
import 'package:rapidefi/utils/config/presets/sections/config_acpi.dart';
import 'package:rapidefi/utils/config/presets/sections/config_device_properties.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/support/macos_version.dart';
import 'models/booter/booter.dart';
import 'models/device_properties/device_properties.dart';
import 'models/kernel/kernel.dart';
import 'models/kernel/kernel_kext.dart';

export 'accessors/acpi_patch_accessor.dart';
export 'accessors/booter_mmio_accessor.dart';
export 'accessors/device_properties_accessor.dart';
export 'accessors/kext_accessor.dart';
export 'accessors/nvram/boot_args_accessor.dart';
export 'accessors/nvram/nvram_settings_accessor.dart';
export 'accessors/platform_info_accessor.dart';
export 'presets/platform_profiles/platform_code_registry.dart';
export 'support/macos_version.dart';

class ConfigModel {
  CpuType cpuType;

  /// 平台类型，默认为台式机
  PlatformType platformType;

  String platformCode;

  /// Darwin主版本号
  int darwinMajorVersion;

  /// 是否是奔腾赛扬处理器
  bool pentiumOrCeleron;

  bool isCometLakeU62;

  bool legacy;

  List<Object>? alcidPickerSelection;

  /// 主板品牌
  Brand brand;

  /// 特殊主板型号
  SpecialMotherboard specialMotherboard;

  Acpi acpi;

  Booter booter;

  DeviceProperties deviceProperties;

  Kernel kernel;

  Misc misc;

  NVRAM nvram;

  PlatformInfo platformInfo;

  Uefi uefi;

  ConfigModel({
    this.cpuType = CpuType.intel,
    this.platformType = PlatformType.desktop,
    String? platformCode,
    int? darwinMajorVersion,
    String? macOSVersion,
    this.pentiumOrCeleron = false,
    this.isCometLakeU62 = false,
    this.legacy = false,
    this.alcidPickerSelection,
    this.brand = Brand.none,
    this.specialMotherboard = SpecialMotherboard.none,
    Acpi? acpi,
    Booter? booter,
    DeviceProperties? deviceProperties,
    Kernel? kernel,
    Misc? misc,
    NVRAM? nvram,
    PlatformInfo? platformInfo,
    Uefi? uefi,
  })  : platformCode = PlatformCodeRegistry.resolveCode(
          cpuType,
          platformType,
          platformCode: platformCode,
        ),
        acpi = acpi ?? Acpi(),
        darwinMajorVersion = darwinMajorVersion ??
            (macOSVersion != null
                ? MacOSVersions.darwinMajorFromLabel(macOSVersion)
                : MacOSVersions.defaultDarwinMajor),
        booter = booter ?? Booter(),
        deviceProperties = deviceProperties ?? DeviceProperties(addList: []),
        kernel = kernel ??
            Kernel(
                kernelBlockItems: [],
                kernelForceItems: [],
                kernelPatchItems: []),
        misc = misc ?? Misc(),
        nvram = nvram ?? NVRAM(),
        platformInfo = platformInfo ?? PlatformInfo(),
        uefi = uefi ?? Uefi();

  Map<String, dynamic> toJson() {
    return {
      'cpuType': cpuType.toString(),
      'platformType': platformType.toString(),
      'platformCode': platformCode,
      'darwinMajorVersion': darwinMajorVersion,
      'pentiumOrCeleron': pentiumOrCeleron,
      'isCometLakeU62': isCometLakeU62,
      'legacy': legacy,
      'alcidPickerSelection': alcidPickerSelection,
      'brand': brand.toString(),
      'specialMotherboard': specialMotherboard.toString(),
      'acpi': acpi.toJson(),
      'booter': booter.toJson(),
      'deviceProperties': deviceProperties.toJson(),
      'kernel': kernel.toJson(),
      'misc': misc.toJson(),
      'nvram': nvram.toJson(),
      'platformInfo': platformInfo.toJson(),
      'uefi': uefi.toJson(),
    };
  }

  ConfigModel detached() => ConfigModel.fromJson(toJson());

  ConfigModel copyWith({
    CpuType? cpuType,
    PlatformType? platformType,
    String? platformCode,
    int? darwinMajorVersion,
    String? macOSVersion,
    bool? pentiumOrCeleron,
    bool? isCometLakeU62,
    bool? legacy,
    List<Object>? alcidPickerSelection,
    ProcessorType? processorType,
    Brand? brand,
    SpecialMotherboard? specialMotherboard,
    Acpi? acpi,
    Booter? booter,
    DeviceProperties? deviceProperties,
    Kernel? kernel,
    Misc? misc,
    NVRAM? nvram,
    PlatformInfo? platformInfo,
    Uefi? uefi,
  }) {
    final targetCpuType = cpuType ?? this.cpuType;
    final targetPlatformType = platformType ?? this.platformType;
    final targetPlatformCode = platformCode ?? this.platformCode;

    return ConfigModel(
      cpuType: targetCpuType,
      platformType: targetPlatformType,
      platformCode: targetPlatformCode,
      darwinMajorVersion: darwinMajorVersion ??
          (macOSVersion != null
              ? MacOSVersions.darwinMajorFromLabel(macOSVersion)
              : this.darwinMajorVersion),
      pentiumOrCeleron: pentiumOrCeleron ?? this.pentiumOrCeleron,
      isCometLakeU62: isCometLakeU62 ?? this.isCometLakeU62,
      legacy: legacy ?? this.legacy,
      alcidPickerSelection: alcidPickerSelection ?? this.alcidPickerSelection,
      brand: brand ?? this.brand,
      specialMotherboard: specialMotherboard ?? this.specialMotherboard,
      acpi: acpi ?? this.acpi.copyWith(),
      booter: booter ?? this.booter.copyWith(),
      deviceProperties: deviceProperties ?? this.deviceProperties.copyWith(),
      kernel: kernel ?? this.kernel.copyWith(),
      misc: misc ?? this.misc.copyWith(),
      nvram: nvram ?? this.nvram.copyWith(),
      platformInfo: platformInfo ?? this.platformInfo.copyWith(),
      uefi: uefi ?? this.uefi.copyWith(),
    );
  }

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    final cpuType = CpuType.fromJson(json['cpuType']);
    final platformType = PlatformType.fromJson(json['platformType']);
    final legacyPlatformIndex =
        json['plantformIndex'] is int ? json['plantformIndex'] as int : 0;
    final model = ConfigModel(
      cpuType: cpuType,
      platformType: platformType,
      platformCode: PlatformCodeRegistry.resolveCode(
        cpuType,
        platformType,
        platformCode: json['platformCode'],
        legacyIndex: legacyPlatformIndex,
      ),
      darwinMajorVersion: json['darwinMajorVersion'] ??
          MacOSVersions.darwinMajorFromLabel(
            json['macOSVersion'] ??
                MacOSVersions.byDarwinMajor(
                  MacOSVersions.defaultDarwinMajor,
                ).label,
          ),
      pentiumOrCeleron: json['pentiumOrCeleron'] ?? false,
      isCometLakeU62: json['isCometLakeU62'] ?? false,
      legacy: json['legacy'] ?? json['uefiSupport'] ?? false,
      alcidPickerSelection:
          _parseAlcidPickerSelection(json['alcidPickerSelection']),
      brand: Brand.fromJson(json['brand']),
      specialMotherboard: SpecialMotherboard.fromJson(
        JsonCompat.pickEnumRaw(
          json,
          [
            'specialMotherboard',
            'specialMainBoard',
            'amdmlb',
          ],
        ),
      ),
      acpi: json['acpi'] != null ? Acpi.fromJson(json['acpi']) : Acpi(),
      booter:
          json['booter'] != null ? Booter.fromJson(json['booter']) : Booter(),
      deviceProperties: json['deviceProperties'] != null
          ? DeviceProperties.fromJson(json['deviceProperties'])
          : DeviceProperties(addList: []),
      kernel:
          json['kernel'] != null ? Kernel.fromJson(json['kernel']) : Kernel(),
      misc: json['misc'] != null ? Misc.fromJson(json['misc']) : Misc(),
      nvram: json['nvram'] != null ? NVRAM.fromJson(json['nvram']) : NVRAM(),
      platformInfo: json['platformInfo'] != null
          ? PlatformInfo.fromJson(json['platformInfo'])
          : PlatformInfo(),
      uefi: json['uefi'] != null ? Uefi.fromJson(json['uefi']) : Uefi(),
    );
    _LegacyConfigModelCompat.apply(model, json);
    return model;
  }

  static List<Object>? _parseAlcidPickerSelection(Object? value) {
    if (value is! List || value.length != 3) {
      return null;
    }

    final vendor = value[0];
    final codec = value[1];
    final layoutId = value[2];
    if (vendor is String && codec is String && layoutId is num) {
      return [vendor, codec, layoutId.toInt()];
    }

    return null;
  }
}

class _LegacyConfigModelCompat {
  const _LegacyConfigModelCompat._();

  static void apply(ConfigModel model, Map<String, dynamic> json) {
    _migrateUsbDriver(model, json);
    _migrateSoundDriver(model, json);
    _migrateNetworkDrivers(model, json);
    _migrateWifiDrivers(model, json);
    _migrateOptionalKexts(model, json);
    _migrateUsbWifi(model, json);
    _migrateAlcid(model, json);
    _migrateHpetPatch(model, json);
    _migrateIgpuProperties(model, json);
    _migrateAmdPlatformOptions(model, json);
    _normalizeSoundOptions(model);
  }

  static void _migrateUsbDriver(
    ConfigModel model,
    Map<String, dynamic> json,
  ) {
    _addKextByLegacyToken(model, _pickLegacyRaw(json, 'usbDriverType'));
  }

  static void _migrateSoundDriver(
    ConfigModel model,
    Map<String, dynamic> json,
  ) {
    _addKextByLegacyToken(model, _pickLegacyRaw(json, 'soundDriverType'));
  }

  static void _migrateNetworkDrivers(
    ConfigModel model,
    Map<String, dynamic> json,
  ) {
    for (final item in _legacyList(json['netWorkTypes'])) {
      _addKextByLegacyToken(model, item);
    }
  }

  static void _migrateWifiDrivers(
    ConfigModel model,
    Map<String, dynamic> json,
  ) {
    for (final item in _legacyList(json['wifiTypes'])) {
      final token = _normalizeToken(_legacyToken(item));
      final group = switch (token) {
        'bcm94360' => ConfigKextGroups.brcm94360.kexts,
        'bcm943xx' => ConfigKextGroups.brcm943xx.kexts,
        'bcm4331' => ConfigKextGroups.brcm4331.kexts,
        'bcm43224' => ConfigKextGroups.brcm43224.kexts,
        _ => null,
      };

      if (group != null) {
        _addKexts(model, group);
      } else {
        _addKextByLegacyToken(model, item);
      }
    }
  }

  static void _migrateOptionalKexts(
    ConfigModel model,
    Map<String, dynamic> json,
  ) {
    for (final item in _legacyList(json['optionalKexts'])) {
      _addKextsByLegacyToken(model, item);
    }

    for (final item in _legacyList(json['optionalLaptopKexts'])) {
      _addKextsByLegacyToken(model, item);
    }
  }

  static void _migrateUsbWifi(
    ConfigModel model,
    Map<String, dynamic> json,
  ) {
    if (json['enableUSBWiFi'] == true) {
      KextAccessor.setUsesUsbWifi(model, true);
    }
  }

  static void _migrateAmdPlatformOptions(
    ConfigModel model,
    Map<String, dynamic> json,
  ) {
    if (model.cpuType == CpuType.amd &&
        model.platformCode != 'bulldozer_jaguar') {
      model.legacy = false;
    }

    if (model.cpuType == CpuType.amd &&
        model.specialMotherboard == SpecialMotherboard.amdB550A520 &&
        !model.acpi.acpiAddItems
            .any((item) => item.path == ConfigAcpi.SSDT_CPUR.path)) {
      model.acpi.acpiAddItems.add(ConfigAcpi.SSDT_CPUR.copyWith());
    }

    if (json['useRyzenGPU'] == true) {
      AmdSettingsAccessor.setUsesRyzenGpu(model, true);
    }

    if (json['usePrecastMMIO'] == true) {
      BooterMmioAccessor.setUsesPrecastMmio(model, true);
    }
  }

  static void _migrateAlcid(ConfigModel model, Map<String, dynamic> json) {
    final legacyAlcid = _readInt(json['alcid']);
    final bootArgAlcid = BootArgsAccessor.getAlcid(model);
    final alcid = legacyAlcid ?? bootArgAlcid;
    if (alcid != null && alcid > 0) {
      BootArgsAccessor.setAlcid(model, alcid);
    }

    final legacySelection = json['alcidPickerSelection'];
    if (legacySelection is! List || legacySelection.length != 3) {
      if (alcid != null && alcid > 0) {
        model.alcidPickerSelection = ['', '', alcid];
      }
      return;
    }

    final selectionLayoutId = _readInt(legacySelection[2]);
    if (legacyAlcid == null &&
        _hasNamedAlcidSelection(legacySelection) &&
        selectionLayoutId != null &&
        selectionLayoutId > 0) {
      model.alcidPickerSelection = [
        legacySelection[0],
        legacySelection[1],
        selectionLayoutId,
      ];
      return;
    }

    final layoutId = legacyAlcid ?? selectionLayoutId ?? bootArgAlcid;
    if (layoutId != null && layoutId > 0) {
      model.alcidPickerSelection = ['', '', layoutId];
    }
  }

  static bool _hasNamedAlcidSelection(List<Object?> selection) {
    final vendor = selection[0];
    final codec = selection[1];
    return vendor is String &&
        vendor.trim().isNotEmpty &&
        codec is String &&
        codec.trim().isNotEmpty;
  }

  static void _normalizeSoundOptions(ConfigModel model) {
    if (KextAccessor.containsKext(model, ConfigKernel.AppleALC)) {
      return;
    }

    model.alcidPickerSelection = null;
    BootArgsAccessor.removeWhere(
      model,
      (arg) => arg.startsWith('alcid='),
    );
  }

  static void _migrateHpetPatch(
    ConfigModel model,
    Map<String, dynamic> json,
  ) {
    if (json['enableHpetPatch'] != true) {
      return;
    }

    final path = json['hpetPath']?.toString().trim() ?? '';
    AcpiPatchAccessor.setHpetPatch(
      model,
      path: path.isEmpty ? AcpiPatchAccessor.defaultHpetPath : path,
    );
  }

  static void _migrateIgpuProperties(
    ConfigModel model,
    Map<String, dynamic> json,
  ) {
    final items = json['iGPUHighLevelProperties'];
    if (items is List) {
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          _setIgpuProperty(model, DevicePropertyItem.fromJson(item));
        } else if (item is Map) {
          _setIgpuProperty(
            model,
            DevicePropertyItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final edid = json['edid']?.toString() ?? '';
    if (edid.isNotEmpty && model.edid.isEmpty) {
      model.edid = edid;
    }
  }

  static Object? _pickLegacyRaw(Map<String, dynamic> json, String key) {
    return JsonCompat.pickEnumRaw(json, [key]);
  }

  static List<Object?> _legacyList(Object? raw) {
    if (raw is! List) return const [];
    return raw.where((item) => _legacyToken(item).isNotEmpty).toList();
  }

  static String _legacyToken(Object? raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) return '';

    final token = text.contains('.') ? text.split('.').last : text;
    final normalized = token.trim().toLowerCase();
    if (const {'', 'nil', 'none', 'null'}.contains(normalized)) {
      return '';
    }
    return token.trim();
  }

  static String _normalizeToken(String value) {
    var normalized = value.trim().toLowerCase();
    if (normalized.endsWith('.kext')) {
      normalized = normalized.substring(0, normalized.length - '.kext'.length);
    }
    return normalized.replaceAll(RegExp(r'[\s_\-]'), '');
  }

  static KernelKext? _kextByToken(Object? raw) {
    final token = _normalizeToken(_legacyToken(raw));
    if (token.isEmpty) return null;

    for (final kext in ConfigKernel.sortKernelKexts) {
      final bundleName = kext.bundlePath.split('/').last;
      final candidates = [
        kext.name,
        kext.bundlePath,
        bundleName,
        bundleName.replaceAll('.kext', ''),
      ];
      if (candidates.any((item) => _normalizeToken(item) == token)) {
        return kext;
      }
    }

    return null;
  }

  static KextGroup? _kextGroupByToken(Object? raw) {
    final token = _normalizeToken(_legacyToken(raw));
    if (token.isEmpty) return null;

    for (final group in ConfigKextGroups.requiredTogetherGroups) {
      final candidates = _groupLegacyCandidates(group);
      if (candidates.any((item) => _normalizeToken(item) == token)) {
        return group;
      }
    }

    return null;
  }

  static List<String> _groupLegacyCandidates(KextGroup group) {
    final bundleNames = group.kexts
        .map((kext) => _bundleNameWithoutKext(kext.bundlePath))
        .where((name) => name.isNotEmpty)
        .toList();
    final kextNames = group.kexts
        .map((kext) => kext.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    final parentPrefixedNames = group.kexts
        .map(_parentPrefixedBundleName)
        .where((name) => name.isNotEmpty)
        .toList();
    return [
      if (bundleNames.isNotEmpty) bundleNames.join('_'),
      if (kextNames.isNotEmpty) kextNames.join('_'),
      if (parentPrefixedNames.isNotEmpty) parentPrefixedNames.join('_'),
      ..._groupLegacyAliases(group),
    ];
  }

  static List<String> _groupLegacyAliases(KextGroup group) {
    if (group == ConfigKextGroups.appleIntelCpuPowerManagement) {
      return const [
        'AppleIntelCPUPowerManagement_AppleIntelCPUPowerManagementClient',
      ];
    }

    if (group == ConfigKextGroups.applePs2SmartTouchPad) {
      return const [
        'ApplePS2SmartTouchPad_ApplePS2SmartTouchPadApplePS2Controller_ApplePS2SmartTouchPadApplePS2Keyboard',
      ];
    }

    return const [];
  }

  static String _bundleNameWithoutKext(String bundlePath) {
    final name = bundlePath.trim().split('/').last;
    if (name.toLowerCase().endsWith('.kext')) {
      return name.substring(0, name.length - '.kext'.length);
    }
    return name;
  }

  static String _parentPrefixedBundleName(KernelKext kext) {
    final parts = kext.bundlePath
        .split('/')
        .where((part) => part.toLowerCase().endsWith('.kext'))
        .map(_bundleNameWithoutKext)
        .toList();
    if (parts.length <= 1) {
      return parts.isEmpty ? '' : parts.first;
    }
    return parts.join('');
  }

  static void _addKextsByLegacyToken(ConfigModel model, Object? raw) {
    final group = _kextGroupByToken(raw);
    if (group != null) {
      _addKexts(model, group.kexts);
      return;
    }

    _addKextByLegacyToken(model, raw);
  }

  static void _addKextByLegacyToken(ConfigModel model, Object? raw) {
    final kext = _kextByToken(raw);
    if (kext != null) {
      _addKext(model, kext);
    }
  }

  static void _addKexts(ConfigModel model, Iterable<KernelKext> kexts) {
    for (final kext in kexts) {
      _addKext(model, kext);
    }
  }

  static void _addKext(ConfigModel model, KernelKext kext) {
    if (kext.bundlePath.isEmpty) {
      return;
    }
    KextAccessor.addKext(model, kext);
  }

  static void _setIgpuProperty(ConfigModel model, DevicePropertyItem item) {
    final key = item.key?.trim() ?? '';
    if (key.isEmpty) {
      return;
    }
    DevicePropertiesAccessor.setProperty(
      model,
      ConfigDp.pciPath,
      item.copyWith(key: key),
    );
  }

  static int? _readInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }
}
