import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'picker_localizations.dart';

typedef PickerSelectedCallback = void Function(
  Picker picker,
  int index,
  List<int> selected,
);

typedef PickerConfirmCallback = void Function(
    Picker picker, List<int> selected);

typedef PickerConfirmBeforeCallback = FutureOr<bool> Function(
  Picker picker,
  List<int> selected,
);

typedef PickerValueFormat<T> = String Function(T value);

typedef PickerWidgetBuilder = Widget Function(
  BuildContext context,
  Widget pickerWidget,
);

typedef PickerItemBuilder = Widget? Function(
  BuildContext context,
  String? text,
  Widget? child,
  bool selected,
  int col,
  int index,
);

class Picker<T> {
  static const double defaultTextSize = 18.0;

  /// 当前每一列的选中索引。
  final List<int> selecteds;

  /// 数据适配器，负责提供列数据和构建选项。
  final PickerAdapter adapter;

  final List<PickerDelimiter>? delimiter;

  final VoidCallback? onCancel;
  final PickerSelectedCallback? onSelect;
  final PickerConfirmCallback? onConfirm;
  final PickerConfirmBeforeCallback? onConfirmBefore;

  /// 上级列变化时，后续联动列是否回到第一项。
  final bool changeToFirst;

  final List<int>? columnFlex;

  final Widget? title;
  final Widget? cancel;
  final Widget? confirm;
  final String? cancelText;
  final String? confirmText;

  final double height;
  final double itemExtent;

  final TextStyle? textStyle;
  final TextStyle? cancelTextStyle;
  final TextStyle? confirmTextStyle;
  final TextStyle? selectedTextStyle;
  final TextAlign textAlign;
  final IconThemeData? selectedIconTheme;

  final TextScaler? textScaler;

  final EdgeInsetsGeometry? columnPadding;
  final Color? backgroundColor;
  final Color? headerColor;
  final Color? containerColor;

  final bool hideHeader;

  final bool reversedOrder;

  final WidgetBuilder? builderHeader;

  final PickerItemBuilder? onBuilderItem;

  final bool looping;

  final int smooth;

  final Widget? footer;

  final Widget selectionOverlay;

  final Decoration? headerDecoration;

  final double magnification;
  final double diameterRatio;
  final double squeeze;

  final bool printDebug;

  Widget? _widget;
  PickerWidgetState? _state;
  int _maxLevel = 1;

  Picker({
    required this.adapter,
    this.delimiter,
    List? selecteds,
    this.height = 150.0,
    this.itemExtent = 28.0,
    this.columnPadding,
    this.textStyle,
    this.cancelTextStyle,
    this.confirmTextStyle,
    this.selectedTextStyle,
    this.selectedIconTheme,
    this.textAlign = TextAlign.start,
    this.textScaler,
    this.title,
    this.cancel,
    this.confirm,
    this.cancelText,
    this.confirmText,
    this.backgroundColor,
    this.containerColor,
    this.headerColor,
    this.builderHeader,
    this.changeToFirst = false,
    this.hideHeader = false,
    this.looping = false,
    this.reversedOrder = false,
    this.headerDecoration,
    this.columnFlex,
    this.footer,
    this.smooth = 0,
    this.magnification = 1.0,
    this.diameterRatio = 1.1,
    this.squeeze = 1.45,
    this.selectionOverlay = const CupertinoPickerDefaultSelectionOverlay(),
    this.onBuilderItem,
    this.onCancel,
    this.onSelect,
    this.onConfirmBefore,
    this.onConfirm,
    this.printDebug = false,
  }) : selecteds = (selecteds ?? const <int>[])
            .map((e) => e is int ? e : int.parse(e.toString()))
            .toList();

  Widget? get widget => _widget;
  PickerWidgetState? get state => _state;

  Widget makePicker([ThemeData? themeData, bool isModal = false, Key? key]) {
    adapter.picker = this;
    _maxLevel = adapter.maxLevel;
    adapter.initSelects();

    _widget = PickerWidget(
      key: key ?? ValueKey<Picker<T>>(this),
      data: this,
      child: PickerContentWidget(
        picker: this,
        themeData: themeData,
        isModal: isModal,
      ),
    );
    return _widget!;
  }

