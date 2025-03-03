import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('OverlayManager');

/// Manages overlay entries for displaying loading indicators, dialogs, etc.
class OverlayManager {
  /// The current active overlay entry
  OverlayEntry? _overlayEntry;

  /// Shows a loading overlay on top of the current screen
  ///
  /// If an overlay is already showing, this method does nothing
  /// to prevent multiple overlays from stacking.
  ///
  /// [context] The build context to use for inserting the overlay
  void showLoadingOverlay(BuildContext context) {
    if (_overlayEntry != null) {
      _logger.fine('Loading overlay already showing, ignoring request');
      return;
    }

    _logger.fine('Showing loading overlay');
    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) => Material(
        color: Colors.transparent,
        child: Container(
          color: Colors.black.withAlpha(77), // Using withAlpha as per lint warnings
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      Overlay.of(context).insert(_overlayEntry!);
    } catch (e) {
      _logger.warning('Failed to insert overlay: $e');
      _overlayEntry = null;
    }
  }

  /// Removes the loading overlay if it is currently showing
  void removeLoadingOverlay() {
    if (_overlayEntry == null) {
      _logger.fine('No loading overlay to remove');
      return;
    }

    _logger.fine('Removing loading overlay');
    try {
      _overlayEntry?.remove();
    } catch (e) {
      _logger.warning('Error removing overlay: $e');
    } finally {
      _overlayEntry = null;
    }
  }
}
