import 'package:flutter/material.dart';

class InkWellShadow extends StatelessWidget {
  final BoxShadow boxShadow;
  final Color? backgroudColor;
  final double radius;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final double? width;
  final double? height;
  final Function()? onTap;
  final Function()? onLongPress;
  const InkWellShadow({
    super.key,
    required this.boxShadow,
    this.backgroudColor = Colors.transparent,
    this.radius = 0.0,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.margin,
    this.alignment,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        width: width,
        padding: padding,
        margin: margin,
        alignment: alignment,
        decoration: BoxDecoration(
          color: backgroudColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [boxShadow],
        ),
        child: child,
      ),
    );
  }
}
