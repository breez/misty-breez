import 'package:flutter/material.dart';

class OverlayManager {
  OverlayEntry? _overlayEntry;

  void showLoadingOverlay(BuildContext context) {
    if (_overlayEntry != null) {
      return;
    }
    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) => Material(
        color: Colors.transparent,
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void removeLoadingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
