import 'package:app_group_directory/app_group_directory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/services/injector.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

final _log = Logger("Config");

class Config {
  static Config? _instance;

  /// Directory in which all SDK files (DB, log) are stored. Defaults to ".", otherwise if it's customized,
  /// the folder should exist before starting the SDK.
  final String workingDir;
  final Network network;

  Config._({
    required this.workingDir,
    required this.network,
  });

  static Future<Config> instance({
    ServiceInjector? serviceInjector,
  }) async {
    _log.info("Getting Config instance");
    if (_instance == null) {
      _log.info("Creating Config instance");
      _instance = Config._(workingDir: await _workingDir(), network: Network.mainnet);
    }
    return _instance!;
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
