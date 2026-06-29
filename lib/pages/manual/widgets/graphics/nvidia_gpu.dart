import 'package:flutter/material.dart';
import 'package:rapidefi/utils/config/models/nvram/boot_arg_model.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import 'package:rapidefi/pages/shared/widgets/boot_arg_choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/scrollable_choice_list_panel.dart';

class NvidiaGPU extends StatefulWidget {
  const NvidiaGPU({
    super.key,
    this.selected = false,
    this.onChanged,
  });

  final bool selected;
  final ValueChanged<bool>? onChanged;

  @override
  State<NvidiaGPU> createState() => _NvidiaGPUState();
}

class _NvidiaGPUState extends State<NvidiaGPU> {
  final String tip = r'''
  Nvidia支持的显卡系列如下:
    •	Tesla 系列（8000 - 300 系列）: 原生免驱最高支持macOS High Sierra 10.13.x(可能需要修正NVCAP),更高需要OCLP补丁(不支持Metal)
       例如:8600GT,9600GT,GT210,GT220,GT240 等,显卡太老,而且可能需要修正NVCAP,不建议使用!
    •	Kepler 系列（600 - 800 系列）: 原生免驱最高支持macOS Big Sur 11.x,更高需要OCLP补丁(支持Metal,真驱动)
       Kepler核心: GT630,GT635,GT640,GTX650,GTX660,GTX680,GT710,GT720,GT730,GT740,GTX760,GTX Titan Z,GTX Titan Black等
       Kepler核心专业卡: NVS 510,Quadro 410,Quadro K420,Quadro K600,Quadro K2000等
    •	Fermi, Maxwell, Pascal 系列: Webdriver最高支持macOS High Sierra 10.13.x, macOS Big Sur 11.x以上系统需要勾选如下启动参数,然后OCLP补丁(不支持Metal,假驱动) 
       Fermi系列: GT605,GT610,GT620,GT630,GT705,GT710,GT720,GT730,GT740等
       Maxwell系列: GTX750,GTX750Ti,GTX950,GTX960,GTX970,GTX980等 
       Pascal系列: GTX1050,GTX1060,GTX1070,GTX1080等
  Nvidia不支持的显卡系列如下(11以上系列都不支持):
    •	16 ~ 50系列: GTX1650,GTX1660,RTX 2050,RTX 2060,RTX 3050,RTX 3060,RTX 4050,RTX 4060,RTX 5060,RTX 5070等
  ''';

  @override
  Widget build(BuildContext context) {
    final bootArgOptions = <BootArgModel>[
      ConfigNvram.ngfxcompat_ngfxgl_nvda_drv_vrl,
    ];
    final selectedBootArgs = widget.selected
        ? bootArgOptions
        : const <BootArgModel>[];
    return ScrollableChoiceListPanel(
      child: BootArgChoiceList(
        options: bootArgOptions,
        selectedBootArgs: selectedBootArgs,
        header: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            tip,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        isMultipleSelection: true,
        allowToggle: true,
        onChanged: (value) {
          widget.onChanged?.call(value.isNotEmpty);
        },
      ),
    );
  }
}