  void show(
    ScaffoldState state, {
    ThemeData? themeData,
    Color? backgroundColor,
    PickerWidgetBuilder? builder,
  }) {
    state.showBottomSheet(
      (context) =>
          _buildWithOptionalWrapper(context, themeData, false, builder),
      backgroundColor: backgroundColor,
    );
  }

  void showBottomSheet(
    BuildContext context, {
    ThemeData? themeData,
    Color? backgroundColor,
    PickerWidgetBuilder? builder,
  }) {
    Scaffold.of(context).showBottomSheet(
      (context) =>
          _buildWithOptionalWrapper(context, themeData, false, builder),
      backgroundColor: backgroundColor,
    );
  }

  Future<T?> showModal(
    BuildContext context, {
    ThemeData? themeData,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    Color? backgroundColor,
    PickerWidgetBuilder? builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      backgroundColor: backgroundColor,
      builder: (context) =>
          _buildWithOptionalWrapper(context, themeData, true, builder),
    );
  }

  Widget _buildWithOptionalWrapper(
    BuildContext context,
    ThemeData? themeData,
    bool isModal,
    PickerWidgetBuilder? builder,
  ) {
    final picker = makePicker(themeData, isModal);
    return builder == null ? picker : builder(context, picker);
  }

  Future<List<int>?> showDialog(
    BuildContext context, {
    bool barrierDismissible = true,
    Color? backgroundColor,
    PickerWidgetBuilder? builder,
    Key? key,
  }) {
    final barrierLabel =
        MaterialLocalizations.of(context).modalBarrierDismissLabel;
    return showGeneralDialog<List<int>>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final theme = Theme.of(context);
        final picker = makePicker(theme);
        final dialog = AlertDialog(
          key: key ?? const Key('picker-dialog'),
          title: title,
          backgroundColor: backgroundColor,
          actions: _buildDialogActions(context, theme),
          content: builder == null ? picker : builder(context, picker),
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
              child: dialog,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDialogActions(BuildContext context, ThemeData theme) {
    return <Widget>[
      if (_buildDialogButton(
        context,
        isCancel: true,
        theme: theme,
        onPressed: () {
          Navigator.pop<List<int>>(context, null);
          onCancel?.call();
        },
      )
          case final cancelButton?)
        cancelButton,
      if (_buildDialogButton(
        context,
        isCancel: false,
        theme: theme,
        onPressed: () {
          doConfirm(context);
        },
      )
          case final confirmButton?)
        confirmButton,
    ];
  }

  Widget? _buildDialogButton(
    BuildContext context, {
    required bool isCancel,
    required ThemeData theme,
    required VoidCallback onPressed,
  }) {
    return PickerWidgetState.buildButton(
      context,
      text: isCancel ? cancelText : confirmText,
      widget: isCancel ? cancel : confirm,
      textStyle: isCancel ? cancelTextStyle : confirmTextStyle,
      isCancel: isCancel,
      theme: theme,
      onPressed: onPressed,
    );
  }

  List<dynamic> getSelectedValues() => adapter.getSelectedValues();

  void doCancel(BuildContext context) {
    Navigator.of(context).pop<List<int>>(null);
    onCancel?.call();
    _widget = null;
  }

  Future<void> doConfirm(BuildContext context) async {
    final allowConfirm = await _shouldConfirm();
    if (!allowConfirm) return;

    if (!context.mounted) return;
    Navigator.of(context).pop<List<int>>(List<int>.from(selecteds));
    onConfirm?.call(this, selecteds);
    _widget = null;
  }

  Future<bool> _shouldConfirm() async {
    final before = onConfirmBefore;
    if (before == null) return true;
    return await before(this, selecteds);
  }

  /// 外部修改联动数据后，刷新指定列。
  void updateColumn(int index, [bool all = false]) {
    if (all) {
      _state?.update();
      return;
    }
    if (index < 0 || index >= (_state?._columnSetters.length ?? 0)) return;

    final setter = _state?._columnSetters[index];
    if (setter == null) return;

    adapter.setColumn(index - 1);
    setter(() {});
  }

  static ButtonStyle buttonStyle(BuildContext context,
      {required bool isCancel}) {
    final theme = Theme.of(context);
    final textColor = isCancel ? null : theme.colorScheme.primary;
    return TextButton.styleFrom(
      minimumSize: const Size(0, 42),
      foregroundColor: textColor,
      textStyle: const TextStyle(fontSize: defaultTextSize),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class PickerDelimiter {
  final Widget? child;
  final int column;

  const PickerDelimiter({required this.child, this.column = 1});
}

class PickerItem<T> {
  final Widget? text;
  final T? value;
  final List<PickerItem<T>>? children;

  const PickerItem({this.text, this.value, this.children});
}

class PickerWidget extends InheritedWidget {
  final Picker data;

  const PickerWidget({super.key, required this.data, required super.child});

  @override
  bool updateShouldNotify(covariant PickerWidget oldWidget) {
    return oldWidget.data != data;
  }

  static PickerWidget of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<PickerWidget>();
    assert(widget != null, 'No PickerWidget found in context.');
    return widget!;
  }
}

class PickerContentWidget extends StatefulWidget {
  final Picker picker;
  final ThemeData? themeData;
  final bool isModal;

  const PickerContentWidget({
    super.key,
    required this.picker,
    this.themeData,
    required this.isModal,
  });

  @override
  PickerWidgetState createState() => PickerWidgetState();
}

class PickerWidgetState extends State<PickerContentWidget>
    with DiagnosticableTreeMixin {
  Picker get picker => widget.picker;
  ThemeData get theme => widget.themeData ?? Theme.of(context);

  final List<FixedExtentScrollController> scrollController =
      <FixedExtentScrollController>[];
  final List<StateSetter?> _columnSetters = <StateSetter?>[];
  final Map<int, _WheelState> _wheelStates = <int, _WheelState>{};

  bool _changing = false;
  bool _wait = true;
  bool _delayScheduled = false;
  List<Widget>? _headerItems;

  @override
  void initState() {
    super.initState();
    picker._state = this;
    picker.adapter.doShow();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant PickerContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.picker != widget.picker) {
      oldWidget.picker._state = null;
      picker._state = this;
      _resetControllers();
      _initControllers();
      _headerItems = null;
    }
  }

  @override
  void dispose() {
    if (picker._state == this) picker._state = null;
    for (final controller in scrollController) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initControllers() {
    for (var i = 0; i < picker._maxLevel; i++) {
      final initialItem = i < picker.selecteds.length ? picker.selecteds[i] : 0;
      scrollController
          .add(FixedExtentScrollController(initialItem: initialItem));
      _columnSetters.add(null);
      _wheelStates[i] = _WheelState(initialItem);
    }
  }

  void _resetControllers() {
    for (final controller in scrollController) {
      controller.dispose();
    }
    scrollController.clear();
    _columnSetters.clear();
    _wheelStates.clear();
  }

  void update() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _scheduleSmoothDelayIfNeeded();

    final body = <Widget>[
      if (!picker.hideHeader) _buildHeader(context),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _buildViews(),
      ),
      if (picker.footer != null) picker.footer!,
    ];

    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: body,
    );

    return GestureDetector(onTap: () {}, child: child);
  }

  void _scheduleSmoothDelayIfNeeded() {
    if (!_wait) return;
    if (picker.smooth <= 0) {
      _wait = false;
      return;
    }
    if (_delayScheduled) return;

    _delayScheduled = true;
    Future<void>.delayed(Duration(milliseconds: picker.smooth), () {
      if (!mounted || !_wait) return;
      setState(() => _wait = false);
    });
  }

  Widget _buildHeader(BuildContext context) {
    final customHeader = picker.builderHeader;
    if (customHeader != null) {
      final child = customHeader(context);
      return picker.headerDecoration == null
          ? child
          : DecoratedBox(decoration: picker.headerDecoration!, child: child);
    }

    return DecoratedBox(
      decoration: picker.headerDecoration ??
          BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.dividerColor, width: 0.5),
              bottom: BorderSide(color: theme.dividerColor, width: 0.5),
            ),
            color: picker.headerColor ?? theme.bottomAppBarTheme.color,
          ),
      child: Row(children: _buildHeaderViews(context)),
    );
  }

  List<Widget> _buildHeaderViews(BuildContext context) {
    final cached = _headerItems;
    if (cached != null) return cached;

    final items = <Widget>[];
    final cancel = buildButton(
      context,
      text: picker.cancelText,
      widget: picker.cancel,
      textStyle: picker.cancelTextStyle,
      isCancel: true,
      theme: theme,
      onPressed: () => picker.doCancel(context),
    );
    if (cancel != null) items.add(cancel);

    items.add(
      Expanded(
        child: picker.title == null
            ? const SizedBox()
            : DefaultTextStyle(
                style: (theme.textTheme.titleLarge ?? const TextStyle())
                    .copyWith(fontSize: Picker.defaultTextSize),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                child: picker.title!,
              ),
      ),
    );

    final confirm = buildButton(
      context,
      text: picker.confirmText,
      widget: picker.confirm,
      textStyle: picker.confirmTextStyle,
      isCancel: false,
      theme: theme,
      onPressed: () {
        picker.doConfirm(context);
      },
    );
    if (confirm != null) items.add(confirm);

    _headerItems = items;
    return items;
  }

  static Widget? buildButton(
    BuildContext context, {
    required String? text,
    required Widget? widget,
    required TextStyle? textStyle,
    required bool isCancel,
    required ThemeData theme,
    required VoidCallback? onPressed,
  }) {
    if (widget != null) {
      return textStyle == null
          ? widget
          : DefaultTextStyle(style: textStyle, child: widget);
    }

    final label = text ??
        (isCancel
            ? PickerLocalizations.of(context).cancelText
            : PickerLocalizations.of(context).confirmText);
    if (label.isEmpty) return null;

    return TextButton(
      style: Picker.buttonStyle(context, isCancel: isCancel),
      onPressed: onPressed,
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        textScaler: MediaQuery.textScalerOf(context),
        style: textStyle,
      ),
    );
  }

  List<Widget> _buildViews() {
    _debug('_buildViews');
    for (var i = 0; i < _columnSetters.length; i++) {
      _columnSetters[i] = null;
    }

    final adapter = picker.adapter..setColumn(-1);
    final decoration = BoxDecoration(
      color: picker.containerColor ?? theme.colorScheme.surface,
    );

    final items = <Widget>[];
    if (adapter.length > 0) {
      for (var i = 0; i < picker._maxLevel; i++) {
        items.add(_buildColumn(i, adapter, decoration));
      }
    }

    if (picker.delimiter != null && !_wait) {
      for (final delimiter in picker.delimiter!) {
        final child = delimiter.child;
        if (child == null) continue;

        final item = SizedBox(
          height: picker.height,
          child: DecoratedBox(decoration: decoration, child: child),
        );

        if (delimiter.column < 0) {
          items.insert(0, item);
        } else if (delimiter.column >= items.length) {
          items.add(item);
        } else {
          items.insert(delimiter.column, item);
        }
      }
    }

    return picker.reversedOrder ? items.reversed.toList() : items;
  }

  Widget _buildColumn(
    int column,
    PickerAdapter adapter,
    Decoration decoration,
  ) {
    return Expanded(
      flex: adapter.getColumnFlex(column),
      child: Container(
        padding: picker.columnPadding,
        height: picker.height,
        decoration: decoration,
        child: _wait
            ? null
            : StatefulBuilder(
                builder: (context, setState) {
                  _columnSetters[column] = setState;
                  adapter.setColumn(column - 1);
                  _debug('builder. col: $column');

                  final controller = scrollController[column];
                  final lastIsEmpty = controller.hasClients &&
                      !controller.position.hasContentDimensions;
                  final length = adapter.length;

                  _fixOutOfRangeSelectionIfNeeded(
                    column: column,
                    adapter: adapter,
                    length: length,
                    lastIsEmpty: lastIsEmpty,
                  );

                  return _buildCupertinoPicker(
                    context,
                    column,
                    length,
                    adapter,
                  );
                },
              ),
      ),
    );
  }

  void _fixOutOfRangeSelectionIfNeeded({
    required int column,
    required PickerAdapter adapter,
    required int length,
    required bool lastIsEmpty,
  }) {
    if (length <= 0) return;
    if (!lastIsEmpty &&
        (picker.changeToFirst || picker.selecteds[column] < length)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      adapter.setColumn(column - 1);
      final len = adapter.length;
      if (len <= 0) return;

      final index = picker.selecteds[column].clamp(0, len - 1).toInt();
      picker.selecteds[column] = index;
      _wheelStates[column]?.indexCorrect = index;

      final controller = scrollController[column];
      if (controller.hasClients) {
        controller.jumpToItem(index);
      } else {
        controller.dispose();
        scrollController[column] =
            FixedExtentScrollController(initialItem: index);
      }
      _columnSetters[column]?.call(() {});
    });
  }

  Widget _buildCupertinoPicker(
    BuildContext context,
    int column,
    int length,
    PickerAdapter adapter,
  ) {
    if (length <= 0) return const SizedBox.shrink();

    final wheelState = _wheelStates.putIfAbsent(
      column,
      () => _WheelState(scrollController[column].initialItem),
    );

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) wheelState.isMouseWheel = true;
      },
      child: CupertinoPicker.builder(
        key: ValueKey<int>(column),
        backgroundColor: picker.backgroundColor,
        scrollController: scrollController[column],
        itemExtent: picker.itemExtent,
        magnification: picker.magnification,
        diameterRatio: picker.diameterRatio,
        squeeze: picker.squeeze,
        selectionOverlay: picker.selectionOverlay,
        childCount: picker.looping ? null : length,
        itemBuilder: (context, index) {
          adapter.setColumn(column - 1);
          return adapter.buildItem(context, index % length);
        },
        onSelectedItemChanged: (selectedIndex) {
          _handleSelectedItemChanged(
            column: column,
            selectedIndex: selectedIndex,
            length: length,
            adapter: adapter,
            wheelState: wheelState,
          );
        },
      ),
    );
  }

  void _handleSelectedItemChanged({
    required int column,
    required int selectedIndex,
    required int length,
    required PickerAdapter adapter,
    required _WheelState wheelState,
  }) {
    if (length <= 0) return;

    if (wheelState.isMouseWheel) {
      if (selectedIndex > wheelState.indexCorrect) {
        wheelState.indexCorrect++;
        scrollController[column].jumpToItem(wheelState.indexCorrect);
      } else if (selectedIndex < wheelState.indexCorrect) {
        wheelState.indexCorrect--;
        scrollController[column].jumpToItem(wheelState.indexCorrect);
      }
      wheelState.isMouseWheel = false;
    } else {
      wheelState.indexCorrect = selectedIndex;
    }

    final index = wheelState.indexCorrect % length;
    _debug('onSelectedItemChanged. col: $column, row: $index');

    picker.selecteds[column] = index;
    updateScrollController(column);
    adapter.doSelect(column, index);

    if (picker.changeToFirst) {
      _resetFollowingColumns(column);
    } else {
      _normalizeFollowingColumns(column, adapter);
    }

    picker.onSelect?.call(picker, column, List<int>.from(picker.selecteds));
    _refreshColumnsAfterSelection(column, adapter);
  }

  void _resetFollowingColumns(int column) {
    for (var i = column + 1; i < picker.selecteds.length; i++) {
      picker.selecteds[i] = 0;
      _wheelStates[i]?.indexCorrect = 0;
      if (scrollController[i].hasClients) {
        scrollController[i].jumpToItem(0);
      }
    }
  }

  void _normalizeFollowingColumns(int column, PickerAdapter adapter) {
    if (!adapter.isLinkage) return;

    for (var i = column + 1; i < picker.selecteds.length; i++) {
      adapter.setColumn(i - 1);
      final len = adapter.length;
      if (len <= 0) {
        _moveColumnTo(i, 0);
        continue;
      }

      final selected = picker.selecteds[i];
      if (selected < 0 || selected >= len) {
        _moveColumnTo(i, 0);
      }
    }
  }

  void _moveColumnTo(int column, int index) {
    picker.selecteds[column] = index;
    _wheelStates[column]?.indexCorrect = index;
    final controller = scrollController[column];
    if (controller.hasClients) {
      controller.jumpToItem(index);
    }
  }

  void _refreshColumnsAfterSelection(int column, PickerAdapter adapter) {
    if (adapter.needUpdatePrev(column)) {
      for (var i = 0; i < picker.selecteds.length; i++) {
        if (i == column) continue;
        adapter.setColumn(i - 1);
        _columnSetters[i]?.call(() {});
      }
      return;
    }

    _columnSetters[column]?.call(() {});
    if (!adapter.isLinkage) return;

    for (var i = column + 1; i < picker.selecteds.length; i++) {
      adapter.setColumn(i - 1);
      _columnSetters[i]?.call(() {});
    }
  }

  void updateScrollController(int column) {
    if (_changing || !picker.adapter.isLinkage) return;
    _changing = true;
    for (var i = 0; i < picker.selecteds.length; i++) {
      if (i == column) continue;
      final controller = scrollController[i];
      if (controller.hasClients && controller.position.hasContentDimensions) {
        controller.position.notifyListeners();
      }
    }
    _changing = false;
  }

  void _debug(String message) {
    if (picker.printDebug) debugPrint(message);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(FlagProperty('_changing', value: _changing, ifTrue: 'changing'));
    properties.add(FlagProperty('_wait', value: _wait, ifTrue: 'waiting'));
  }
}

