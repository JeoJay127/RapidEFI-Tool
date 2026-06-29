import 'package:flutter/material.dart';

class DropDownMenuWidget extends StatefulWidget {
  const DropDownMenuWidget(
      {super.key, required this.labels, this.onChanged, this.initialIndex = 0});
  final List<String?> labels;
  final int initialIndex;
  final Function(String, int)? onChanged;

  @override
  State<DropDownMenuWidget> createState() => _DropDownMenuWidgetState();
}

class _DropDownMenuWidgetState extends State<DropDownMenuWidget> {
  String selectVaule = "";
  late List<DropdownMenuItem> menuItems;

  @override
  void initState() {
    super.initState();
    menuItems = widget.labels.map((text) {
      return DropdownMenuItem(
        value: text,
        child: Text(
          text ?? "",
        ),
      );
    }).toList();
    if (widget.labels.isNotEmpty &&
        widget.labels.length >= widget.initialIndex + 1) {
      selectVaule = widget.labels[widget.initialIndex]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: DropdownButton(
        value: selectVaule,
        focusColor: Colors.transparent,
        isExpanded: true,
        padding: const EdgeInsets.only(left: 5),
        onChanged: (value) {
          int index = widget.labels.indexOf(value);
          widget.onChanged?.call(value, index);
          setState(() {
            selectVaule = value;
          });
        },
        items: menuItems,
      ),
    );
  }
}
