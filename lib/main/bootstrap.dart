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
import 'package:l_breez/firebase/firebase_options.dart';
import 'package:l_breez/utils/date.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:service_injector/service_injector.dart';
import 'package:shared_preference_app_group/shared_preference_app_group.dart';

final _log = Logger("Bootstrap");

typedef AppBuilder = Widget Function(
  ServiceInjector serviceInjector,
  SdkConnectivityCubit sdkConnectivityCubit,
);

Future<void> bootstrap(AppBuilder builder) async {
  // runZonedGuarded wrapper is required to log Dart errors.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
    // Initialize library
    await liquid_sdk.initialize();
    //initializeDateFormatting(Platform.localeName, null);
    BreezDateUtils.setupLocales();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final injector = ServiceInjector();
    var breezLogger = injector.breezLogger;
    breezLogger.registerBreezSdkLiquidLogs(injector.liquidSDK);

    final appDir = await getApplicationDocumentsDirectory();

    // iOS Extension requirement
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      SharedPreferenceAppGroup.setAppGroup(
        "group.${const String.fromEnvironment("APP_ID_PREFIX")}.com.breez.liquid.lBreez",
      );
    }

    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: Directory(p.join(appDir.path, "bloc_storage")),
    );
    var sdkConnectivityCubit = SdkConnectivityCubit(
      liquidSDK: injector.liquidSDK,
      credentialsManager: injector.credentialsManager,
    );
    _log.info("Reconnect if secure storage has mnemonic.");
    String? mnemonic = await injector.credentialsManager.restoreMnemonic();
    if (mnemonic != null) {
      await sdkConnectivityCubit.reconnect();
    }
    runApp(builder(injector, sdkConnectivityCubit));
  }, (error, stackTrace) async {
    if (error is! FlutterErrorDetails) {
      _log.severe("FlutterError: $error", error, stackTrace);
    }
  });
}
