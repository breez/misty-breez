import 'dart:async';
import 'dart:io';

import 'package:breez_logger/breez_logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:flutter_svg/svg.dart';
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

final Logger _logger = Logger('Bootstrap');

typedef AppBuilder = Widget Function(
  ServiceInjector serviceInjector,
  SdkConnectivityCubit sdkConnectivityCubit,
);

Future<void> bootstrap(AppBuilder builder) async {
  // runZonedGuarded wrapper is required to log Dart errors.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await _precacheSvgImages();
    SystemChrome.setPreferredOrientations(
      <DeviceOrientation>[DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
    // iOS Extension requirement
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      SharedPreferenceAppGroup.setAppGroup(
        'group.F7R2LZH3W5.com.breez.liquid.lBreez',
      );
    }

    // Initialize library
    await _initializeBreezSdkLiquid();
    final ServiceInjector injector = ServiceInjector();
    final BreezLogger breezLogger = injector.breezLogger;
    breezLogger.registerBreezSdkLiquidLogs(injector.breezSdkLiquid);
    BreezDateUtils.setupLocales();
    if (Firebase.apps.isEmpty) {
      _logger.info('List of Firebase apps: ${Firebase.apps}');
      await Firebase.initializeApp(
        name: 'breez-technology',
        // ignore: undefined_identifier
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final Directory appDir = await getApplicationDocumentsDirectory();
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(p.join(appDir.path, 'bloc_storage')),
    );
    final SdkConnectivityCubit sdkConnectivityCubit = SdkConnectivityCubit(
      breezSdkLiquid: injector.breezSdkLiquid,
      credentialsManager: injector.credentialsManager,
    );
    final bool isOnboardingComplete = await OnboardingPreferences.isOnboardingComplete();
    if (isOnboardingComplete) {
      _logger.info('Reconnect if secure storage has mnemonic.');
      final String? mnemonic = await injector.credentialsManager.restoreMnemonic();
      if (mnemonic != null) {
        await sdkConnectivityCubit.reconnect(mnemonic: mnemonic);
      }
    }
    runApp(builder(injector, sdkConnectivityCubit));
  }, (Object error, StackTrace stackTrace) async {
    if (error is! FlutterErrorDetails) {
      _logger.severe('FlutterError: $error', error, stackTrace);
    }
  });
}

Future<void> _initializeBreezSdkLiquid() async {
  try {
    await liquid_sdk.initialize();
  } catch (error, stackTrace) {
    _logger.severe('Failed to initialize Breez SDK - Liquid: $error', error, stackTrace);
    runApp(BootstrapErrorPage(error: error, stackTrace: stackTrace));
  }
}

Future<void> _precacheSvgImages() async {
  final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final List<String> assets = assetManifest.listAssets();

  final Iterable<String> svgPaths = assets.where((String path) => path.endsWith('.svg'));
  for (final String svgPath in svgPaths) {
    final SvgAssetLoader loader = SvgAssetLoader(svgPath);
    await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
  }
}
