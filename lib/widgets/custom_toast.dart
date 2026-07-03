import 'package:flutter/material.dart';

class CustomToast {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, String message) {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry(context, message);
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    }
  }

  static void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  static OverlayEntry _createOverlayEntry(
      BuildContext context, String message) {
    return OverlayEntry(
      builder: (BuildContext overlayContext) {
        final colorScheme = Theme.of(overlayContext).colorScheme;
        return Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Material(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
