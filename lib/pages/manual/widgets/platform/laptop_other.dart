import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/formatters/kext_label.dart';
import 'package:rapidefi/pages/shared/widgets/kext_choice_list.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';

class LaptopOther extends StatefulWidget {
  final List<KernelKext> selectedKexts;
  final ValueChanged<List<KernelKext>>? onChanged;
  const LaptopOther({
    super.key,
    this.onChanged,
    this.selectedKexts = const [],
  });
  static final choices = [ConfigKernel.ECEnabler, ConfigKernel.BrightnessKeys];

  @override
  State<LaptopOther> createState() => _LaptopOtherState();
}

class _LaptopOtherState extends State<LaptopOther> {
  @override
  Widget build(BuildContext context) {
    final choices = LaptopOther.choices;
    return KextChoiceList(
      width: 160,
      choices: choices,
      selectedChoices: choices.where(widget.selectedKexts.contains).toList(),
      showBundleNameTips: true,
      isMultipleSelection: true,
      allowToggle: true,
      subTitle: '其他修复(除非必要,否则不建议勾选)',
      labelBuilder: kextFunctionOrBundleLabel,
      onChanged: (List<KernelKext> value) {
        final picked = value.toList();
        widget.onChanged?.call(picked);
      },
    );
  }
}
