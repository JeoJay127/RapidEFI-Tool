import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:rapidefi/extension/string_extension.dart';
import 'package:rapidefi/utils/config/models/device_properties/device_property_item.dart';
import 'package:rapidefi/utils/config/models/device_properties/igpu_model.dart';
import 'package:rapidefi/utils/config/models/device_properties/iigpufb_model.dart';
import 'package:rapidefi/utils/config/support/iigpufb_service.dart';
import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/scrollable_choice_list_panel.dart';

/// 核显基础配置
class IgpuBase extends StatefulWidget {
  final ValueChanged onChanged;

  /// 高级属性变更回调（与 IgpuAdvance 共用同一 callback）
  final Function(Set<DevicePropertyItem>)? onDevicePropertiesChanged;

  /// 当前已选中的高级属性集合，用于合并新增条目时不覆盖已有设置
  final Set<DevicePropertyItem>? selectedDevicePropertyItems;

  final List<List<IgpuPropertyModel>> igpuModels;
  final List<IgpuPropertyModel>? selectedigpuModel;

  const IgpuBase({
    super.key,
    required this.onChanged,
    required this.igpuModels,
    this.selectedigpuModel,
    this.onDevicePropertiesChanged,
    this.selectedDevicePropertyItems,
  });

  @override
  State<IgpuBase> createState() => _IgpuBaseState();
}

enum _ConfigMode { preset, cpu }

class _IgpuBaseState extends State<IgpuBase> {
  // ── 模式 ───────────────────────────────────────────────────────
  _ConfigMode _mode = _ConfigMode.preset;

  // ── 原有状态 ───────────────────────────────────────────────────
  late List<List<IgpuPropertyModel>> igpuModels = widget.igpuModels;
  late List<IgpuPropertyModel>? selectedModel = widget.selectedigpuModel;

  // ── iigpufb 状态 ───────────────────────────────────────────────
  List<IigpufbGeneration> _generations = [];
  bool _fbLoading = true;

  String? _selectedGeneration;
  IigpufbCpuEntry? _selectedCpu;

