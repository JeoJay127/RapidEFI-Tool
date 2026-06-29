import 'package:flutter/material.dart';
import 'package:rapidefi/pages/shared/widgets/choice_chip_tile.dart';

class ChoiceList<T> extends StatefulWidget {
  final List<String>? tips; // 可选
  final List<T> choices;
  final List<T> selectedChoices;
  final bool isMultipleSelection;
  final bool allowToggle;
  final String title;
  final String subTitle;
  final Widget header;
  final Widget footer;
  final double width;
  final List<String> tiplist;
  final bool showTip;
  final bool initiallyExpanded;
  final String? expandTitle;
  final bool alwaysShowTitle;
  final bool showBorder;
  final String Function(T choice)? labelBuilder;
  final ValueChanged<List<T>>? onChanged;

  const ChoiceList({
    super.key,
    required this.choices,
    this.onChanged,
    this.tips,
    this.selectedChoices = const [],
    this.isMultipleSelection = false,
    this.allowToggle = true,
    this.showBorder = false,
    this.labelBuilder,
    this.title = '',
    this.subTitle = '',
    this.header = const SizedBox.shrink(),
    this.footer = const SizedBox.shrink(),
    this.width = double.infinity,
    this.tiplist = const [],
    this.showTip = false,
    this.initiallyExpanded = false,
    this.alwaysShowTitle = true,
    this.expandTitle,
  }) : assert(
          tips == null || tips.length == choices.length,
          'tips 长度必须和 choices 一致',
        );

  @override
  State createState() => _ChoiceListState<T>();
}

class _ChoiceListState<T> extends State<ChoiceList<T>> {
  late List<T> _selectedChoices;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedChoices = _normalizeSelectedChoices(widget.selectedChoices);
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant ChoiceList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final choicesChanged = !_listEqualsByValue(
      oldWidget.choices,
      widget.choices,
    );

    final selectedChanged = !_listEqualsByValue(
      oldWidget.selectedChoices,
      widget.selectedChoices,
    );
    final normalizedSelectedChoices =
        _normalizeSelectedChoices(widget.selectedChoices);
    final internalSelectedOutOfSync = !_listEqualsByValue(
      _selectedChoices,
      normalizedSelectedChoices,
    );

    final expandedChanged =
        oldWidget.initiallyExpanded != widget.initiallyExpanded;

    if (choicesChanged || selectedChanged || internalSelectedOutOfSync) {
      _selectedChoices = normalizedSelectedChoices;
    }

    if (expandedChanged) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  List<T> _normalizeSelectedChoices(List<T> source) {
    return source.where((item) => widget.choices.contains(item)).toList();
  }

  bool _listEqualsByValue(List<T> a, List<T> b) {
    if (identical(a, b)) return true;

    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }

  bool get _isAllSelected {
    return widget.choices.isNotEmpty &&
        _selectedChoices.length == widget.choices.length;
  }

  bool get _isNoneSelected => _selectedChoices.isEmpty;

  void _toggleAllSelection() {
    setState(() {
      if (_isAllSelected) {
        _selectedChoices.clear();
      } else {
        _selectedChoices = List<T>.from(widget.choices);
      }
    });

    widget.onChanged?.call(List<T>.from(_selectedChoices));
  }

  void _handleChipSelection(T choice, bool isSelected) {
    setState(() {
      if (widget.isMultipleSelection) {
        if (isSelected) {
          if (!_selectedChoices.contains(choice)) {
            _selectedChoices.add(choice);
          }
        } else {
          _selectedChoices.remove(choice);
        }
      } else {
        if (!widget.allowToggle && _selectedChoices.contains(choice)) {
          return;
        }

        _selectedChoices = isSelected ? [choice] : [];
      }
    });

    widget.onChanged?.call(List<T>.from(_selectedChoices));
  }

  @override
  Widget build(BuildContext context) {
    final subWidgets = widget.choices.asMap().entries.map((entry) {
      final index = entry.key;
      final choice = entry.value;
      final label = widget.labelBuilder?.call(choice) ?? choice.toString();
      final tip = widget.tips?[index];
      final isSelected = _selectedChoices.contains(choice);

      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: ChoiceChipTile(
          tip: tip,
          label: label,
          selected: isSelected,
          showBorder: widget.showBorder,
          onChanged: (value) => _handleChipSelection(choice, value),
          tooltip: widget.showTip && widget.tiplist.isNotEmpty
              ? widget.tiplist[index]
              : "",
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.header,
        if (widget.title.isNotEmpty || widget.subTitle.isNotEmpty)
          _buildTitle(),
        if (widget.expandTitle != null && widget.expandTitle!.isNotEmpty)
          _buildExpandableContent(subWidgets)
        else
          Wrap(children: subWidgets),
        widget.footer,
      ],
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (widget.subTitle.isNotEmpty) const SizedBox(width: 5),
          if (widget.subTitle.isNotEmpty)
            Flexible(
              child: Text(
                widget.subTitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableContent(List<Widget> subWidgets) {
    final expansionContent = Wrap(children: subWidgets);

    return widget.alwaysShowTitle
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpandableTitle(),
              expansionContent,
            ],
          )
        : ExpansionTile(
            childrenPadding: EdgeInsets.zero,
            collapsedBackgroundColor: Colors.black.withValues(alpha: 0.08),
            initiallyExpanded: widget.initiallyExpanded,
            title: _buildExpandableTitle(),
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            children: _isExpanded ? [expansionContent] : [],
          );
  }

  Widget _buildExpandableTitle() {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final textColor = _isAllSelected
        ? selectedColor
        : Theme.of(context).textTheme.bodyLarge!.color;

    return InkWell(
      onTap: _toggleAllSelection,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              tristate: true,
              checkColor: Colors.white,
              value: _isAllSelected
                  ? true
                  : _isNoneSelected
                      ? false
                      : null,
              onChanged: (_) => _toggleAllSelection(),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                widget.expandTitle!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
