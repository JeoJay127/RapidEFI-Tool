import 'package:flutter/material.dart';

class CustomToast {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, String message) {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry(context, message);
      Overlay.of(context).insert(_overlayEntry!);
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
                child: Card(
                  color: Theme.of(context).colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
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
