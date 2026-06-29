import 'package:flutter/material.dart';

class ChoiceChipTile extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final String tooltip;
  final String? tip;
  final bool showBorder;
  final TextStyle? labelStyle;
  final TextStyle? tipStyle;

  const ChoiceChipTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.tooltip = '',
    this.tip,
    this.showBorder = false,
    this.labelStyle,
    this.tipStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurface.withValues(alpha: 0.38);
    final backgroundColor =
        selected ? selectedColor.withValues(alpha: 0.05) : Colors.transparent;
    final textColor =
        selected ? selectedColor : Theme.of(context).textTheme.bodyLarge!.color;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onChanged(!selected),
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          decoration: showBorder
              ? BoxDecoration(
                  border: Border.all(
                    color: selected ? selectedColor : unselectedColor,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                  color: backgroundColor,
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: selected,
                checkColor: Colors.white,
                onChanged: (value) => onChanged(value!),
                activeColor: selectedColor,
              ),
              const SizedBox(width: 4.0),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tip != null && tip!.isNotEmpty) ...[
                      Text(
                        tip!,
                        style: tipStyle ??
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                      ),
                      const SizedBox(height: 2.0),
                    ],
                    Text(
                      label,
                      style: labelStyle ??
                          TextStyle(
                            color: textColor,
                          ),
                      softWrap: true, // 自动换行
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