class _WheelState {
  bool isMouseWheel;
  int indexCorrect;

  _WheelState(this.indexCorrect) : isMouseWheel = false;
}

abstract class PickerAdapter {
  Picker? picker;

  int getLength();
  int getMaxLevel();
  void setColumn(int index);
  void initSelects();
  Widget buildItem(BuildContext context, int index);

  /// 当前列变化后，是否需要反向刷新前面的列。
  bool needUpdatePrev(int curIndex) => false;

  Widget makeText(Widget? child, String? text, bool isSel) {
    final picker = this.picker!;
    final context = picker.state?.context;
    final theme =
        picker.textStyle != null || context == null ? null : Theme.of(context);

    final defaultStyle = picker.textStyle ??
        TextStyle(
          color: theme?.brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
          fontFamily: theme?.textTheme.titleLarge?.fontFamily,
          fontSize: Picker.defaultTextSize,
        );

    final content = child != null
        ? _wrapSelectedIconIfNeeded(child, isSel)
        : Text(
            text ?? '',
            textScaler: picker.textScaler,
            style: isSel ? picker.selectedTextStyle : null,
          );

    return Center(
      child: DefaultTextStyle(
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: picker.textAlign,
        style: defaultStyle,
        child: content,
      ),
    );
  }

  Widget makeTextEx(
    Widget? child,
    String text,
    Widget? postfix,
    Widget? suffix,
    bool isSel,
  ) {
    final picker = this.picker!;
    final context = picker.state?.context;
    final theme =
        picker.textStyle != null || context == null ? null : Theme.of(context);

    final selectedStyle = picker.selectedTextStyle;
    final defaultStyle = picker.textStyle ??
        TextStyle(
          color: selectedStyle?.color ??
              (theme?.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87),
          fontSize: selectedStyle?.fontSize ?? Picker.defaultTextSize,
          fontFamily: theme?.textTheme.titleLarge?.fontFamily,
        );

    return Center(
      child: DefaultTextStyle(
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: picker.textAlign,
        style: defaultStyle,
        child: Wrap(
          children: <Widget>[
            if (postfix != null) postfix,
            child ?? Text(text, style: isSel ? selectedStyle : null),
            if (suffix != null) suffix,
          ],
        ),
      ),
    );
  }

