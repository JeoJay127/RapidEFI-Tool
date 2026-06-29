import 'package:flutter/material.dart';
import 'package:rapidefi/utils/config/models/enums/csr_setting_enum.dart';
import 'package:rapidefi/pages/shared/widgets/choice_list.dart';

class CSRWidget extends StatefulWidget {
  final ValueChanged onChanged;
  final CsrSetting csrsetting;
  const CSRWidget(
      {super.key, required this.onChanged, this.csrsetting = CsrSetting.none});

  @override
  State<CSRWidget> createState() => _CSRWidgetState();
}

class _CSRWidgetState extends State<CSRWidget> {
  late CsrSetting csrsetting = widget.csrsetting;

  @override
  void didUpdateWidget(covariant CSRWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.csrsetting != widget.csrsetting) {
      csrsetting = widget.csrsetting;
    }
  }

  @override
  Widget build(BuildContext context) {
    final choices = CsrSetting.values
        .where((element) => element != CsrSetting.none)
        .map((e) => e.value)
        .toList();
    final tips = CsrSetting.values
        .where((element) => element != CsrSetting.none)
        .map((e) => 'csr-active-config: ${e.nvramValue} ')
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 10,
      ),
      ChoiceList(
        tips: tips,
        choices: choices,
        selectedChoices: [csrsetting.value],
        isMultipleSelection: false,
        allowToggle: true,
        subTitle: "可选项-根据需求设置,默认关闭SIP",
        onChanged: (List<String> value) {
          String? selectedValue = value.firstOrNull;
          csrsetting = CsrSetting.values.firstWhere(
            (type) => type.value == selectedValue,
            orElse: () => CsrSetting.none,
          );
          setState(() {});
          widget.onChanged.call(csrsetting);
        },
      ),
    ]);
  }
}
