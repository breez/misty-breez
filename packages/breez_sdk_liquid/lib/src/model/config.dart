import 'package:app_group_directory/app_group_directory.dart';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:service_injector/service_injector.dart';

final _log = Logger("AppConfig");

class AppConfig {
  static AppConfig? _instance;

  final liquid_sdk.Config sdkConfig;

  AppConfig._({required this.sdkConfig});

  static Future<AppConfig> instance({
    ServiceInjector? serviceInjector,
  }) async {
    _log.info("Getting Config instance");
    if (_instance == null) {
      _log.info("Creating Config instance");
      final defaultConf = _getDefaultConf();
      final sdkConfig = await getSDKConfig(defaultConf);

      _instance = AppConfig._(sdkConfig: sdkConfig);
    }
    return _instance!;
  }

  static liquid_sdk.Config _getDefaultConf({
    liquid_sdk.LiquidNetwork network = liquid_sdk.LiquidNetwork.mainnet,
  }) {
    _log.info("Getting default SDK config for network: $network");
    return liquid_sdk.defaultConfig(
      network: network,
    );
  }

  static Future<liquid_sdk.Config> getSDKConfig(
    liquid_sdk.Config defaultConf,
  ) async {
    _log.info("Getting SDK config");
    const breezApiKey = String.fromEnvironment("API_KEY");
    return defaultConf.copyWith(
      workingDir: await _workingDir(),
      breezApiKey: breezApiKey,
    );
  }

  static Future<String> _workingDir() async {
    String path = "";
    if (defaultTargetPlatform == TargetPlatform.android) {
      final workingDir = await getApplicationDocumentsDirectory();
      path = workingDir.path;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final sharedDirectory = await AppGroupDirectory.getAppGroupDirectory(
        "group.F7R2LZH3W5.com.breez.liquid.lBreez",
      );
      if (sharedDirectory == null) {
        throw Exception("Could not get shared directory");
      }
      path = sharedDirectory.path;
    }
    _log.info("Using workingDir: $path");
    return path;
  }
}