  Widget _wrapSelectedIconIfNeeded(Widget child, bool isSel) {
    final iconTheme = picker!.selectedIconTheme;
    if (!isSel || iconTheme == null) return child;
    return IconTheme(data: iconTheme, child: child);
  }

  String getText() => getSelectedValues().toString();

  List<dynamic> getSelectedValues() => <dynamic>[];

  void doShow() {}
  void doSelect(int column, int index) {}

  int getColumnFlex(int column) {
    final flex = picker?.columnFlex;
    if (flex != null && column >= 0 && column < flex.length) {
      return flex[column];
    }
    return 1;
  }

  int get maxLevel => getMaxLevel();

  int get length => getLength();

  String get text => getText();

  bool get isLinkage => getIsLinkage();

  bool getIsLinkage() => true;

  @override
  String toString() => getText();

  /// 数据源变化后同步滚轮位置。
  void notifyDataChanged() {
    final currentPicker = picker;
    final state = currentPicker?.state;
    if (currentPicker == null || state == null) return;

    doShow();
    initSelects();

    for (var i = 0; i < currentPicker.selecteds.length; i++) {
      if (i >= state.scrollController.length) break;
      final controller = state.scrollController[i];
      final target = currentPicker.selecteds[i];
      if (controller.hasClients) {
        controller.jumpToItem(target);
      }
    }
    state.update();
  }
}

