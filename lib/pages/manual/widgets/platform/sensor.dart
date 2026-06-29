import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/formatters/kext_label.dart';
import 'package:rapidefi/pages/shared/widgets/kext_choice_list.dart';

class Sensor extends StatelessWidget {
  final List<KernelKext> selectedKexts;
  final ValueChanged<List<KernelKext>>? onChanged;
  const Sensor({
    super.key,
    this.onChanged,
    this.selectedKexts = const [],
  });

  static final choices = [
    ConfigKernel.SMCLightSensor,
    ConfigKernel.SMCDellSensors,
    ConfigKernel.YogaSMC,
    ConfigKernel.AsusSMC,
  ];

  @override
  Widget build(BuildContext context) {
    final choices = Sensor.choices;
    return KextChoiceList(
      choices: choices,
      selectedChoices: choices.where(selectedKexts.contains).toList(),
      showBundleNameTips: true,
      isMultipleSelection: true,
      allowToggle: true,
      subTitle: '传感器驱动(除非必要,否则不建议勾选)',
      labelBuilder: kextFunctionOrBundleLabel,
      onChanged: (List<KernelKext> value) {
        final picked = value.toList();
        onChanged?.call(picked);
      },
    );
  }
}
