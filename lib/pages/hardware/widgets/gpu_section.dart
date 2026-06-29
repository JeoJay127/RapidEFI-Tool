import 'package:flutter/material.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_compatibility.dart';
import 'package:rapidefi/pages/hardware/models/hardware_models.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_utils.dart';
import 'package:rapidefi/pages/hardware/widgets/gpu_display_name.dart';
import 'package:rapidefi/pages/hardware/widgets/hardware_shared.dart';
import 'package:rapidefi/utils/hardware/analysis/gpu_compatibility_data.dart';

class GpuSection extends StatelessWidget {
  final Map<String, dynamic> rawInfo;
  final bool detailed;

  const GpuSection(this.rawInfo, {super.key, this.detailed = false});

  @override
  Widget build(BuildContext context) {
    final entries = hardwareDevices(rawInfo['GPU']).where((entry) {
      final gpu = safeMap(entry.value);
      return safeStr(gpu['Device ID']).isNotEmpty;
    }).toList();
    final connectedGpuNames = _connectedInternalGpuNames(rawInfo);
    final enforceInternalDisplay = _isLaptopPlatform(rawInfo) &&
        entries.length > 1 &&
        connectedGpuNames.isNotEmpty;
    final items = entries
        .map(
          (entry) => _GpuCompatibilityItem.from(
            rawInfo,
            entry,
            connectedGpuNames: connectedGpuNames,
            enforceInternalDisplay: enforceInternalDisplay,
          ),
        )
        .toList();
    final lines = entries.asMap().entries.map((indexedEntry) {
      final entry = indexedEntry.value;
      final item = items[indexedEntry.key];
      final gpu = safeMap(entry.value);
      final deviceId = safeStr(gpu['Device ID']);
      final record = GpuCompatibilityData.findSync(deviceId);
      final displayName =
          hardwareGpuDisplayName(entry.key, gpu, record: record);
      final targetDeviceId = record?.spoofDeviceIdPart ?? '';
      final color = item.note.level == CompatibilityLevel.supported
          ? null
          : item.note.color;
      return HardwareDeviceBlock([
        Wrap(
            spacing: 18,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SelectableText(
                joinNonEmpty([
                  displayName,
                  '设备ID: $deviceId',
                  '核心: ${gpuCodename(gpu)}',
                  gpu['Device Type'],
                ], '    '),
                style: TextStyle(fontSize: 14, height: 1.25, color: color),
              ),
              if (record?.requiresSpoof == true && targetDeviceId.isNotEmpty)
                SelectableText('需要仿冒ID: $targetDeviceId',
                    style: TextStyle(color: color, fontSize: 13)),
            ]),
        if (detailed) HardwarePathLine(gpu, color: color),
      ]);
    }).toList();
    if (lines.isEmpty) return const SizedBox.shrink();
    return HardwareSection(
      '显卡',
      lines,
      trailing: _GpuCompatibilityPanel(items: items),
    );
  }

  Set<String> _connectedInternalGpuNames(Map<String, dynamic> rawInfo) {
    return hardwareDevices(rawInfo['Monitor'])
        .map((entry) => _normalizeGpuName(
              safeStr(safeMap(entry.value)['Connected GPU']),
            ))
        .where((name) => name.isNotEmpty)
        .toSet();
  }

  static String _normalizeGpuName(String value) {
    return normalizeHardwareGpuDisplayName(value);
  }

  bool _isLaptopPlatform(Map<String, dynamic> rawInfo) {
    final board = safeMap(rawInfo['Motherboard']);
    final platform = safeStr(board['Platform']).toLowerCase();

    return platform == 'laptop' || platform == '笔记本';
  }
}

class _GpuCompatibilityPanel extends StatelessWidget {
  const _GpuCompatibilityPanel({
    required this.items,
  });

  final List<_GpuCompatibilityItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // 单显卡：只显示兼容性
    if (items.length == 1) {
      final item = items.first;
      if (item.note.level == CompatibilityLevel.supported) {
        return _GpuCompatibilityStatusText(
          note: CompatibilityNote.supported('兼容'),
        );
      }

      return _GpuCompatibilityText(item: item, showName: false);
    }