class PickerDataAdapter<T> extends PickerAdapter {
  final List<PickerItem<T>> data;
  final bool isArray;

  List<PickerItem<T>>? _datas;
  int _maxLevel = -1;
  int _col = 0;

  PickerDataAdapter({
    List<dynamic>? pickerData,
    List<PickerItem<T>>? data,
    this.isArray = false,
  }) : data = data ?? <PickerItem<T>>[] {
    _parseData(pickerData);
  }

  @override
  bool getIsLinkage() => !isArray;

  void _parseData(List<dynamic>? pickerData) {
    if (pickerData == null || pickerData.isEmpty || data.isNotEmpty) return;
    if (isArray) {
      _parseArrayPickerDataItem(pickerData, data);
    } else {
      _parsePickerDataItem(pickerData, data);
    }
  }

  void _parseArrayPickerDataItem(
    List<dynamic> pickerData,
    List<PickerItem<T>> target,
  ) {
    for (final value in pickerData) {
      if (value is! List) continue;
      if (value.isEmpty) continue;

      final children = <PickerItem<T>>[];
      target.add(PickerItem<T>(children: children));

      for (final item in value) {
        final parsed = _castValue(item);
        if (parsed != null) children.add(PickerItem<T>(value: parsed));
      }
    }
    if (picker?.printDebug == true) debugPrint('data.length: ${data.length}');
  }

