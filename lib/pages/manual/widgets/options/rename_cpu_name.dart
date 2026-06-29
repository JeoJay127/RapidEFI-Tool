import 'package:fluent_ui/fluent_ui.dart';
import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/utils/config/models/enums/processor_type_enum.dart';

class RenameCPUNameWidget extends StatefulWidget {
  final Function(ProcessorType, String?) onChanged;
  final ProcessorType processorType;
  final String? cpuName;
  const RenameCPUNameWidget(
      {super.key,
      required this.onChanged,
      this.processorType = ProcessorType.none,
      this.cpuName});

  @override
  State<RenameCPUNameWidget> createState() => _RenameCPUNameWidgetState();
}

class _RenameCPUNameWidgetState extends State<RenameCPUNameWidget> {
  late ProcessorType processorType = widget.processorType;
  late String? cpuName = widget.cpuName;
  late final TextEditingController _controller =
      TextEditingController(text: cpuName ?? '');
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant RenameCPUNameWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.processorType != widget.processorType ||
        oldWidget.cpuName != widget.cpuName) {
      processorType = widget.processorType;
      cpuName = widget.cpuName;
      if (!_focusNode.hasFocus) {
        _controller.text = cpuName ?? '';
      }
    }
  }

  Widget cpunameText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          const Text(
            '输入CPU名称(不填则显示Win下CPU名称):',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(
            width: 10,
          ),
          Flexible(
              child: Container(
            constraints: const BoxConstraints(
              maxWidth: 160.0, // 设置最大宽度
            ),
            child: TextBox(
              controller: _controller,
              placeholder: '在此输入CPU名称',
              onChanged: (value) {
                cpuName = value;
                setState(() {});
                widget.onChanged.call(processorType, cpuName);
              },
            ),
          ))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final choices = ProcessorType.values
        .where((element) => element != ProcessorType.none)
        .map((e) => e.text.description)
        .toList();
    final tips = ProcessorType.values
        .where((element) => element != ProcessorType.none)
        .map((e) => e.text.title)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10,
        ),
        ChoiceList(
          tips: tips,
          choices: choices,
          selectedChoices: [processorType.text.description],
          isMultipleSelection: false,
          allowToggle: true,
          subTitle: "可选项-自定义CPU名称",
          header: processorType != ProcessorType.none
              ? cpunameText()
              : const SizedBox.shrink(),
          onChanged: (List<String> value) {
            String? selectedValue = value.firstOrNull;
            processorType = ProcessorType.values.firstWhere(
              (type) => type.text.description == selectedValue,
              orElse: () => ProcessorType.none,
            );
            if (processorType == ProcessorType.none) {
              cpuName = '';
              _controller.text = '';
            }
            widget.onChanged.call(processorType, cpuName);
            // 设置焦点
            _focusNode.requestFocus();
            setState(() {});
          },
        )
      ],
    );
  }
}
