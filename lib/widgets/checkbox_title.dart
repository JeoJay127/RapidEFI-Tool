//  checkbox_title.dart 
//  Created by JeoJay127 
//
import 'package:flutter/material.dart';

class CheckboxTile extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final String tooltip;
  final bool showBorder;

  const CheckboxTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.tooltip = '',
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurface.withAlpha(
      (255.0 * 0.38).round(),
    );
    final backgroundColor = selected
        ? selectedColor.withAlpha((255.0 * 0.38).round())
        : Colors.transparent;
    final textColor = selected
        ? selectedColor
        : Theme.of(context).textTheme.bodyLarge!.color;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onChanged(!selected),
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          decoration: showBorder
              ? BoxDecoration(
                  border: Border.all(
                    color: selected ? selectedColor : unselectedColor,
                  ),
                  borderRadius: BorderRadius.circular(6.0),
                  color: backgroundColor,
                )
              : null,
          padding: const EdgeInsets.only(
            left: 2.0,
            right: 6.0,
            top: 2.0,
            bottom: 2.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: selected,
                  onChanged: (value) => onChanged(value!),
                  activeColor: selectedColor,
                  checkColor: Colors.white,
                ),
              ),

              const SizedBox(width: 2.0),
              Flexible(
                child: Text(label, style: TextStyle(color: textColor, fontSize: 11.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
