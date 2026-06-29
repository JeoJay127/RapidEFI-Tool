import 'package:flutter/material.dart';

extension MaterialColorExtension on Color {
  MaterialColor toMaterialColor() {
    Map<int, Color> colorMap = {
      50: withValues(alpha: 0.1),
      100: withValues(alpha: 0.2),
      200: withValues(alpha: 0.3),
      300: withValues(alpha: 0.4),
      400: withValues(alpha: 0.5),
      500: withValues(alpha: 0.6),
      600: withValues(alpha: 0.7),
      700: withValues(alpha: 0.8),
      800: withValues(alpha: 0.9),
      900: withValues(alpha: 1.0),
    };
    return MaterialColor(toARGB32(), colorMap);
  }
}
