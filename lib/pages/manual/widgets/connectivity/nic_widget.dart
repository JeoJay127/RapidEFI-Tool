import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:flutter/material.dart';

import 'package:rapidefi/pages/shared/formatters/kext_label.dart';
import 'package:rapidefi/pages/shared/widgets/kext_choice_list.dart';

class NicWidget extends StatefulWidget {
  final ValueChanged? onChanged;
  final List<KernelKext>? selectedKexts;
  const NicWidget({super.key, this.onChanged, this.selectedKexts});

  static final ethernetOptions = [
    ConfigKernel.RealtekRTL8100,
    ConfigKernel.AppleIntelE1000e,
    ConfigKernel.BCM5722D,
    ConfigKernel.AtherosL1cEthernet,
    ConfigKernel.RealtekRTL8111,
    ConfigKernel.AtherosE2200Ethernet,
    ConfigKernel.AppleIGC,
    ConfigKernel.AppleIGB,
    ConfigKernel.IntelMausi,
    ConfigKernel.LucyRTL8125Ethernet,
    ConfigKernel.RTL812xLucy,
    ConfigKernel.SmallTreeIntel82576,
    ConfigKernel.IntelLucy,
  ];

  @override
  State<NicWidget> createState() => _NicWidgetState();
}

class _NicWidgetState extends State<NicWidget> {
  @override
  Widget build(BuildContext context) {
    final ethernetOptions = NicWidget.ethernetOptions;
    final selected = ethernetOptions
        .where((kext) => widget.selectedKexts?.contains(kext) ?? false)
        .toList();
    final tips = ethernetOptions.map((kext) => kext.note.join('\n')).toList();
    return KextChoiceListCard(
      title: "网卡驱动:",
      cardSubTitle: '(默认不添加网卡驱动)',
      choices: ethernetOptions,
      selectedChoices: selected,
      isMultipleSelection: true,
      allowToggle: true,
      showTip: true,
      tiplist: tips,
      labelBuilder: kextTitleLabel,
      onChanged: (List<KernelKext> value) {
        widget.onChanged?.call(value);
      },
    );
  }
}
