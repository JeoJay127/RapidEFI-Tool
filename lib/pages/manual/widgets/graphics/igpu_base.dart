import 'package:flutter/material.dart';
import 'package:rapidefi/extension/string_extension.dart';
import 'package:rapidefi/utils/config/models/device_properties/device_property_item.dart';
import 'package:rapidefi/utils/config/models/device_properties/igpu_model.dart';
import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/scrollable_choice_list_panel.dart';

///核显基础配置
class IgpuBase extends StatefulWidget {
  final ValueChanged onChanged;
  final Function(Set<DevicePropertyItem>)? onDevicePropertiesChanged;
  final List<List<IgpuPropertyModel>> igpuModels;
  final List<IgpuPropertyModel>? selectedigpuModel;
  const IgpuBase(
      {super.key,
      required this.onChanged,
      required this.igpuModels,
      this.selectedigpuModel,
      this.onDevicePropertiesChanged});

  @override
  State<IgpuBase> createState() => _IgpuBaseState();
}

class _IgpuBaseState extends State<IgpuBase> {
  late List<List<IgpuPropertyModel>> igpuModels = widget.igpuModels;
  late List<IgpuPropertyModel>? selectedModel = widget.selectedigpuModel;

  @override
  void didUpdateWidget(covariant IgpuBase oldWidget) {
    super.didUpdateWidget(oldWidget);

    igpuModels = widget.igpuModels;
    selectedModel = widget.selectedigpuModel;
  }

  @override
  Widget build(BuildContext context) {
    final choices = igpuModels
        .map((e) => e.first.propertyItems.first.comment ?? '')
        .toList();
    final selectedChoice = selectedModel != null && selectedModel!.isNotEmpty
        ? selectedModel?.first.propertyItems.first.comment
        : '';
    final tips = igpuModels.map((e) {
      final str =
          "${e.first.propertyItems.first.key} : ${e.first.propertyItems.first.value}";
      return str;
    }).toList();
    return ScrollableChoiceListPanel(
      children: [
        ChoiceList(
          initiallyExpanded: true,
          tips: tips,
          choices: choices,
          selectedChoices: [selectedChoice.nullSafe],
          subTitle: "对应则勾选,否则不勾选",
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
        ),
      ],
    );
  }
}
