/// iigpufb.json 数据模型
/// 层次：代数 → CPU型号 → 属性列表

/// 单个核显属性（已将 JSON 原始值转换为 plist 可用格式）
class IigpufbProperty {
  /// OpenCore plist 键名，如 'AAPL,ig-platform-id'
  final String key;

  /// 数据类型：'data' 或 'string'
  final String dataType;

  /// 属性值：
  ///   - data 类型：去掉 "0x" 前缀的十六进制字符串，如 '00009b3e'
  ///   - string 类型：原始字符串值
  final String value;

  const IigpufbProperty({
    required this.key,
    required this.dataType,
    required this.value,
  });

  @override
  String toString() => '$key ($dataType): $value';
}

/// 单个 CPU 条目
class IigpufbCpuEntry {
  /// CPU 型号字符串，如 'i5-4200u(HD4400)'
  final String cpuModel;

  /// 核显简称，如 'HD4400'
  final String igpuName;

  /// JSON 中的 _note 字段（如有），仅用于提示，不写入配置
  final String? note;

  /// 可写入 plist 的属性列表（已排除 igpu / _note 等元字段）
  final List<IigpufbProperty> properties;

  const IigpufbCpuEntry({
    required this.cpuModel,
    required this.igpuName,
    this.note,
    required this.properties,
  });

  /// 核显型号完整名称（来自 model 属性，如有）
  String get modelName {
    for (final p in properties) {
      if (p.key == 'model') return p.value;
    }
    return igpuName;
  }

  /// Platform ID 值（已去掉 "0x" 前缀）
  String? get platformId {
    for (final p in properties) {
      if (p.key == 'AAPL,ig-platform-id' ||
          p.key == 'AAPL,snb-platform-id') {
        return p.value;
      }
    }
    return null;
  }

  /// Platform ID 键名（Sandy Bridge 与其他代不同）
  String? get platformIdKey {
    for (final p in properties) {
      if (p.key == 'AAPL,ig-platform-id' ||
          p.key == 'AAPL,snb-platform-id') {
        return p.key;
      }
    }
    return null;
  }
}

/// 一个 CPU 代数
class IigpufbGeneration {
  /// 代数名称，如 'Intel 4th Haswell'
  final String name;

  /// 该代所有 CPU 条目
  final List<IigpufbCpuEntry> cpus;

  const IigpufbGeneration({
    required this.name,
    required this.cpus,
  });
}