    // 多显卡：如果全部都没有兼容库记录，且没有白名单/规则支持项，不兼容
    if (items.every((item) => item.record == null) &&
        items
            .every((item) => item.note.level != CompatibilityLevel.supported) &&
        !items.any((item) => item.isLoadingCompatibility)) {
      return _GpuCompatibilityStatusText(
        note: CompatibilityNote.unsupported('不兼容'),
      );
    }

    // 多显卡：判断是否存在不兼容 / 有限兼容
    final hasProblemGpu = items.any(
      (item) => item.note.level != CompatibilityLevel.supported,
    );

    // 多显卡：如果全部兼容，只显示一个“兼容”
    if (!hasProblemGpu) {
      return _GpuCompatibilityStatusText(
        note: CompatibilityNote.supported('兼容'),
      );
    }

    // 多显卡：只要有一个不兼容 / 有限兼容，列出所有显卡兼容性
    final visibleItems = items;

    final colors = hardwareThemeColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < visibleItems.length; i++) ...[
          _GpuCompatibilityText(
            item: visibleItems[i],
            showName: true,
          ),
          if (i != visibleItems.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Divider(
                height: 1,
                thickness: 1,
                color: colors.borderColor,
              ),
            ),
        ],
      ],
    );
  }
}

class _GpuCompatibilityText extends StatelessWidget {
  const _GpuCompatibilityText({
    required this.item,
    required this.showName,
  });

  final _GpuCompatibilityItem item;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final colors = hardwareThemeColors(context);
    final text = item.detailText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showName && item.name.isNotEmpty) ...[
          Text(
            item.name,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: colors.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          text.isEmpty ? item.note.text : text,
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: item.note.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GpuCompatibilityStatusText extends StatelessWidget {
  const _GpuCompatibilityStatusText({required this.note});

  final CompatibilityNote note;

  @override
  Widget build(BuildContext context) {
    return Text(
      note.text,
      style: TextStyle(
        fontSize: 12,
        height: 1.35,
        color: note.color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _GpuCompatibilityItem {
  const _GpuCompatibilityItem({
    required this.name,
    required this.note,
    required this.record,
  });

  final String name;
  final CompatibilityNote note;
  final GpuCompatibilityRecord? record;

  bool get isLoadingCompatibility => note.text == '兼容性加载中';

  String get statusText {
    return switch (note.level) {
      CompatibilityLevel.supported => '兼容',
      CompatibilityLevel.limited => '有限兼容',
      CompatibilityLevel.unsupported => '不兼容',
    };
  }

  String get detailText {
    final hidden = <String>{
      name.trim(),
      record?.name.trim() ?? '',
      record?.codename.trim() ?? '',
    }..removeWhere((value) => value.isEmpty);

    final lines = note.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !hidden.contains(line))
        .toList();

    return lines.join('\n');
  }

  factory _GpuCompatibilityItem.from(
    Map<String, dynamic> rawInfo,
    MapEntry<String, dynamic> entry, {
    required Set<String> connectedGpuNames,
    required bool enforceInternalDisplay,
  }) {
    final gpu = safeMap(entry.value);
    final record = GpuCompatibilityData.findSync(safeStr(gpu['Device ID']));
    final baseNote = gpuEntryCompatibility(rawInfo, entry.key, gpu);
    final note = enforceInternalDisplay &&
            !_matchesConnectedInternalGpu(
                entry.key, gpu, record, connectedGpuNames)
        ? CompatibilityNote.unsupported('不兼容,没有直连内屏')
        : baseNote;
    return _GpuCompatibilityItem(
      name: hardwareGpuDisplayName(entry.key, gpu, record: record),
      note: note,
      record: record,
    );
  }

  static bool _matchesConnectedInternalGpu(
    String fallbackName,
    Map<String, dynamic> gpu,
    GpuCompatibilityRecord? record,
    Set<String> connectedGpuNames,
  ) {
    final aliases = <String>{
      fallbackName,
      safeStr(gpu['Name']),
      safeStr(gpu['DeviceDesc']),
      record?.name ?? '',
    }
        .map(GpuSection._normalizeGpuName)
        .where((name) => name.isNotEmpty)
        .toSet();

    return aliases.any(connectedGpuNames.contains);
  }
}