  void _parsePickerDataItem(
    List<dynamic> pickerData,
    List<PickerItem<T>> target,
  ) {
    for (final item in pickerData) {
      if (item is Map) {
        for (final entry in item.entries) {
          final key = _castValue(entry.key);
          final value = entry.value;
          if (key == null || value is! List || value.isEmpty) continue;

          final children = <PickerItem<T>>[];
          target.add(PickerItem<T>(value: key, children: children));
          _parsePickerDataItem(List<dynamic>.from(value), children);
        }
        continue;
      }

      if (item is List) continue;
      final parsed = _castValue(item);
      if (parsed != null) target.add(PickerItem<T>(value: parsed));
    }
  }

  T? _castValue(dynamic value) {
    if (value is T) return value;
    if (T == String) return value.toString() as T;
    return null;
  }

  @override
  void setColumn(int index) {
    final targetCol = index + 1;
    if (_datas != null && _col == targetCol) return;
    _col = targetCol;

    if (isArray) {
      _datas = _col >= 0 && _col < data.length ? data[_col].children : null;
      if (picker?.printDebug == true) debugPrint('index: $index');
      return;
    }

    if (index < 0) {
      _datas = data;
      return;
    }

    var current = data;
    for (var i = 0; i <= index; i++) {
      final selectedIndex = picker!.selecteds[i];
      if (selectedIndex < 0 || selectedIndex >= current.length) {
        _datas = null;
        return;
      }
      final children = current[selectedIndex].children;
      if (children == null || children.isEmpty) {
        _datas = null;
        return;
      }
      current = children;
    }
    _datas = current;
  }

