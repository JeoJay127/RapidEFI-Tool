import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/widgets/scrollable_choice_list_panel.dart';
import 'package:rapidefi/utils/config/support/intel_connector_patch.dart';

class IgpuConnectorCustomization extends StatefulWidget {
  const IgpuConnectorCustomization({
    super.key,
    required this.platformCode,
    required this.igPlatformId,
    required this.preferExternalConnectors,
    required this.connectorAllData,
    this.onChanged,
  });

  final String platformCode;
  final String igPlatformId;
  final bool preferExternalConnectors;
  final Map<int, String> connectorAllData;
  final void Function(int connectorIndex, String value)? onChanged;

  @override
  State<IgpuConnectorCustomization> createState() =>
      _IgpuConnectorCustomizationState();
}

class _IgpuConnectorCustomizationState
    extends State<IgpuConnectorCustomization> {
  late IntelConnectorPlatformTemplate _template;
  late List<_ConnectorDraft> _values;

  @override
  void initState() {
    super.initState();
    _template = IntelConnectorPlatformTemplate.forConfig(
      platformCode: widget.platformCode,
      igPlatformId: widget.igPlatformId,
      preferExternalConnectors: widget.preferExternalConnectors,
    );
    _values = _initialValues();
  }

  @override
  void didUpdateWidget(covariant IgpuConnectorCustomization oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.platformCode == widget.platformCode &&
        oldWidget.igPlatformId == widget.igPlatformId &&
        oldWidget.preferExternalConnectors == widget.preferExternalConnectors &&
        oldWidget.connectorAllData == widget.connectorAllData) {
      return;
    }

    _template = IntelConnectorPlatformTemplate.forConfig(
      platformCode: widget.platformCode,
      igPlatformId: widget.igPlatformId,
      preferExternalConnectors: widget.preferExternalConnectors,
    );
    _values = _initialValues();
  }

  List<_ConnectorDraft> _initialValues() {
    final parsedValues = <_ConnectorDraft>[];
    final usedBusIds = <String>{};
    final entries = widget.connectorAllData.entries
        .where(
          (entry) => IntelConnectorPlatformTemplate.allConnectorIndexes
              .contains(entry.key),
        )
        .toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    for (final entry in entries) {
      final parsed = _template.parse(entry.key, entry.value);
      if (!_template.supported ||
          !_template.connectorIndexes.contains(entry.key) ||
          parsed == null ||
          usedBusIds.contains(parsed.busIdHex)) {
        parsedValues.add(
          _ConnectorDraft(
            connectorIndex: entry.key,
            value: null,
          ),
        );
        continue;
      }
      usedBusIds.add(parsed.busIdHex);
      parsedValues.add(
        _ConnectorDraft(
          connectorIndex: entry.key,
          value: parsed,
        ),
      );
    }

    return parsedValues;
  }

  Set<int> get _usedConnectors {
    return _values
        .map((value) => value.connectorIndex)
        .toSet();
  }

  Set<String> _usedBusIdsExcept(int itemIndex) {
    final used = <String>{};
    for (var i = 0; i < _values.length; i++) {
      if (i == itemIndex) continue;
      final value = _values[i].value;
      if (value != null) {
        used.add(value.busIdHex);
      }
    }
    return used;
  }

  void _addConnector() {
    if (!_template.supported ||
        _values.length >= _template.connectorIndexes.length) {
      return;
    }

    final usedConnectors = _usedConnectors;
    final connectorIndex = _template.connectorIndexes
        .firstWhere((index) => !usedConnectors.contains(index));
    final value = _template.defaultValue(
      connectorIndex,
      usedBusIds: _usedBusIdsExcept(-1),
    );
    setState(() {
      _values = [
        ..._values,
        _ConnectorDraft(
          connectorIndex: connectorIndex,
          value: value,
        ),
      ];
    });
    _emitAllValues();
  }

  void _removeConnector(int itemIndex) {
    final draft = _values[itemIndex];
    widget.onChanged?.call(draft.connectorIndex, '');

    setState(() {
      _values.removeAt(itemIndex);
    });
  }

  void _updateValue(
    int itemIndex,
    IntelConnectorPatchValue nextValue,
  ) {
    final previous = _values[itemIndex];
    if (previous.connectorIndex != nextValue.connectorIndex) {
      widget.onChanged?.call(previous.connectorIndex, '');
    }

    setState(() {
      _values[itemIndex] = _ConnectorDraft(
        connectorIndex: nextValue.connectorIndex,
        value: nextValue,
      );
    });
    _emit(nextValue);
  }

  void _emit(IntelConnectorPatchValue value) {
    widget.onChanged?.call(value.connectorIndex, value.allData);
  }

  void _emitAllValues() {
    for (final draft in _values) {
      final value = draft.value;
      if (value != null) {
        _emit(value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScrollableChoiceListPanel(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
          child: Text(
            _template.supported
                ? '当前Framebuffer: ${_template.framebufferId}。按WhateverGreen官方表生成 framebuffer-conX-alldata。'
                : '当前Framebuffer不支持结构化推荐值; 已有原始值可删除后重新选择受支持的核显基础配置。',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        ..._values.asMap().entries.map(
              (entry) => _buildConnectorEditor(entry.key, entry.value),
            ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: '添加接口定制',
              onPressed: !_template.supported ||
                      _values.length >= _template.connectorIndexes.length
                  ? null
                  : _addConnector,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectorEditor(
    int itemIndex,
    _ConnectorDraft draft,
  ) {
    final value = draft.value;
    if (value == null) {
      return _buildUnparsedItem(itemIndex, draft.connectorIndex);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              _buildDropdown<int>(
                label: '接口',
                value: value.connectorIndex,
                items: _availableConnectorIndexes(itemIndex),
                itemLabel: (item) => 'con$item',
                onChanged: (connectorIndex) {
                  final next = _template.defaultValue(
                    connectorIndex,
                    usedBusIds: _usedBusIdsExcept(itemIndex),
                  );
                  _updateValue(
                    itemIndex,
                    next.copyWith(type: value.type),
                  );
                },
              ),
              _buildDropdown<String>(
                label: '索引号',
                value: value.indexHex,
                items: _template.portIndexes,
                itemLabel: (item) => item,
                onChanged: (indexHex) => _updateValue(
                  itemIndex,
                  value.copyWith(indexHex: indexHex),
                ),
              ),
              _buildDropdown<String>(
                label: '总线ID',
                value: value.busIdHex,
                items: _availableBusIds(itemIndex, value.busIdHex),
                itemLabel: (item) => item,
                onChanged: (busIdHex) => _updateValue(
                  itemIndex,
                  value.copyWith(busIdHex: busIdHex),
                ),
              ),
              _buildDropdown<IntelConnectorType>(
                label: '接口类型',
                value: value.type,
                items: IntelConnectorType.values,
                itemLabel: (item) =>
                    item.recommended ? item.label : '${item.label}(老接口)',
                onChanged: (type) => _updateValue(
                  itemIndex,
                  value.copyWith(type: type),
                ),
              ),
              IconButton(
                tooltip: '删除 con${value.connectorIndex} 定制',
                onPressed: () => _removeConnector(itemIndex),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          SelectableText(
            'framebuffer-con${value.connectorIndex}-alldata = ${value.allData}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildUnparsedItem(int itemIndex, int connectorIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          const Text(
            '原始值不可解析',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Text(
            'con$connectorIndex',
            style: const TextStyle(fontSize: 12),
          ),
          const Text(
            '请删除后重新添加结构化接口定制',
            style: TextStyle(fontSize: 12),
          ),
          IconButton(
            tooltip: '删除不可解析接口定制',
            onPressed: () => _removeConnector(itemIndex),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  List<int> _availableConnectorIndexes(int itemIndex) {
    final current = _values[itemIndex].connectorIndex;
    final used = _usedConnectors..remove(current);
    return _template.connectorIndexes
        .where((item) => !used.contains(item))
        .toList();
  }

  List<String> _availableBusIds(int itemIndex, String currentBusId) {
    final used = _usedBusIdsExcept(itemIndex);
    return _template.busIds
        .where((item) => item == currentBusId || !used.contains(item))
        .toList();
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T item) itemLabel,
    required ValueChanged<T> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        fluent.ComboBox<T>(
          isExpanded: false,
          value: items.contains(value) ? value : items.first,
          items: items
              .map(
                (item) => fluent.ComboBoxItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                ),
              )
              .toList(),
          onChanged: (item) {
            if (item != null) {
              onChanged(item);
            }
          },
        ),
      ],
    );
  }
}

class _ConnectorDraft {
  const _ConnectorDraft({
    required this.connectorIndex,
    required this.value,
  });

  final int connectorIndex;
  final IntelConnectorPatchValue? value;
}
