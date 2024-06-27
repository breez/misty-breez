import 'dart:async';

import 'package:l_breez/bloc/account/breez_liquid_sdk.dart';
import 'package:l_breez/logger.dart';
import 'package:l_breez/services/deep_links.dart';
import 'package:l_breez/services/device.dart';
import 'package:l_breez/services/keychain.dart';
import 'package:l_breez/services/lightning_links.dart';
import 'package:l_breez/services/notifications.dart';
import 'package:l_breez/utils/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServiceInjector {
  static final _singleton = ServiceInjector._internal();
  static ServiceInjector? _injector;

  FirebaseNotifications? _notifications;
  DeepLinksService? _deepLinksService;

  // breez sdk
  BreezLiquidSDK? _liquidSDK;
  LightningLinksService? _lightningLinksService;

  Device? _device;
  Future<SharedPreferences>? _sharedPreferences = SharedPreferences.getInstance();
  KeyChain? _keychain;
  Preferences? _preferences;
  BreezLogger? _breezLogger;

  factory ServiceInjector() => _injector ?? _singleton;

  ServiceInjector._internal();

  static void configure(ServiceInjector injector) => _injector = injector;

  Notifications get notifications => _notifications ??= FirebaseNotifications();

  Device get device => _device ??= Device();

  DeepLinksService get deepLinks => _deepLinksService ??= DeepLinksService();

  LightningLinksService get lightningLinks => _lightningLinksService ??= LightningLinksService();

  Future<SharedPreferences> get sharedPreferences => _sharedPreferences ??= SharedPreferences.getInstance();

  KeyChain get keychain => _keychain ??= KeyChain();

  Preferences get preferences => _preferences ??= const Preferences();

  BreezLogger get breezLogger => _breezLogger ??= BreezLogger();

  BreezLiquidSDK get liquidSDK => _liquidSDK ??= BreezLiquidSDK();
}
