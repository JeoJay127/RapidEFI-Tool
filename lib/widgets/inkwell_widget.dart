import 'package:flutter/material.dart';
import 'inkwell_shadow.dart';

class InkWellWidget extends StatelessWidget {
  final Color? backgroundColor;
  final double radius;
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final BoxShadow? boxShadow;
  final DecorationImage? decorationImage;
  final Color? foregroundColor;
  final Function()? onTap;
  final Function()? onLongPress;
  final Gradient? gradient;
  final Border? border;
  const InkWellWidget({
    super.key,
    this.backgroundColor,
    this.radius = 0.0,
    this.child,
    this.onTap,
    this.width,
    this.height,
    this.boxShadow,
    this.alignment = Alignment.center,
    this.decorationImage,
    this.padding = EdgeInsets.zero,
    this.foregroundColor,
    this.onLongPress,
    this.margin = EdgeInsets.zero,
    this.gradient,
    this.border,
  });
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        boxShadow != null
            ? InkWellShadow(
                height: height,
                width: width,
                padding: padding,
                margin: margin,
                alignment: alignment,
                radius: radius,
                boxShadow: boxShadow!,
              )
            : const SizedBox.shrink(),
        Material(
          color: backgroundColor ?? Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              height: height,
              width: width,
              padding: padding,
              margin: margin,
              alignment: alignment,
              decoration: BoxDecoration(
                  color:
                      gradient != null ? backgroundColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(radius),
                  image: decorationImage,
                  border: border,
                  gradient: gradient),
              foregroundDecoration: BoxDecoration(
                color: foregroundColor ?? Colors.transparent,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: child,
            ),
          ),
        )
      ],
    );
  }
}
