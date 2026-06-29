import 'package:fluent_ui/fluent_ui.dart';
import 'package:rapidefi/pages/shared/widgets/title_card.dart';
import 'package:rapidefi/utils/config/models/enums/motherboard_enum.dart';
import 'package:rapidefi/widgets/radio_option_group.dart';

import 'package:rapidefi/pages/shared/widgets/choice_chip_tile.dart';

class AMDWidget extends StatefulWidget {
  final List<String> labels;
  final Function(SpecialMotherboard, String)? onChanged;
  final ValueChanged? onAPUChanged;
  final ValueChanged? onPrecastMMIOChanged;
  final SpecialMotherboard specialMotherboard;
  final bool showRyzenGPU;
  final bool useRyzenGPU;
  final bool usePrecastMMIO;
  final bool showAMDSpecialMainboards;
  final String amdCore;
  const AMDWidget({
    super.key,
    this.specialMotherboard = SpecialMotherboard.amdNormal,
    required this.labels,
    this.onAPUChanged,
    this.onPrecastMMIOChanged,
    this.onChanged,
    this.showAMDSpecialMainboards = false,
    this.useRyzenGPU = false,
    this.usePrecastMMIO = false,
    this.showRyzenGPU = false,
    this.amdCore = '4',
  });

  @override
  State<AMDWidget> createState() => _AMDWidgetState();
}

class _AMDWidgetState extends State<AMDWidget> {
  late String amdCore = widget.amdCore;
  late SpecialMotherboard specialMotherboard = widget.specialMotherboard;
  late bool showRyzenGPU = widget.showRyzenGPU;
  late bool useRyzenGPU = widget.useRyzenGPU;
  late bool usePrecastMMIO = widget.usePrecastMMIO;
  late bool showAMDSpecialMainboards = widget.showAMDSpecialMainboards;

  @override
  void didUpdateWidget(covariant AMDWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (amdCore != widget.amdCore) {
      amdCore = widget.amdCore;
    }

    if (specialMotherboard != widget.specialMotherboard) {
      specialMotherboard = widget.specialMotherboard;
    }

    if (showRyzenGPU != widget.showRyzenGPU) {
      showRyzenGPU = widget.showRyzenGPU;
    }

    if (useRyzenGPU != widget.useRyzenGPU) {
      useRyzenGPU = widget.useRyzenGPU;
    }

    if (usePrecastMMIO != widget.usePrecastMMIO) {
      usePrecastMMIO = widget.usePrecastMMIO;
    }

    if (showAMDSpecialMainboards != widget.showAMDSpecialMainboards) {
      showAMDSpecialMainboards = widget.showAMDSpecialMainboards;
    }
  }

  Widget cores() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'AMD核心数:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(
          width: 10,
        ),
        ComboBox<String>(
          isExpanded: false,
          value: amdCore,
          items: widget.labels.map((e) {
            return ComboBoxItem(
              value: e,
              child: Text(e),
            );
          }).toList(),
          onChanged: (info) {
            amdCore = info!;
            setState(() {});
            widget.onChanged?.call(specialMotherboard, amdCore);
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TitleCard(
      title: '',
      content: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          Wrap(
            children: [
              cores(),
              const SizedBox(
                width: 20,
              ),
              if (showRyzenGPU)
                ChoiceChipTile(
                    label: "7000~9000系CPU",
                    selected: usePrecastMMIO,
                    onChanged: (bo) {
                      usePrecastMMIO = bo;
                      widget.onPrecastMMIOChanged?.call(usePrecastMMIO);
                      setState(() {});
                    }),
              const SizedBox(
                width: 20,
              ),
              if (showRyzenGPU)
                ChoiceChipTile(
                    label: "使用AMD核显输出显示",
                    selected: useRyzenGPU,
                    onChanged: (bo) {
                      useRyzenGPU = bo;
                      widget.onAPUChanged?.call(useRyzenGPU);
                      setState(() {});
                    })
            ],
          ),
          showAMDSpecialMainboards
              ? RadioOptionGroup(
                  groupValue: specialMotherboard.value,
                  options: SpecialMotherboard.values
                      .where((e) => e.vendor == MotherboardVendor.amd)
                      .map((e) => RadioOptionData(
                            value: e.value,
                            label: e.text.title,
                          ))
                      .toList(),
                  onChanged: (value) {
                    specialMotherboard = SpecialMotherboard.values.firstWhere(
                      (type) => type.value == value,
                      orElse: () => SpecialMotherboard.none,
                    );
                    widget.onChanged?.call(specialMotherboard, amdCore);
                  },
                )
              : const SizedBox.shrink()
        ],
      ),
    );
  }
}
