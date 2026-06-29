import 'package:rapidefi/utils/config/catalogs/bluetooth_nvram/bluetooth_nvram_option.dart';
import 'package:flutter/material.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_add.dart';
import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/scrollable_choice_list_panel.dart';

class BluetoothWidget extends StatefulWidget {
  final ValueChanged<String?>? onChanged;
  final NvramAdd? nvramAdd;
  final List<BluetoothNvramOption> nvramOptions;
  final BluetoothNvramOption? selectedNvramOption;

  const BluetoothWidget({
    super.key,
    this.onChanged,
    this.nvramAdd,
    this.nvramOptions = const [],
    this.selectedNvramOption,
  });

  @override
  State<BluetoothWidget> createState() => _BluetoothWidgetState();
}

class _BluetoothWidgetState extends State<BluetoothWidget> {
  String tip = r'''
  蓝牙驱动说明：
  1. 当勾选Intel WiFi时，会根据macOS版本自动添加Intel蓝牙驱动，无需手动勾选！！！
  2. 当勾选Broadcom WiFi时，会根据macOS版本自动添加Broadcom蓝牙驱动，无需手动勾选！！！
  3. 当勾选Atheros WiFi时，会自动添加Atheros蓝牙驱动,无需手动勾选！！！
  4. 没有勾选WiFi型号时或者未做说明的蓝牙型号,需要手动勾选！！！
  5. 由于蓝牙走USB通道,如果添加驱动和补丁仍然不正常,请确保USB定制良好！！！
  ''';

  @override
  Widget build(BuildContext context) {
    final nvramOptions = widget.nvramOptions;
    final selectedNvramOption = widget.selectedNvramOption;
    return ScrollableChoiceListPanel(
      children: [
        Text(tip, style: TextStyle(fontSize: 13)),
        ChoiceList(
          subTitle: '蓝牙NVRAM参数:',
          choices: nvramOptions.map((option) => option.title).toList(),
          selectedChoices: [
            if (selectedNvramOption != null) selectedNvramOption.title
          ],
          allowToggle: true,
          onChanged: (value) {
            final title = value.firstOrNull;
            final option = nvramOptions
                .where((option) => option.title == title)
                .firstOrNull;
            widget.onChanged?.call(option?.id);
          },
        )
      ],
    );
  }
}
