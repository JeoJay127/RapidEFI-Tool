import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/formatters/kext_label.dart';
import 'package:rapidefi/pages/shared/widgets/kext_choice_list.dart';

class Battery extends StatelessWidget {
  final List<KernelKext> selectedKexts;
  final ValueChanged<List<KernelKext>>? onChanged;
  const Battery({
    super.key,
    this.onChanged,
    this.selectedKexts = const [],
  });

  static final choices = [
    ConfigKernel.ACPIBatteryManager,
    ConfigKernel.SMCBatteryManager,
  ];

  @override
  Widget build(BuildContext context) {
    final choices = Battery.choices;
    final selected = [
      if (selectedKexts.contains(ConfigKernel.ACPIBatteryManager))
        ConfigKernel.ACPIBatteryManager,
      if (selectedKexts.contains(ConfigKernel.SMCBatteryManager))
        ConfigKernel.SMCBatteryManager,
    ];
    return KextChoiceList(
      choices: choices,
      selectedChoices: selected,
      showBundleNameTips: true,
      isMultipleSelection: false,
      allowToggle: true,
      subTitle: '电池驱动',
      labelBuilder: kextFunctionOrBundleLabel,
      onChanged: (List<KernelKext> value) {
        final picked = value.toList();
        onChanged?.call(picked);
      },
    );
  }
}
