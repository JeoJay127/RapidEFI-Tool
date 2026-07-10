import 'dart:typed_data';
import 'package:rapidefi/utils/config/models/device_properties/device_property_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 可勾选条目类型枚举
// ─────────────────────────────────────────────────────────────────────────────
enum MbItemCategory {
  acpiAdd,       // ACPI.Add → SSDT 文件
  kextAdd,       // Kernel.Add → Kext 文件
  kernelPatch,   // Kernel.Patch → 内核补丁
  kernelQuirk,   // Kernel.Quirks → 单个 bool/int 字段
  booterQuirk,   // Booter.Quirks → 单个 bool/int 字段
  dpPath,        // DP.Add → 某 PCI 路径下的所有属性
  miscBoot,      // Misc.Boot → 单个字段
  miscSecurity,  // Misc.Security → 单个字段
  nvramGuid,     // NVRAM → 单个 GUID 的键值对
  platformInfo,  // PI → 全部 PlatformInfo 设置
  uefiQuirk,     // UEFI.Quirks → 单个 bool/int 字段
}

// ─────────────────────────────────────────────────────────────────────────────
// 通用可勾选条目
// ─────────────────────────────────────────────────────────────────────────────
class MbConfSelectableItem {
  final MbItemCategory category;

  /// 界面显示标签，如 "SSDT-EC.aml"、"layout-id = 04000000"
  final String label;

  /// 辅助说明（可选）
  final String description;

  /// 实际数据，类型依 category 而定（见下方说明）
  final Object data;

  const MbConfSelectableItem({
    required this.category,
    required this.label,
    required this.data,
    this.description = '',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 各 category 对应的 data 类型说明
// ─────────────────────────────────────────────────────────────────────────────
// acpiAdd    → String (SSDT filename, e.g. "SSDT-EC.aml")
// kextAdd    → String (bundlePath, e.g. "Lilu.kext")
// kernelPatch→ MbKernelPatch
// kernelQuirk→ MbQuirkEntry
// booterQuirk→ MbQuirkEntry
// dpPath     → MbDpPath
// miscBoot   → MbMiscEntry
// miscSecurity→MbMiscEntry
// nvramGuid  → MbNvramGuid
// platformInfo→MbPlatformInfoData
// uefiQuirk  → MbQuirkEntry

// ─────────────────────────────────────────────────────────────────────────────
// data 载体类
// ─────────────────────────────────────────────────────────────────────────────

/// 内核补丁条目
class MbKernelPatch {
  final String arch;
  final String base;
  final String comment;
  final int count;
  final bool enabled;
  final Uint8List? find;
  final String identifier;
  final int limit;
  final Uint8List? mask;
  final String maxKernel;
  final String minKernel;
  final Uint8List? replace;
  final Uint8List? replaceMask;
  final int skip;

  const MbKernelPatch({
    required this.arch,
    required this.base,
    required this.comment,
    required this.count,
    required this.enabled,
    this.find,
    required this.identifier,
    required this.limit,
    this.mask,
    required this.maxKernel,
    required this.minKernel,
    this.replace,
    this.replaceMask,
    required this.skip,
  });
}

/// bool/int Quirk 条目（Kernel / Booter / UEFI）
class MbQuirkEntry {
  /// JSON 中的原始 key（PascalCase），如 "SetupVirtualMap"
  final String jsonKey;

  /// 要设置的值（bool 或 int）
  final dynamic value;

  const MbQuirkEntry({required this.jsonKey, required this.value});
}

/// DeviceProperties 的某条 PCI 路径
class MbDpPath {
  final String pciPath;
  final List<DevicePropertyItem> properties;

  const MbDpPath({required this.pciPath, required this.properties});
}

/// Misc.Boot 或 Misc.Security 的单个键值对
class MbMiscEntry {
  final String key;
  final dynamic value;

  const MbMiscEntry({required this.key, required this.value});
}

/// NVRAM 单个 GUID 及其键值对
class MbNvramGuid {
  final String guid;
  final Map<String, dynamic> entries;

  const MbNvramGuid({required this.guid, required this.entries});
}

/// PlatformInfo 完整数据
class MbPlatformInfoData {
  final bool? automatic;
  final String? updateSMBIOSMode;
  final bool? updateDataHub;
  final bool? updateNVRAM;
  final bool? updateSMBIOS;
  final bool? useRawUuidEncoding;
  final bool? customMemory;
  final Map<String, dynamic>? generic;

  const MbPlatformInfoData({
    this.automatic,
    this.updateSMBIOSMode,
    this.updateDataHub,
    this.updateNVRAM,
    this.updateSMBIOS,
    this.useRawUuidEncoding,
    this.customMemory,
    this.generic,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 主板条目（解析后的完整配置）
// ─────────────────────────────────────────────────────────────────────────────
class MbConfEntry {
  final String platform;
  final String vendor;
  final String modelName;

  /// 全部可勾选条目（已按 category 预分组）
  final List<MbConfSelectableItem> items;

  const MbConfEntry({
    required this.platform,
    required this.vendor,
    required this.modelName,
    required this.items,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 层级导航辅助
// ─────────────────────────────────────────────────────────────────────────────
class MbConfVendor {
  final String name;
  final List<String> models;
  const MbConfVendor({required this.name, required this.models});
}

class MbConfPlatform {
  final String name;
  final List<MbConfVendor> vendors;
  const MbConfPlatform({required this.name, required this.vendors});
}
