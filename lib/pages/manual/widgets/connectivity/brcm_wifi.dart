import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/widgets/kext_group_choice_list.dart';
import 'package:rapidefi/utils/config/models/kernel/kext_group.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';

class BrcmWifi extends StatelessWidget {
  final ValueChanged<List<KernelKext>>? onChanged;
  final List<KernelKext> selectedKexts;

  const BrcmWifi({
    super.key,
    this.onChanged,
    this.selectedKexts = const [],
  });

  static final List<KextGroup> choices = ConfigKextGroups.brcmWifiGroups;
  static final List<KernelKext> removableKexts = KextGroup.expand(choices);

  @override
  Widget build(BuildContext context) {
    return KextGroupChoiceList(
      choices: choices,
      selectedKexts: selectedKexts,
      isMultipleSelection: false,
      allowToggle: true,
      onChanged: (value) {
        onChanged?.call(value);
      },
    );
  }
}
