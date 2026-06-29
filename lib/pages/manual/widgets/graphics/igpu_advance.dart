import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/scrollable_choice_list_panel.dart';
import 'package:rapidefi/utils/config/models/device_properties/device_property_item.dart';
import 'package:rapidefi/utils/config/support/platform_properties.dart';

class IgpuAdvance extends StatefulWidget {
  final Function(Set<DevicePropertyItem>)? onDevicePropertiesChanged;
  final List<IgpuDevicePropertyOption> availableOptions;
  final Set<DevicePropertyItem>? selectedDevicePropertyItems;

  const IgpuAdvance({
    super.key,
    required this.availableOptions,
    this.onDevicePropertiesChanged,
    this.selectedDevicePropertyItems,
  });

  @override
  State<IgpuAdvance> createState() => _IgpuAdvanceState();
}

class _IgpuAdvanceState extends State<IgpuAdvance> {
  static const _categoryOrder = [
    igpuCategoryMemory,
    igpuCategoryHaswell,
    igpuCategoryIvyBridge,
    igpuCategorySandyBridge,
    igpuCategoryArrandale,
    igpuCategoryHdmi,
    igpuCategoryIceLake,
    igpuCategoryCommon,
  ];

  void _updateSelectedOptions(
    List<IgpuDevicePropertyOption> selectedOptions,
    List<IgpuDevicePropertyOption> changedOptions,
  ) {
    final selectedItems = Set<DevicePropertyItem>.from(
      widget.selectedDevicePropertyItems ?? const <DevicePropertyItem>{},
    );
    final exactRemovableItems = changedOptions
        .expand((option) => option.items)
        .map(_propertyIdentity)
        .toSet();
    final replacementKeys = selectedOptions
        .expand((option) => option.items)
        .map((item) => item.key)
        .whereType<String>()
        .toSet();

    selectedItems.removeWhere(
      (item) =>
          exactRemovableItems.contains(_propertyIdentity(item)) ||
          replacementKeys.contains(item.key),
    );
    selectedItems.addAll(
      selectedOptions.expand(
        (option) => option.items.map((item) => item.copyWith()),
      ),
    );
    widget.onDevicePropertiesChanged?.call(selectedItems);
  }

  List<IgpuDevicePropertyOption> _changedOptionsForMultipleGroup(
    List<IgpuDevicePropertyOption> groupOptions,
    List<IgpuDevicePropertyOption> categoryOptions,
  ) {
    String? mutexGroup;
    for (final option in groupOptions) {
      if (option.mutexGroup != null) {
        mutexGroup = option.mutexGroup;
        break;
      }
    }

    if (mutexGroup == null) return groupOptions;

    return categoryOptions
        .where((option) => option.mutexGroup == mutexGroup)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems =
        widget.selectedDevicePropertyItems ?? const <DevicePropertyItem>{};
    final groupedOptions = _groupOptionsByCategory(widget.availableOptions);

    return ScrollableChoiceListPanel(
      children: _categoryOrder
          .where(groupedOptions.containsKey)
          .expand(
            (category) => _buildCategory(
              category,
              groupedOptions[category]!,
              selectedItems,
            ),
          )
          .toList(),
    );
  }

  Map<String, List<IgpuDevicePropertyOption>> _groupOptionsByCategory(
    List<IgpuDevicePropertyOption> options,
  ) {
    final grouped = <String, List<IgpuDevicePropertyOption>>{};
    for (final option in options) {
      grouped.putIfAbsent(option.category, () => []).add(option);
    }
    return grouped;
  }

  List<Widget> _buildCategory(
    String category,
    List<IgpuDevicePropertyOption> options,
    Set<DevicePropertyItem> selectedItems,
  ) {
    final widgets = <Widget>[];
    final multipleOptions =
        options.where((option) => option.exclusiveGroup == null).toList();
    final multipleGroups = _groupMultipleOptions(multipleOptions);
    final exclusiveGroups = <String, List<IgpuDevicePropertyOption>>{};

    for (final option
        in options.where((option) => option.exclusiveGroup != null)) {
      exclusiveGroups.putIfAbsent(option.exclusiveGroup!, () => []).add(option);
    }

    for (final groupOptions in multipleGroups) {
      widgets.add(
        ChoiceList<IgpuDevicePropertyOption>(
          choices: groupOptions,
          selectedChoices: _selectedOptions(groupOptions, selectedItems),
          isMultipleSelection: true,
          subTitle: widgets.isEmpty ? category : '',
          labelBuilder: (option) => option.title,
          onChanged: (value) => _updateSelectedOptions(
            value,
            _changedOptionsForMultipleGroup(groupOptions, options),
          ),
        ),
      );
    }

    for (final groupOptions in exclusiveGroups.values) {
      widgets.add(
        ChoiceList<IgpuDevicePropertyOption>(
          choices: groupOptions,
          selectedChoices: _selectedOptions(groupOptions, selectedItems),
          subTitle: multipleOptions.isEmpty && widgets.isEmpty ? category : '',
          labelBuilder: (option) => option.title,
          allowToggle: true,
          onChanged: (value) => _updateSelectedOptions(
            value,
            category == igpuCategoryHdmi ? options : groupOptions,
          ),
        ),
      );
    }

    return widgets;
  }

  List<List<IgpuDevicePropertyOption>> _groupMultipleOptions(
    List<IgpuDevicePropertyOption> options,
  ) {
    final grouped = <String, List<IgpuDevicePropertyOption>>{};
    for (final option in options) {
      final key = option.multiSelectGroup ?? '';
      grouped.putIfAbsent(key, () => []).add(option);
    }
    return grouped.values.toList();
  }

  List<IgpuDevicePropertyOption> _selectedOptions(
    List<IgpuDevicePropertyOption> options,
    Set<DevicePropertyItem> selectedItems,
  ) {
    return options
        .where(
          (option) => option.items.every(
            (item) => selectedItems.any(
              (selected) =>
                  selected.key == item.key &&
                  selected.value == item.value &&
                  selected.dataType == item.dataType,
            ),
          ),
        )
        .toList();
  }

  String _propertyIdentity(DevicePropertyItem item) =>
      '${item.key}|${item.dataType}|${item.value}';
}
