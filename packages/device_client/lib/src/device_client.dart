import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _logger = Logger('DeviceClient');

class DeviceClient {
  final BehaviorSubject<String> _clipboardController = BehaviorSubject<String>();

  DeviceClient() {
    _logger.info('Initializing Device');
  }

  Future<void> setClipboardText(String text) async {
    _logger.info('Setting clipboard text: $text');
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<ShareResult> shareText(String text) {
    _logger.info('Sharing text: $text');
    return Share.share(text);
  }

  void fetchClipboard(SharedPreferences preferences) {
    _logger.info('Fetching clipboard');
    Clipboard.getData('text/plain').then((ClipboardData? clipboardData) {
      final String? text = clipboardData?.text;
      _logger.info('Clipboard text: $text');
      if (text != null) {
        _clipboardController.add(text);
      }
    });
  }

  Future<String> appVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}.${packageInfo.buildNumber}';
  }
}
