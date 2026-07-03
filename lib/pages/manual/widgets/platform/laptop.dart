import 'package:fluent_ui/fluent_ui.dart';
import 'package:rapidefi/pages/manual/widgets/platform/battery.dart';
import 'package:rapidefi/pages/manual/widgets/platform/laptop_other.dart';
import 'package:rapidefi/pages/manual/widgets/platform/sensor.dart';
import 'package:rapidefi/pages/shared/widgets/title_card.dart';
import 'package:rapidefi/pages/manual/widgets/platform/touchpad.dart';
import 'package:rapidefi/utils/config/models/kernel/kext_group.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/widgets/state_keep_container.dart';

// 笔记本特有驱动
class LaptopWidget extends StatefulWidget {
  final List<KernelKext> selectedKexts;
  final ValueChanged<List<KernelKext>>? onChanged;
  const LaptopWidget({
    super.key,
    this.onChanged,
    this.selectedKexts = const [],
  });

  static final List<KernelKext> removableKexts = KextGroup.uniqueKexts([
    ...TouchPad.removableKexts,
    ...Battery.choices,
    ...Sensor.choices,
    ...LaptopOther.choices,
  ]);

  @override
  State<LaptopWidget> createState() => _LaptopWidgetState();
}

class _LaptopWidgetState extends State<LaptopWidget> {
  int currentIndex = 0;

  final TabWidthBehavior tabWidthBehavior = TabWidthBehavior.sizeToContent;

  final CloseButtonVisibilityMode closeButtonVisibilityMode =
      CloseButtonVisibilityMode.never;

  final bool showScrollButtons = true;

  final List<String> titles = const [
    '键盘触摸板驱动',
    '电池驱动',
    '传感器驱动',
    '其他修复',
  ];

  final List<IconData> iconDatas = const [
    FluentIcons.keyboard_classic,
    FluentIcons.power_b_i_logo,
    FluentIcons.hot,
    FluentIcons.more,
  ];

  void _emitMergedSelection({
    required List<KernelKext> sectionRemovableKexts,
    required List<KernelKext> sectionSelectedKexts,
  }) {
    final merged = <KernelKext>[];

    for (final kext in widget.selectedKexts) {
      final isLaptopKext = LaptopWidget.removableKexts.contains(kext);
      final isCurrentSectionKext = sectionRemovableKexts.contains(kext);

      if (isLaptopKext && !isCurrentSectionKext && !merged.contains(kext)) {
        merged.add(kext);
      }
    }

    for (final kext in sectionSelectedKexts) {
      if (!merged.contains(kext)) {
        merged.add(kext);
      }
    }

    if (ConfigKextGroups.bigSurface.kexts.any(merged.contains)) {
      merged.remove(ConfigKernel.BrightnessKeys);
    }

    widget.onChanged?.call(merged);
  }

  List<Widget> _buildSubviews() {
    return [
      StateKeepContainer(
        child: SingleChildScrollView(
          child: TouchPad(
            selectedKexts: widget.selectedKexts,
            onChanged: (selectedKexts) {
              _emitMergedSelection(
                sectionRemovableKexts: TouchPad.removableKexts,
                sectionSelectedKexts: selectedKexts,
              );
            },
          ),
        ),
      ),
      StateKeepContainer(
        child: Battery(
          selectedKexts: widget.selectedKexts,
          onChanged: (selectedKexts) {
            _emitMergedSelection(
              sectionRemovableKexts: Battery.choices,
              sectionSelectedKexts: selectedKexts,
            );
          },
        ),
      ),
      StateKeepContainer(
        child: Sensor(
          selectedKexts: widget.selectedKexts,
          onChanged: (selectedKexts) {
            _emitMergedSelection(
              sectionRemovableKexts: Sensor.choices,
              sectionSelectedKexts: selectedKexts,
            );
          },
        ),
      ),
      StateKeepContainer(
        child: LaptopOther(
          selectedKexts: widget.selectedKexts,
          onChanged: (selectedKexts) {
            _emitMergedSelection(
              sectionRemovableKexts: LaptopOther.choices,
              sectionSelectedKexts: selectedKexts,
            );
          },
        ),
      ),
    ];
  }

  Tab _generateTab(int index, List<Widget> subviews) {
    return Tab(
      text: Text(titles[index]),
      icon: Icon(iconDatas[index]),
      body: subviews[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    final subviews = _buildSubviews();
    final tabs = List.generate(
      titles.length,
      (index) => _generateTab(index, subviews),
    );

    return TitleCard(
      title: '笔记本相关驱动:',
      subTitle: '(主要用于笔记本)',
      expander: SizedBox(
        height: 380,
        child: TabView(
          tabs: tabs,
          currentIndex: currentIndex,
          onChanged: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          tabWidthBehavior: tabWidthBehavior,
          closeButtonVisibility: closeButtonVisibilityMode,
          showScrollButtons: showScrollButtons,
        ),
      ),
    );
  }
}
