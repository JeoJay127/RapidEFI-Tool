import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/services/apple_alc_resolver.dart';
import 'package:rapidefi/widgets/flutter_picker/flutter_picker.dart';
import 'package:rapidefi/widgets/number_input.dart';

import 'package:rapidefi/pages/shared/formatters/kext_label.dart';
import 'package:rapidefi/pages/shared/widgets/custom_textfield.dart';
import 'package:rapidefi/pages/shared/widgets/kext_choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/tip_switch.dart';

class SoundWidget extends StatefulWidget {
  final Function(KernelKext?, String, List<Object>?)? onChanged;
  final List<Object>? alcidPickerSelection;
  final KernelKext? soundDriverType;
  final String? hpet;

  const SoundWidget({
    super.key,
    this.onChanged,
    this.alcidPickerSelection,
    this.hpet,
    this.soundDriverType,
  });

  @override
  State<SoundWidget> createState() => _SoundWidgetState();
}

class _SoundWidgetState extends State<SoundWidget> {
  static const String _defaultHpetPath = r'\_SB.PCI0.LPCB.HPET';

  late KernelKext? soundDriverType = widget.soundDriverType;
  late String hpet = widget.hpet ?? '';
  late final TextEditingController _controller = TextEditingController(
    text: hpet.isEmpty ? _defaultHpetPath : hpet,
  );
  final FocusNode _focusNode = FocusNode();
  List<Object>? _lastPickerSelection;

  final String tip = r'''
  常见HPET路径:
  \_SB.PCI0.LPCB.HPET
  \_SB.PCI0.LPC.HPET
  \_SB.PCI0.HPET
  此选项用于修复部分声卡IRQ问题!注意:如果你的声卡没有IRQ问题,请不要使用此功能!!!
  ''';

  @override
  void initState() {
    super.initState();
    _lastPickerSelection = widget.alcidPickerSelection;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _emitChanged();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SoundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.soundDriverType != widget.soundDriverType) {
      soundDriverType = widget.soundDriverType;
    }

    if (oldWidget.alcidPickerSelection != widget.alcidPickerSelection) {
      _lastPickerSelection = widget.alcidPickerSelection;
    }

    if (oldWidget.hpet != widget.hpet) {
      hpet = widget.hpet ?? '';
      final text = hpet.isEmpty ? _defaultHpetPath : hpet;
      if (_controller.text != text) {
        _controller.text = text;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  int get _selectedLayoutId {
    final selection = _lastPickerSelection;
    if (selection != null && selection.length >= 3) {
      final value = selection[2];
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return 1;
  }

  bool get _enableHpetPatch => hpet.trim().isNotEmpty;

  List<Object> _selectionWithLayoutId(int layoutId) {
    final selection = _lastPickerSelection;
    if (selection != null && selection.length == 3) {
      return [selection[0], selection[1], layoutId];
    }
    return ['', '', layoutId];
  }

  void _emitChanged() {
    widget.onChanged?.call(
      soundDriverType,
      _enableHpetPatch ? hpet : '',
      _lastPickerSelection,
    );
  }

  Widget configalcid() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ALC布局ID:',
                ),
                IncrementalInput(
                  number: _selectedLayoutId,
                  onChanged: (number) {
                    _lastPickerSelection = _selectionWithLayoutId(number);
                    _emitChanged();
                  },
                ),
                const SizedBox(
                  width: 10,
                ),
                ActionChip(
                  backgroundColor:
                      isDarkMode ? Colors.grey[850] : Colors.grey[50],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  label: const Text(
                    "查询布局ID",
                  ),
                  onPressed: () {
                    showPickerModal(context);
                  },
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 15,
              children: [
                const Text(
                  '高精度计时器ACPI路径(用于修复声卡IRQ问题):',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                CustomTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minWidth: 120,
                  maxWidth: 200,
                  expandWidth: true,
                  adaptiveWidth: true,
                  style: const TextStyle(fontSize: 13),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9_\\.]'),
                    ),
                  ],
                  keyboardType: TextInputType.text,
                  enabled: _enableHpetPatch,
                  onChanged: (value, _) {
                    hpet = value;
                  },
                ),
                TipSwitch(
                  tip: tip,
                  title: '修复IRQ',
                  checked: _enableHpetPatch,
                  onChanged: (value) {
                    setState(() {
                      if (value) {
                        hpet = _controller.text.trim().isEmpty
                            ? _defaultHpetPath
                            : _controller.text.trim();
                        _controller.text = hpet;
                      } else {
                        hpet = '';
                        _controller.text = _defaultHpetPath;
                      }
                    });
                    _emitChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showPickerModal(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selecteds = AppleALCResolver.findAlcidPositionBySelection(
      _lastPickerSelection,
      _selectedLayoutId,
    );
    final data = AppleALCResolver.loadPickerData();
    Picker(
      containerColor: Colors.transparent,
      title: Column(
        spacing: 5,
        children: [
          Text(
            "选择声卡布局ID(数据库:${AppleALCResolver.published} v${AppleALCResolver.version})",
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            "(鼠标滑轮选择后,点击确认即可)",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      adapter: PickerDataAdapter(pickerData: data),
      selecteds: selecteds,
      changeToFirst: true,
      hideHeader: true,
      textScaler: const TextScaler.linear(0.6),
      columnFlex: const [2, 2, 1],
      onConfirm: (Picker picker, List value) {
        final values = picker.getSelectedValues();
        _lastPickerSelection = AppleALCResolver.selectionFromPickerValues(
          values,
        );
        setState(() {});
        _emitChanged();
      },
    ).showDialog(
      this.context,
      barrierDismissible: false,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      builder: (context, pickerWidget) {
        return pickerWidget;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final soundChoices = [ConfigKernel.AppleALC, ConfigKernel.VoodooHDA];
    return KextChoiceListCard(
      title: "声卡驱动:",
      cardSubTitle: '(默认使用AppleALC驱动)',
      choices: soundChoices,
      selectedChoices:
          soundDriverType != null && soundDriverType!.bundlePath.isNotEmpty
              ? [soundDriverType!]
              : [],
      isMultipleSelection: false,
      allowToggle: true,
      labelBuilder: kextDescriptionLabel,
      header: soundDriverType?.bundlePath == ConfigKernel.AppleALC.bundlePath
          ? configalcid()
          : const SizedBox.shrink(),
      onChanged: (List<KernelKext> value) {
        soundDriverType = value.firstOrNull;
        _emitChanged();
        setState(() {});
      },
    );
  }
}
