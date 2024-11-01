import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
// ignore: uri_does_not_exist
import 'package:l_breez/firebase/firebase_options.dart';
import 'package:l_breez/main/bootstrap_error_page.dart';
import 'package:l_breez/utils/date.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:service_injector/service_injector.dart';
import 'package:shared_preference_app_group/shared_preference_app_group.dart';

final _log = Logger("Bootstrap");

typedef AppBuilder = Widget Function(
  ServiceInjector serviceInjector,
  AccountCubit accountCubit,
  SdkConnectivityCubit sdkConnectivityCubit,
);

Future<void> bootstrap(AppBuilder builder) async {
  // runZonedGuarded wrapper is required to log Dart errors.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
    // iOS Extension requirement
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      SharedPreferenceAppGroup.setAppGroup(
        "group.F7R2LZH3W5.com.breez.liquid.lBreez",
      );
    }

    // Initialize library
    await _initializeLiquidSdk();
    final injector = ServiceInjector();
    final breezLogger = injector.breezLogger;
    breezLogger.registerBreezSdkLiquidLogs(injector.liquidSDK);
    BreezDateUtils.setupLocales();
    if (Firebase.apps.isEmpty) {
      _log.info("List of Firebase apps: ${Firebase.apps}");
      await Firebase.initializeApp(
        // ignore: undefined_identifier
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final appDir = await getApplicationDocumentsDirectory();
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: Directory(p.join(appDir.path, "bloc_storage")),
    );
    final accountCubit = AccountCubit(
      liquidSDK: injector.liquidSDK,
      keyChain: injector.keychain,
    );
    final sdkConnectivityCubit = SdkConnectivityCubit(
      liquidSDK: injector.liquidSDK,
      credentialsManager: injector.credentialsManager,
    );
    final isOnboardingComplete = await accountCubit.restoreIsOnboardingCompleteFlag();
    if (isOnboardingComplete) {
      _log.info("Reconnect if secure storage has mnemonic.");
      String? mnemonic = await injector.credentialsManager.restoreMnemonic();
      if (mnemonic != null) {
        await sdkConnectivityCubit.reconnect(mnemonic: mnemonic);
      }
    }
    runApp(builder(injector, accountCubit, sdkConnectivityCubit));
  }, (error, stackTrace) async {
    if (error is! FlutterErrorDetails) {
      _log.severe("FlutterError: $error", error, stackTrace);
    }
  });
}

Future<void> _initializeLiquidSdk() async {
  try {
    await liquid_sdk.initialize();
  } catch (error, stackTrace) {
    _log.severe("Failed to initialize Liquid SDK: $error", error, stackTrace);
    runApp(BootstrapErrorPage(error: error, stackTrace: stackTrace));
  }
}
