import 'dart:async';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _logger = Logger('DeviceClient');

class DeviceClient extends ClipboardListener {
  final BehaviorSubject<String> _clipboardController = BehaviorSubject<String>();
  Stream<String> get clipboardStream =>
      _clipboardController.stream.where((String e) => e != _lastFromAppClip);

  static const String lastClippingPreferencesKey = 'lastClipping';
  static const String lastFromAppClippingPreferencesKey = 'lastFromAppClipping';

  String? _lastFromAppClip;

  DeviceClient() {
    _logger.info('Initializing Device');
    final Future<SharedPreferences> sharedPreferences = SharedPreferences.getInstance();
    sharedPreferences.then((SharedPreferences preferences) {
      _lastFromAppClip = preferences.getString(lastFromAppClippingPreferencesKey);
      _clipboardController.add(preferences.getString(lastClippingPreferencesKey) ?? '');
      _logger.info('Last clipping: $_lastFromAppClip');
      fetchClipboard(preferences);
    });
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
  }

  Future<void> setClipboardText(String text) async {
    _logger.info('Setting clipboard text: $text');
    _lastFromAppClip = text;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(lastFromAppClippingPreferencesKey, text);
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
        preferences.setString(lastClippingPreferencesKey, text);
      }
    });
  }

  Future<String> appVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}.${packageInfo.buildNumber}';
  }

  @override
  void onClipboardChanged() {
    _logger.info('Clipboard changed');
    SharedPreferences.getInstance().then((SharedPreferences preferences) {
      fetchClipboard(preferences);
    });
  }
}