  @override
  int getLength() => _datas?.length ?? 0;

  @override
  int getMaxLevel() {
    if (_maxLevel == -1) _checkPickerDataLevel(data, 1);
    return _maxLevel <= 0 ? 1 : _maxLevel;
  }

  @override
  Widget buildItem(BuildContext context, int index) {
    final item = _datas![index];
    final isSelected = _col >= 0 &&
        _col < picker!.selecteds.length &&
        index == picker!.selecteds[_col];

    final customBuilder = picker!.onBuilderItem;
    if (customBuilder != null) {
      final widget = customBuilder(
        context,
        item.value?.toString(),
        item.text,
        isSelected,
        _col,
        index,
      );
      if (widget != null) return makeText(widget, null, isSelected);
    }

    final itemText = item.text;
    if (itemText != null) {
      if (!isSelected || picker!.selectedTextStyle == null) return itemText;
      final child = picker!.selectedIconTheme == null
          ? itemText
          : IconTheme(data: picker!.selectedIconTheme!, child: itemText);
      return DefaultTextStyle(
        style: picker!.selectedTextStyle!,
        textAlign: picker!.textAlign,
        child: child,
      );
    }

    return makeText(null, item.value?.toString(), isSelected);
  }

  @override
  void initSelects() {
    final p = picker!;
    final maxLevel = getMaxLevel();

    while (p.selecteds.length < maxLevel) {
      p.selecteds.add(0);
    }
    if (p.selecteds.length > maxLevel) {
      p.selecteds.removeRange(maxLevel, p.selecteds.length);
    }

    // 保证每一列的选中索引都落在当前数据范围内。
    for (var i = 0; i < maxLevel; i++) {
      setColumn(i - 1);
      final len = length;
      if (len <= 0) {
        p.selecteds[i] = 0;
      } else {
        p.selecteds[i] = p.selecteds[i].clamp(0, len - 1).toInt();
      }
    }
    setColumn(-1);
  }

  @override
  List<dynamic> getSelectedValues() {
    final p = picker!;
    final items = <dynamic>[];

    if (isArray) {
      for (var i = 0; i < p.selecteds.length && i < data.length; i++) {
        final selectedIndex = p.selecteds[i];
        final children = data[i].children;
        if (children == null ||
            selectedIndex < 0 ||
            selectedIndex >= children.length) {
          break;
        }
        items.add(children[selectedIndex].value);
      }
      return items;
    }

    List<PickerItem<T>>? current = data;
    for (final selectedIndex in p.selecteds) {
      if (current == null ||
          current.isEmpty ||
          selectedIndex < 0 ||
          selectedIndex >= current.length) {
        break;
      }
      final item = current[selectedIndex];
      items.add(item.value);
      current = item.children;
    }
    return items;
  }

  void _checkPickerDataLevel(List<PickerItem<T>>? items, int level) {
    if (items == null || items.isEmpty) return;

    if (isArray) {
      _maxLevel = data.length;
      return;
    }

    _maxLevel = _maxLevel < level ? level : _maxLevel;
    for (final item in items) {
      final children = item.children;
      if (children != null && children.isNotEmpty) {
        _checkPickerDataLevel(children, level + 1);
      }
    }
  }
}
