import 'dart:io';

import 'package:app_group_directory/app_group_directory.dart';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:service_injector/service_injector.dart';

final Logger _logger = Logger('AppConfig');

class AppConfig {
  static AppConfig? _instance;

  final liquid_sdk.Config sdkConfig;

  AppConfig._({required this.sdkConfig});

  static Future<AppConfig> instance({ServiceInjector? serviceInjector}) async {
    _logger.info('Getting Config instance');
    if (_instance == null) {
      _logger.info('Creating Config instance');
      final liquid_sdk.Config defaultConf = _getDefaultConf();
      final liquid_sdk.Config sdkConfig = await getSDKConfig(defaultConf);

      _instance = AppConfig._(sdkConfig: sdkConfig);
    }
    return _instance!;
  }

  static liquid_sdk.Config _getDefaultConf({
    liquid_sdk.LiquidNetwork network = liquid_sdk.LiquidNetwork.mainnet,
  }) {
    _logger.info('Getting default SDK config for network: $network');
    const String breezApiKey = String.fromEnvironment('API_KEY');
    if (breezApiKey.isEmpty) {
      throw Exception('API_KEY is not set in environment variables');
    }
    return liquid_sdk.defaultConfig(network: network, breezApiKey: breezApiKey);
  }

  static Future<liquid_sdk.Config> getSDKConfig(liquid_sdk.Config defaultConf) async {
    _logger.info('Getting SDK config');
    return defaultConf.copyWith(workingDir: await _workingDir());
  }

  static Future<String> _workingDir() async {
    String path = '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      final Directory workingDir = await getApplicationDocumentsDirectory();
      path = workingDir.path;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final Directory? sharedDirectory = await AppGroupDirectory().getAppGroupDirectory(
        'group.F7R2LZH3W5.com.breez.misty',
      );
      if (sharedDirectory == null) {
        throw Exception('Could not get shared directory');
      }
      path = sharedDirectory.path;
    }
    _logger.info('Using workingDir: $path');
    return path;
  }
}
