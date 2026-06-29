import 'package:flutter/material.dart';

class ButtonSegmentWidget extends StatefulWidget {
  const ButtonSegmentWidget({
    super.key,
    required this.labels,
    this.onSelectionChanged,
    this.initialSelection,
    this.segmentHeight = 36,
    this.horizontalPadding = 16,
  });

  final List<String> labels;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final Set<String>? initialSelection;
  final double segmentHeight;
  final double horizontalPadding;

  @override
  State<ButtonSegmentWidget> createState() => _ButtonSegmentWidgetState();
}

class _ButtonSegmentWidgetState extends State<ButtonSegmentWidget> {
  late Set<String> selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialSelection ?? {widget.labels.first};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final themeColor = theme.colorScheme.primary;
    final borderColor = Colors.grey.withAlpha(
      (255.0 * (isDarkMode ? 0.6 : 0.5)).round(),
    );
    final radius = BorderRadius.circular(widget.segmentHeight / 2);

    return SizedBox(
      height: widget.segmentHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: radius,
            ),
            child: SizedBox(
              height: widget.segmentHeight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < widget.labels.length; index++)
                    _buildSegment(
                      text: widget.labels[index],
                      isLast: index == widget.labels.length - 1,
                      themeColor: themeColor,
                      borderColor: borderColor,
                      isDarkMode: isDarkMode,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegment({
    required String text,
    required bool isLast,
    required Color themeColor,
    required Color borderColor,
    required bool isDarkMode,
  }) {
    final isSelected = selected.contains(text);

    return Material(
      color: isSelected ? themeColor : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (selected.length == 1 && selected.contains(text)) {
            return;
          }
          final newSelection = {text};
          setState(() => selected = newSelection);
          widget.onSelectionChanged?.call(newSelection);
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    right: BorderSide(color: borderColor),
                  ),
          ),
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDarkMode ? Colors.grey[500] : Colors.black),
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
