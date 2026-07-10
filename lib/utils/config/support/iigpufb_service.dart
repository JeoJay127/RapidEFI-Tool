import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:rapidefi/utils/config/models/device_properties/iigpufb_model.dart';

/// iigpufb.json 加载与查询服务（单例懒加载）
class IigpufbService {
  IigpufbService._();
  static final IigpufbService instance = IigpufbService._();

  List<IigpufbGeneration>? _cache;

  /// 异步加载并解析 iigpufb.json，重复调用直接返回缓存
  Future<List<IigpufbGeneration>> load() async {
    if (_cache != null) return _cache!;
    final jsonStr =
        await rootBundle.loadString('assets/data/iigpufb.json');
    final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
    _cache = raw.entries
        .map((e) => _parseGeneration(e.key, e.value as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  // ---------- 内部解析 ----------

  IigpufbGeneration _parseGeneration(
      String name, Map<String, dynamic> cpuMap) {
    final cpus = cpuMap.entries
        .map((e) => _parseCpu(e.key, e.value as Map<String, dynamic>))
        .toList();
    return IigpufbGeneration(name: name, cpus: cpus);
  }

  IigpufbCpuEntry _parseCpu(String model, Map<String, dynamic> props) {
    const metaKeys = {'igpu', '_note'};
    // 这些键的值为纯字符串，不是 hex
    const stringKeys = {
      'model',
      'device_type',
      'AAPL,slot-name',
      'hda-gfx',
    };

    final igpu = props['igpu'] as String? ?? '';
    final note = props['_note'] as String?;

    final properties = <IigpufbProperty>[];
    for (final entry in props.entries) {
      if (metaKeys.contains(entry.key)) continue;
      final rawVal = entry.value.toString();
      final isHex = rawVal.startsWith('0x') || rawVal.startsWith('0X');
      final isString = stringKeys.contains(entry.key);

      if (isHex && !isString) {
        // 去掉 "0x" 前缀，转小写，保持原始字节序
        properties.add(IigpufbProperty(
          key: entry.key,
          dataType: 'data',
          value: rawVal.substring(2).toLowerCase(),
        ));
      } else {
        properties.add(IigpufbProperty(
          key: entry.key,
          dataType: 'string',
          value: rawVal,
        ));
      }
    }

    return IigpufbCpuEntry(
      cpuModel: model,
      igpuName: igpu,
      note: note,
      properties: properties,
    );
  }
}
