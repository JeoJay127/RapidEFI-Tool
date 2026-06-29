import 'package:flutter/material.dart';
import 'radio_option_item.dart';

enum RadioGroupDirection { row, column, wrap }

class RadioOptionGroup extends StatefulWidget {
  final List<RadioOptionData> options;
  final String groupValue;
  final ValueChanged<String> onChanged;

  final RadioGroupDirection direction;
  final double horizontalSpacing;
  final double verticalSpacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  final WrapAlignment wrapAlignment;
  final WrapCrossAlignment wrapCrossAlignment;
  final WrapAlignment wrapRunAlignment;
  final double radioScale;

  const RadioOptionGroup({
    super.key,
    required this.options,
    required this.groupValue,
    required this.onChanged,
    this.direction = RadioGroupDirection.wrap,
    this.horizontalSpacing = 8.0,
    this.verticalSpacing = 6.0,
    this.radioScale = 0.8,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.wrapAlignment = WrapAlignment.start,
    this.wrapCrossAlignment = WrapCrossAlignment.center,
    this.wrapRunAlignment = WrapAlignment.start,
  });

  @override
  State<RadioOptionGroup> createState() => _RadioOptionGroupState();
}

class _RadioOptionGroupState extends State<RadioOptionGroup> {
  late String _groupValue = widget.groupValue;

  @override
  void didUpdateWidget(covariant RadioOptionGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_groupValue != widget.groupValue) {
      _groupValue = widget.groupValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: _groupValue,
      onChanged: (value) {
        if (value == null || value == _groupValue) {
          return;
        }

        setState(() {
          _groupValue = value;
        });

        widget.onChanged(value);
      },
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    final children = widget.options.map((option) {
      final selected = option.value == _groupValue;

      return RadioOptionItem(
        radioScale: widget.radioScale,
        value: option.value,
        label: option.label,
        selected: selected,
        onChanged: (value) {
          if (value == _groupValue) {
            return;
          }

          setState(() {
            _groupValue = value;
          });

          widget.onChanged(value);
        },
      );
    }).toList();

    switch (widget.direction) {
      case RadioGroupDirection.column:
        return Column(
          crossAxisAlignment: widget.crossAxisAlignment,
          mainAxisAlignment: widget.mainAxisAlignment,
          children: _addSpacing(
            children,
            widget.verticalSpacing,
            Axis.vertical,
          ),
        );

      case RadioGroupDirection.row:
        return Row(
          crossAxisAlignment: widget.crossAxisAlignment,
          mainAxisAlignment: widget.mainAxisAlignment,
          children: _addSpacing(
            children,
            widget.horizontalSpacing,
            Axis.horizontal,
          ),
        );

      case RadioGroupDirection.wrap:
        return Wrap(
          spacing: widget.horizontalSpacing,
          runSpacing: widget.verticalSpacing,
          alignment: widget.wrapAlignment,
          crossAxisAlignment: widget.wrapCrossAlignment,
          runAlignment: widget.wrapRunAlignment,
          children: children,
        );
    }
  }

  List<Widget> _addSpacing(
    List<Widget> items,
    double spacing,
    Axis axis,
  ) {
    if (items.isEmpty) return [];

    final result = <Widget>[];

    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);

      if (i < items.length - 1) {
        result.add(
          SizedBox(
            width: axis == Axis.horizontal ? spacing : 0,
            height: axis == Axis.vertical ? spacing : 0,
          ),
        );
      }
    }

    return result;
  }
}

class RadioOptionData {
  final String value;
  final String label;

  const RadioOptionData({
    required this.value,
    required this.label,
  });
}