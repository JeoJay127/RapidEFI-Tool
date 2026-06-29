import 'package:rapidefi/pages/shared/widgets/kext_group_choice_list.dart';
import 'package:rapidefi/utils/config/models/kernel/kext_group.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';
import 'package:flutter/material.dart';

class TouchPad extends StatelessWidget {
  final ValueChanged<List<KernelKext>>? onChanged;
  final List<KernelKext> selectedKexts;

  const TouchPad({
    super.key,
    this.onChanged,
    this.selectedKexts = const [],
  });

  static final List<KextGroup> choices = ConfigKextGroups.touchPadGroups;
  static final List<KernelKext> removableKexts = KextGroup.expand(choices);

  @override
  Widget build(BuildContext context) {
    return KextGroupChoiceList(
      choices: choices,
      selectedKexts: selectedKexts,
      isMultipleSelection: false,
      allowToggle: true,
      subTitle: '键盘触摸板驱动',
      onChanged: (value) {
        onChanged?.call(value);
      },
    );
  }
}
