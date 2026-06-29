import 'package:flutter/material.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis_models.dart';

export 'package:rapidefi/utils/hardware/analysis/hardware_analysis_models.dart';

class HardwareThemeColors {
  const HardwareThemeColors({
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.noteColor,
    required this.buttonColor,
    required this.highlightColor,
    required this.progressTrack,
  });

  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color noteColor;
  final Color buttonColor;
  final Color highlightColor;
  final Color progressTrack;
}

HardwareThemeColors hardwareThemeColors(BuildContext context) {
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  return HardwareThemeColors(
    cardColor: dark ? const Color(0xFF23262B) : Colors.white,
    borderColor: dark ? const Color(0xFF4A4F58) : const Color(0xFFD8D8D8),
    textColor: theme.colorScheme.onSurface,
    noteColor: dark ? const Color(0xFFB8BEC8) : const Color(0xFF7D7D7D),
    buttonColor: theme.colorScheme.surface,
    highlightColor: theme.colorScheme.primary,
    progressTrack: dark ? const Color(0xFF3A3E46) : const Color(0xFFE6EDF5),
  );
}

extension CompatibilityNoteColor on CompatibilityNote {
  Color get color {
    return switch (level) {
      CompatibilityLevel.supported => const Color(0xFF4CAF50),
      CompatibilityLevel.limited => const Color(0xFFFFB627),
      CompatibilityLevel.unsupported => const Color(0xFFD94B4B),
    };
  }
}
