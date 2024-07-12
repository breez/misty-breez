import 'dart:async';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger("Device");

class Device extends ClipboardListener {
  final _clipboardController = BehaviorSubject<String>();
  Stream<String> get clipboardStream => _clipboardController.stream.where((e) => e != _lastFromAppClip);

  static const String lastClippingPreferencesKey = "lastClipping";
  static const String lastFromAppClippingPreferencesKey = "lastFromAppClipping";

  String? _lastFromAppClip;

  Device() {
    _log.info("Initializing Device");
    var sharedPreferences = SharedPreferences.getInstance();
    sharedPreferences.then((preferences) {
      _lastFromAppClip = preferences.getString(lastFromAppClippingPreferencesKey);
      _clipboardController.add(preferences.getString(lastClippingPreferencesKey) ?? "");
      _log.info("Last clipping: $_lastFromAppClip");
      fetchClipboard(preferences);
    });
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
  }

  Future setClipboardText(String text) async {
    _log.info("Setting clipboard text: $text");
    _lastFromAppClip = text;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(lastFromAppClippingPreferencesKey, text);
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future shareText(String text) {
    _log.info("Sharing text: $text");
    return Share.share(text);
  }

  void fetchClipboard(SharedPreferences preferences) {
    _log.info("Fetching clipboard");
    Clipboard.getData("text/plain").then((clipboardData) {
      final text = clipboardData?.text;
      _log.info("Clipboard text: $text");
      if (text != null) {
        _clipboardController.add(text);
        preferences.setString(lastClippingPreferencesKey, text);
      }
    });
  }

  Future<String> appVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return "${packageInfo.version}.${packageInfo.buildNumber}";
  }

  @override
  void onClipboardChanged() {
    _log.info("Clipboard changed");
    SharedPreferences.getInstance().then((preferences) {
      fetchClipboard(preferences);
    });
  }
}
