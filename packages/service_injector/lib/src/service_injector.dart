import 'dart:async';

import 'package:breez_logger/breez_logger.dart';
import 'package:breez_preferences/breez_preferences.dart';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:deep_link_client/deep_link_client.dart';
import 'package:device_client/device_client.dart';
import 'package:firebase_notifications_client/firebase_notifications_client.dart';
import 'package:keychain/keychain.dart';
import 'package:lightning_links/lightning_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServiceInjector {
  static final _singleton = ServiceInjector._internal();
  static ServiceInjector? _injector;

  FirebaseNotificationsClient? _notifications;
  DeepLinkClient? _deepLinkClient;

  // breez sdk
  BreezSDKLiquid? _liquidSDK;
  LightningLinksService? _lightningLinksService;

  DeviceClient? _deviceClient;
  Future<SharedPreferences>? _sharedPreferences = SharedPreferences.getInstance();
  KeyChain? _keychain;
  BreezPreferences? _breezPreferences;
  BreezLogger? _breezLogger;

  factory ServiceInjector() => _injector ?? _singleton;

  ServiceInjector._internal();

  static void configure(ServiceInjector injector) => _injector = injector;

  NotificationsClient get notifications => _notifications ??= FirebaseNotificationsClient();

  DeviceClient get deviceClient => _deviceClient ??= DeviceClient();

  DeepLinkClient get deepLinkClient => _deepLinkClient ??= DeepLinkClient();

  LightningLinksService get lightningLinks => _lightningLinksService ??= LightningLinksService();

  Future<SharedPreferences> get sharedPreferences => _sharedPreferences ??= SharedPreferences.getInstance();

  KeyChain get keychain => _keychain ??= KeyChain();

  BreezPreferences get breezPreferences => _breezPreferences ??= const BreezPreferences();

  BreezLogger get breezLogger => _breezLogger ??= BreezLogger();

  BreezSDKLiquid get liquidSDK => _liquidSDK ??= BreezSDKLiquid();
}
