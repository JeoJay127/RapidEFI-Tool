import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IncrementalInput extends StatefulWidget {
  final Function(int) onChanged;
  final int number;

  const IncrementalInput({
    super.key,
    required this.onChanged,
    this.number = 1,
  });

  @override
  State<IncrementalInput> createState() => _IncrementalInputState();
}

class _IncrementalInputState extends State<IncrementalInput> {
  static const int _maxValue = 300;

  late final TextEditingController _controller;
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = _normalize(widget.number);
    _controller = TextEditingController(text: _value.toString());
  }

  @override
  void didUpdateWidget(covariant IncrementalInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.number != widget.number) {
      _setValue(
        widget.number,
        notify: false,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _normalize(int value) {
    return value.clamp(0, _maxValue);
  }

  void _setValue(
    int value, {
    bool notify = true,
  }) {
    final nextValue = _normalize(value);

    _value = nextValue;

    final text = nextValue.toString();

    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    if (notify) {
      widget.onChanged(_value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.indeterminate_check_box),
          onPressed: () {
            _setValue(_value - 1);
          },
        ),
        SizedBox(
          width: 40,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              _setValue(int.tryParse(value) ?? 0);
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_box_rounded),
          onPressed: () {
            _setValue(_value + 1);
          },
        ),
      ],
    );
  }
}
