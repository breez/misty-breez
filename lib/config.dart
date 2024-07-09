import 'package:app_group_directory/app_group_directory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:l_breez/services/injector.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

final _log = Logger("Config");

class Config {
  static Config? _instance;

  final liquid_sdk.Config sdkConfig;

  Config._({
    required this.sdkConfig,
  });

  static Future<Config> instance({
    ServiceInjector? serviceInjector,
  }) async {
    _log.info("Getting Config instance");
    if (_instance == null) {
      _log.info("Creating Config instance");
      final defaultConf = _getDefaultConf();
      final sdkConfig = await getSDKConfig(defaultConf);

      _instance = Config._(sdkConfig: sdkConfig);
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
    return defaultConf.copyWith(
      workingDir: await _workingDir(),
    );
  }

  static Future<String> _workingDir() async {
    String path = "";
    if (defaultTargetPlatform == TargetPlatform.android) {
      final workingDir = await getApplicationDocumentsDirectory();
      path = workingDir.path;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final sharedDirectory = await AppGroupDirectory.getAppGroupDirectory(
        "group.${const String.fromEnvironment("APP_ID_PREFIX")}.com.breez.liquid.lBreez",
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

extension ConfigCopyWith on liquid_sdk.Config {
  liquid_sdk.Config copyWith({
    String? liquidElectrumUrl,
    String? bitcoinElectrumUrl,
    String? workingDir,
    liquid_sdk.LiquidNetwork? network,
    BigInt? paymentTimeoutSec,
    int? zeroConfMinFeeRateMsat,
  }) {
    return liquid_sdk.Config(
      liquidElectrumUrl: liquidElectrumUrl ?? this.liquidElectrumUrl,
      bitcoinElectrumUrl: bitcoinElectrumUrl ?? this.bitcoinElectrumUrl,
      workingDir: workingDir ?? this.workingDir,
      network: network ?? this.network,
      paymentTimeoutSec: paymentTimeoutSec ?? this.paymentTimeoutSec,
      zeroConfMinFeeRateMsat: zeroConfMinFeeRateMsat ?? this.zeroConfMinFeeRateMsat,
    );
  }
}
