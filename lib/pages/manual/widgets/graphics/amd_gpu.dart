import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rapidefi/utils/config/models/nvram/boot_arg_model.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/utils/config/services/config_option_provider.dart';
import 'package:rapidefi/pages/shared/widgets/boot_arg_choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/kext_choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/scrollable_choice_list_panel.dart';

class AMDGPU extends StatefulWidget {
  const AMDGPU({
    super.key,
    this.onNootRXChanged,
    this.nootRXSelected = false,
  });
  final ValueChanged<bool>? onNootRXChanged;
  final bool nootRXSelected;
  @override
  State<AMDGPU> createState() => _AMDGPUState();
}

class _AMDGPUState extends State<AMDGPU> {
  static final List<BootArgModel> _bootArgOptions = [
    ConfigNvram.agdpmod_pikera,
    ConfigNvram.agdpmod_vit9696,
    ConfigNvram.agdpmod_ignore,
    ConfigNvram.radpg15,
    ConfigNvram.amd_no_dgpu_accel,
    ConfigNvram.raddvi,
    ConfigNvram.unfairgva,
    ConfigNvram.radcodec,
    ConfigNvram.applbkl,
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigOptionProvider>(builder: (context, provider, child) {
      final nootRXSelected =
          provider.selectedKexts.contains(ConfigKernel.NootRX);

      return ScrollableChoiceListPanel(
        child: BootArgChoiceList(
          options: _bootArgOptions,
          selectedBootArgs: provider.selectedBootArgs,
          isMultipleSelection: true,
          allowToggle: true,
          onChanged: (value) {
            provider.updateBootArgsForOptions(_bootArgOptions, value);
          },
          footer: KextChoiceList(
            tips: const ['NootRX.kext'],
            choices: [ConfigKernel.NootRX],
            selectedChoices: nootRXSelected ? [ConfigKernel.NootRX] : [],
            isMultipleSelection: true,
            labelBuilder: (kext) => kext.note.join(' '),
            onChanged: (value) {
              final selected = value.isNotEmpty;
              provider.updateKexts(
                [ConfigKernel.NootRX],
                selected ? [ConfigKernel.NootRX] : [],
              );
              widget.onNootRXChanged?.call(selected);
            },
          ),
        ),
      );
    });
  }
}
