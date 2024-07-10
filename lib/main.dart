// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/bloc/account/account_bloc.dart';
import 'package:l_breez/bloc/account/credentials_manager.dart';
import 'package:l_breez/bloc/backup/backup_bloc.dart';
import 'package:l_breez/bloc/currency/currency_bloc.dart';
import 'package:l_breez/bloc/input/input_bloc.dart';
import 'package:l_breez/bloc/security/security_bloc.dart';
import 'package:l_breez/bloc/user_profile/user_profile_bloc.dart';
import 'package:l_breez/services/injector.dart';
import 'package:l_breez/user_app.dart';
import 'package:l_breez/utils/date.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preference_app_group/shared_preference_app_group.dart';

final _log = Logger("Main");

void main() async {
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
    //await Firebase.initializeApp();
    final injector = ServiceInjector();
    var breezLogger = injector.breezLogger;

    // Initialize Log Stream
    if (injector.liquidSDK.instance == null) {
      injector.liquidSDK.initializeLogStream();
      breezLogger.registerBreezSdkLiquidLogs(injector.liquidSDK);
    }

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
    runApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<AccountBloc>(
            create: (BuildContext context) => AccountBloc(
              injector.liquidSDK,
              CredentialsManager(keyChain: injector.keychain),
            ),
          ),
          BlocProvider<InputBloc>(
            create: (BuildContext context) => InputBloc(
              injector.lightningLinks,
              injector.device,
            ),
          ),
          BlocProvider<UserProfileBloc>(
            create: (BuildContext context) => UserProfileBloc(),
          ),
          BlocProvider<CurrencyBloc>(
            create: (BuildContext context) => CurrencyBloc(injector.liquidSDK),
          ),
          BlocProvider<SecurityBloc>(
            create: (BuildContext context) => SecurityBloc(),
          ),
          BlocProvider<BackupBloc>(
            create: (BuildContext context) => BackupBloc(injector.liquidSDK),
          ),
        ],
        child: UserApp(),
      ),
    );
  }, (error, stackTrace) async {
    if (error is! FlutterErrorDetails) {
      _log.severe("FlutterError: $error", error, stackTrace);
    }
  });
}
