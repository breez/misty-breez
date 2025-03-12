import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

/// Logger for the DeviceClient class.
final Logger _logger = Logger('DeviceClient');

/// A client that provides device-specific functionality.
///
/// Handles clipboard operations, sharing capabilities, and device information.
class DeviceClient {
  /// Controller for listening to clipboard changes.
  final BehaviorSubject<String> _clipboardController = BehaviorSubject<String>();

  /// Stream of clipboard text updates.
  Stream<String> get clipboardStream => _clipboardController.stream;

  /// Creates a new DeviceClient instance.
  DeviceClient() {
    _logger.info('Initializing DeviceClient');
  }

  /// Sets the provided [text] to the device clipboard.
  ///
  /// Returns a [Future] that completes when the operation is done.
  Future<void> setClipboardText(String text) async {
    _logger.info('Setting clipboard text: $text');
    try {
      await Clipboard.setData(ClipboardData(text: text));
      _logger.fine('Successfully set clipboard text');
    } catch (e) {
      _logger.severe('Failed to set clipboard text', e);
      rethrow;
    }
  }

  /// Retrieves text from the device clipboard.
  ///
  /// Returns the clipboard text as a [String] or null if the clipboard is empty.
  Future<String?> fetchClipboardData() async {
    _logger.info('Fetching clipboard data');
    try {
      final ClipboardData? clipboardData = await Clipboard.getData('text/plain');
      final String? text = clipboardData?.text;
      if (text != null) {
        _clipboardController.add(text);
        _logger.fine('Updated clipboard stream with text');
      }
      _logger.fine('Retrieved clipboard text: $text');
      return text;
    } catch (e) {
      _logger.severe('Failed to fetch clipboard data', e);
      return null;
    }
  }

  /// Disposes of resources used by this client.
  void dispose() {
    _logger.info('Disposing DeviceClient');
    _clipboardController.close();
  }
}
