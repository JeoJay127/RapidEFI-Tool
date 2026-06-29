import 'package:flutter/material.dart';

class RadioOptionItem extends StatelessWidget {
  final String value;
  final String label;
  final bool selected;
  final double radioScale;
  final ValueChanged<String> onChanged;

  const RadioOptionItem({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.selected = false,
    this.radioScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.only(left: 3, right: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: radioScale,
              child: Radio<String>(
                value: value,
                activeColor: primaryColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}