  /// 勾选的属性索引集合（对应 _selectedCpu.properties 的下标）
  Set<int> _checkedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadFbData();
  }

  Future<void> _loadFbData() async {
    final gens = await IigpufbService.instance.load();
    if (mounted) {
      setState(() {
        _generations = gens;
        _fbLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant IgpuBase oldWidget) {
    super.didUpdateWidget(oldWidget);
    igpuModels = widget.igpuModels;
    selectedModel = widget.selectedigpuModel;
  }

  // ── 切换模式 ───────────────────────────────────────────────────
  void _switchMode(_ConfigMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      if (mode == _ConfigMode.preset) {
        // 切到预设方案：清除 CPU 相关状态
        _selectedGeneration = null;
        _selectedCpu = null;
        _checkedIndices = {};
      } else {
        // 切到 CPU 模式：清除预设选择
        selectedModel = null;
        widget.onChanged.call(null);
      }
    });
  }

  // ── 选代数 ─────────────────────────────────────────────────────
  void _onGenerationChanged(String? gen) {
    setState(() {
      _selectedGeneration = gen;
      _selectedCpu = null;
      _checkedIndices = {};
    });
  }

  // ── 选 CPU 型号 ────────────────────────────────────────────────
  void _onCpuChanged(IigpufbCpuEntry? cpu) {
    if (cpu == null) return;
    setState(() {
      _selectedCpu = cpu;
      // 默认全部勾选
      _checkedIndices =
          Set<int>.from(List.generate(cpu.properties.length, (i) => i));
    });
    // 选中 CPU 后立即应用，并提示
    _applySelected();
  }

  // ── 全选 / 全不选 ──────────────────────────────────────────────
  void _toggleAll(bool selectAll) {
    if (_selectedCpu == null) return;
    setState(() {
      _checkedIndices = selectAll
          ? Set<int>.from(
              List.generate(_selectedCpu!.properties.length, (i) => i))
          : {};
    });
    _applySelected(silent: true);
  }

  // ── 切换单个属性勾选 ───────────────────────────────────────────
  void _toggleIndex(int idx) {
    setState(() {
      if (_checkedIndices.contains(idx)) {
        _checkedIndices.remove(idx);
      } else {
        _checkedIndices.add(idx);
      }
    });
    _applySelected(silent: true);
  }

  // ── 应用选中条目 ───────────────────────────────────────────────
  void _applySelected({bool silent = false}) {
    final cpu = _selectedCpu;
    if (cpu == null || _checkedIndices.isEmpty) return;

    // 以现有高级属性为基础，按 key 做 Map 便于合并
    final merged = <String, DevicePropertyItem>{
      for (final item in widget.selectedDevicePropertyItems ?? {})
        if (item.key != null) item.key!: item,
    };

    // 将勾选的属性写入（同 key 覆盖，新 key 追加）
    for (final idx in _checkedIndices) {
      final prop = cpu.properties[idx];
      merged[prop.key] = DevicePropertyItem(
        key: prop.key,
        dataType: prop.dataType,
        value: prop.value,
        comment: '来自 ${cpu.cpuModel} (${cpu.igpuName})',
        display: true,
      );
    }

    widget.onDevicePropertiesChanged?.call(merged.values.toSet());

    if (!silent) {
      showToast(
        '已从 ${cpu.cpuModel} 加载 ${cpu.igpuName} 核显配置，写入 ${_checkedIndices.length} 项属性',
        duration: const Duration(seconds: 3),
      );
    }
  }

  // ============================================================
  //  UI 构建
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ScrollableChoiceListPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        _buildModeToggle(context),
        const SizedBox(height: 8),
        if (_mode == _ConfigMode.cpu)
          _buildCpuSelectorSection(context)
        else
          _buildPresetSection(context),
      ],
    );
  }

  // ── 模式切换按钮 ──────────────────────────────────────────────
  Widget _buildModeToggle(BuildContext context) {
    return SegmentedButton<_ConfigMode>(
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
      segments: const [
        ButtonSegment(
          value: _ConfigMode.preset,
          label: Text('预设方案'),
          icon: Icon(Icons.list_alt_outlined, size: 16),
        ),
        ButtonSegment(
          value: _ConfigMode.cpu,
          label: Text('按 CPU 型号'),
          icon: Icon(Icons.memory_outlined, size: 16),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (selected) => _switchMode(selected.first),
    );
  }

  // ── 预设方案分支 ──────────────────────────────────────────────
  Widget _buildPresetSection(BuildContext context) {
    final choices = igpuModels
        .map((e) => e.first.propertyItems.first.comment ?? '')
        .toList();
    final selectedChoice = selectedModel != null && selectedModel!.isNotEmpty
        ? selectedModel?.first.propertyItems.first.comment
        : '';
    final tips = igpuModels.map((e) {
      return '${e.first.propertyItems.first.key} : ${e.first.propertyItems.first.value}';
    }).toList();

    return ChoiceList(
      initiallyExpanded: true,
      tips: tips,
      choices: choices,
      selectedChoices: [selectedChoice.nullSafe],
      subTitle: '对应则勾选，否则不勾选',
      allowToggle: true,
      onChanged: (List<String> value) {
        if (value.isNotEmpty) {
          setState(() {
            selectedModel = widget.igpuModels.firstWhere(
              (e) => e.first.propertyItems.first.comment == value.first,
            );
          });
        } else {
          setState(() {
            selectedModel = null;
          });
        }
        widget.onChanged.call(selectedModel);
      },
    );
  }

  // ── CPU 选择面板 ──────────────────────────────────────────────
  Widget _buildCpuSelectorSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: const Text(
          '从 CPU 型号加载核显配置',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: _selectedCpu != null
            ? Text(
                '已选：${_selectedCpu!.cpuModel}  ${_selectedCpu!.igpuName}',
                style:
                    TextStyle(fontSize: 12, color: colorScheme.primary),
              )
            : const Text(
                '选择 CPU 代数和型号，勾选要应用的属性',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _fbLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDropdownRow(context),
                      if (_selectedCpu != null) ...[
                        const SizedBox(height: 8),
                        _buildPreviewRow(context),
                        const SizedBox(height: 8),
                        _buildPropertyChecklist(context),
                      ],
                      const SizedBox(height: 4),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── 两个下拉 ──────────────────────────────────────────────────
  Widget _buildDropdownRow(BuildContext context) {
    final genNames = _generations.map((g) => g.name).toList();
    final currentGen = _generations
        .where((g) => g.name == _selectedGeneration)
        .firstOrNull;
    final cpuList = currentGen?.cpus ?? <IigpufbCpuEntry>[];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // CPU 代数
        SizedBox(
          width: 230,
          child: DropdownButtonFormField<String>(
            value: _selectedGeneration,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'CPU 代数',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            hint: const Text('选择代数'),
            items: genNames
                .map((g) =>
                    DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: _onGenerationChanged,
          ),
        ),
        // CPU 型号
        SizedBox(
          width: 260,
          child: DropdownButtonFormField<IigpufbCpuEntry>(
            value: _selectedCpu,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'CPU 型号',
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
              enabled: cpuList.isNotEmpty,
            ),
            hint: const Text('选择 CPU'),
            items: cpuList
                .map((cpu) => DropdownMenuItem(
                      value: cpu,
                      child: Text(
                        cpu.cpuModel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: cpuList.isEmpty ? null : _onCpuChanged,
          ),
        ),
      ],
    );
  }

  // ── 关键信息预览行 ─────────────────────────────────────────────
  Widget _buildPreviewRow(BuildContext context) {
    final cpu = _selectedCpu!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 4,
        children: [
          _previewItem('核显', cpu.igpuName, colorScheme),
          if (cpu.platformId != null)
            _previewItem(
              cpu.platformIdKey ?? 'platform-id',
              cpu.platformId!,
              colorScheme,
            ),
          _previewItem('型号', cpu.modelName, colorScheme),
          if (cpu.note != null)
            _previewItem('⚠️ 备注', cpu.note!, colorScheme,
                valueColor: Colors.orange.shade700),
        ],
      ),
    );
  }

  Widget _previewItem(
    String label,
    String value,
    ColorScheme cs, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: valueColor ?? cs.primary,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  // ── 属性勾选列表 ──────────────────────────────────────────────
  Widget _buildPropertyChecklist(BuildContext context) {
    final cpu = _selectedCpu!;
    final props = cpu.properties;
    final allSelected = _checkedIndices.length == props.length;
    final noneSelected = _checkedIndices.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 全选 / 全不选 标题行
        InkWell(
          onTap: () => _toggleAll(!allSelected),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Checkbox(
                  tristate: true,
                  value: allSelected
                      ? true
                      : noneSelected
                          ? false
                          : null,
                  onChanged: (v) => _toggleAll(v == true),
                ),
                const Text(
                  '选择要应用的属性',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_checkedIndices.length}/${props.length} 已选)',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 4),
        // 属性条目
        ...props.asMap().entries.map((entry) {
          final idx = entry.key;
          final prop = entry.value;
          return _buildPropertyRow(
              idx, prop, _checkedIndices.contains(idx), context);
        }),
      ],
    );
  }

  Widget _buildPropertyRow(
    int idx,
    IigpufbProperty prop,
    bool checked,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isData = prop.dataType == 'data';

    return InkWell(
      onTap: () => _toggleIndex(idx),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: checked
              ? colorScheme.primaryContainer
                  .withValues(alpha: 0.25)
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              onChanged: (_) => _toggleIndex(idx),
              materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            // key 名
            SizedBox(
              width: 220,
              child: Text(
                prop.key,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: checked
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 类型徽章
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isData
                    ? Colors.blue.withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                prop.dataType.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: isData ? Colors.blue : Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 值
            Expanded(
              child: Text(
                prop.value,
                style: const TextStyle(
                    fontSize: 12, fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
