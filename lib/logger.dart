library breez.logger;

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:l_breez/bloc/account/breez_sdk_liquid.dart';
import 'package:l_breez/config.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

final _log = Logger("Logger");
final _liquidSdkLog = Logger("BreezSdkLiquid");

void shareLog() async {
  var config = await Config.instance();
  final appDir = config.sdkConfig.workingDir;
  final encoder = ZipFileEncoder();
  final zipFilePath = "$appDir/l-breez.logs.zip";
  encoder.create(zipFilePath);
  encoder.addDirectory(Directory("$appDir/logs/"));
  encoder.close();
  final zipFile = XFile(zipFilePath);
  Share.shareXFiles([zipFile]);
}

class BreezLogger {
  BreezLogger() {
    Logger.root.level = Level.CONFIG;

    if (kDebugMode) {
      Logger.root.onRecord.listen((record) {
        // Dart analyzer doesn't understand that here we are in debug mode so we have to use kDebugMode again
        if (kDebugMode) {
          print(_recordToString(record));
        }
      });
    }

    Config.instance().then((config) {
      var appDir = Directory(config.sdkConfig.workingDir);
      _pruneLogs(appDir);
      final file = File("${_logDir(appDir)}/${DateTime.now().millisecondsSinceEpoch}.app.log");

      try {
        file.createSync(recursive: true);
      } catch (e) {
        _log.severe("Failed to create log file", e);
        return;
      }
      final sync = file.openWrite(mode: FileMode.append);
      Logger.root.onRecord.listen((record) {
        sync.writeln(_recordToString(record));
      }, onDone: () {
        sync.flush();
        sync.close();
      });

      FlutterError.onError = (FlutterErrorDetails details) async {
        FlutterError.presentError(details);
        final name = details.context?.name ?? "FlutterError";
        final exception = details.exceptionAsString();
        _log.severe("$exception -- $name", details, details.stack);
      };

      DeviceInfoPlugin().deviceInfo.then((deviceInfo) {
        _log.info("Device info:");
        deviceInfo.data.forEach((key, value) => _log.info("$key: $value"));
      }, onError: (error) {
        _log.severe("Failed to get device info", error);
      });
    });
  }

  void registerBreezSdkLiquidLogs(BreezSDKLiquid liquidSdk) {
    liquidSdk.logStream.listen((e) => _logLiquidSdkEntries(e, _liquidSdkLog));
  }

  void _logLiquidSdkEntries(liquid_sdk.LogEntry log, Logger logger) {
    switch (log.level) {
      case "ERROR":
        logger.severe(log.line);
        break;
      case "WARN":
        logger.warning(log.line);
        break;
      case "INFO":
        logger.info(log.line);
        break;
      case "DEBUG":
        logger.config(log.line);
        break;
      case "TRACE":
        logger.finest(log.line);
        break;
    }
  }

  String _recordToString(LogRecord record) =>
      "[${record.loggerName}] {${record.level.name}} (${_formatTime(record.time)}) : ${record.message}"
      "${record.error != null ? "\n${record.error}" : ""}"
      "${record.stackTrace != null ? "\n${record.stackTrace}" : ""}";

  String _formatTime(DateTime time) => time.toUtc().toIso8601String();

  String _logDir(Directory appDir) => "${appDir.path}/logs/";

  void _pruneLogs(Directory appDir) {
    final loggingFolder = Directory(_logDir(appDir));
    if (loggingFolder.existsSync()) {
      // Get and sort log files by modified date
      List<FileSystemEntity> filesToBePruned = loggingFolder
          .listSync(followLinks: false)
          .where((e) => e.path.endsWith('.log'))
          .toList()
        ..sort((l, r) => l.statSync().modified.compareTo(r.statSync().modified));
      // Delete all except last 10 logs
      if (filesToBePruned.length > 10) {
        filesToBePruned.removeRange(
          filesToBePruned.length - 10,
          filesToBePruned.length,
        );
        for (var logFile in filesToBePruned) {
          logFile.delete();
        }
      }
    }
  }
}
