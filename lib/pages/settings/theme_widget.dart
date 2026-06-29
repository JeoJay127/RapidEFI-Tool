import 'dart:math';
import 'package:flutter/material.dart';

class ThemeWidget extends StatefulWidget {
  const ThemeWidget({
    super.key,
    required this.primary,
    required this.defaultPrimary,
    required this.defaultCustomPrimary,
    this.onTap,
    this.isDefault = false,
    this.hasExpaner = true,
  });

  ///选中主题色回调
  final Function(MaterialColor)? onTap;

  ///当前选中主题色
  final MaterialColor primary;

  ///自定义默认主题色，指定默认主题色
  final MaterialColor defaultCustomPrimary;

  ///默认主题色
  final MaterialColor defaultPrimary;

  ///是否使用默认主题色
  final bool? isDefault;

  final bool hasExpaner;

  @override
  State<ThemeWidget> createState() => _ThemeWidgetState();
}

class _ThemeWidgetState extends State<ThemeWidget> {
  late MaterialColor selectThemeColor = widget.primary;
  late final MaterialColor defaultPrimary = widget.defaultPrimary;
  late final MaterialColor defaultCustomPrimary = widget.defaultCustomPrimary;
  late bool isDefalut =
      selectThemeColor.toARGB32() == defaultPrimary.toARGB32();
  final _colorsArr = <MaterialColor>[
    Colors.red,
    Colors.pink,
    Colors.deepOrange,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.teal,
    Colors.green,
  ];
  void _changeThemeColor(MaterialColor color, {bool radom = false}) {
    if (radom) {
      int colorIndex = Random().nextInt(_colorsArr.length - 1);
      selectThemeColor = _colorsArr[colorIndex];
    } else {
      selectThemeColor = color;
    }
    setState(() {});
  }

  Widget _radomWidget(BuildContext context) {
    final color = isDefalut ? widget.defaultCustomPrimary : selectThemeColor;
    return Material(
      child: InkWell(
        onTap: () {
          isDefalut = false;
          _changeThemeColor(selectThemeColor, radom: true);
          widget.onTap?.call(selectThemeColor);
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: color)),
          width: 40,
          height: 40,
          child: Text(
            "?",
            style: TextStyle(fontSize: 20, color: color),
          ),
        ),
      ),
    );
  }

  Widget _defaultWidget(BuildContext context) {
    final color = isDefalut ? widget.defaultCustomPrimary : selectThemeColor;
    return Material(
      child: InkWell(
        onTap: () {
          isDefalut = true;
          _changeThemeColor(defaultCustomPrimary);
          widget.onTap?.call(defaultPrimary);
        },
        child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: color)),
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                const SizedBox(
                  width: 40,
                  height: 40,
                ),
                Text(
                  "默认",
                  style: TextStyle(fontSize: 11, color: color),
                ),
                isDefalut
                    ? Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          color: Colors.grey[700],
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const SizedBox.shrink()
              ],
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var colorWidets = Wrap(
      spacing: 5,
      runSpacing: 5,
      children: <Widget>[
        ..._colorsArr.map((color) {
          return Material(
            color: color,
            child: InkWell(
              onTap: () {
                isDefalut = false;
                _changeThemeColor(color);
                widget.onTap?.call(color);
              },
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  const SizedBox(
                    width: 40,
                    height: 40,
                  ),
                  selectThemeColor.toARGB32() == color.toARGB32() && !isDefalut
                      ? Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            color: Colors.grey[600],
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          );
        }),
        _radomWidget(context),
        _defaultWidget(context)
      ],
    );
    if (!widget.hasExpaner) {
      return colorWidets;
    }
    return ExpansionTile(
      title: const Text('色彩主题'),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: colorWidets,
        ),
      ],
    );
  }
}
