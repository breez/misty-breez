library breez.logger;

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

final _log = Logger("BreezLogger");
final _liquidSdkLog = Logger("BreezSdkLiquid");

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

    _createSessionLogFile();

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
  }

  void _createSessionLogFile() async {
    try {
      final config = await AppConfig.instance();
      final appDir = Directory(config.sdkConfig.workingDir);

      _pruneLogs(appDir);

      final logFile = File("${appDir.path}/logs/${DateTime.now().millisecondsSinceEpoch}.app.log");
      logFile.createSync(recursive: true);

      final sync = logFile.openWrite(mode: FileMode.append);
      Logger.root.onRecord.listen(
        (record) => sync.writeln(_recordToString(record)),
        onDone: () async {
          await sync.flush();
          await sync.close();
        },
      );
    } catch (e) {
      _log.severe("Failed to create log file", e);
    }
  }

  void _pruneLogs(Directory appDir) {
    final loggingFolder = Directory("${appDir.path}/logs/");
    if (!loggingFolder.existsSync()) return;

    // Get and sort log files by modified date
    final logFiles = loggingFolder
        .listSync(followLinks: false)
        .whereType<File>()
        .where((file) => file.path.endsWith('.log'))
        .toList()
      ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

    // Delete all except the last 10 log files
    if (logFiles.length > 10) {
      final filesToDelete = logFiles.take(logFiles.length - 10);
      for (var file in filesToDelete) {
        file.deleteSync();
      }
    }
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
}

void shareLog() async {
  var config = await AppConfig.instance();
  final appDir = config.sdkConfig.workingDir;
  final encoder = ZipFileEncoder();
  final zipFilePath = "$appDir/l-breez.logs.zip";
  encoder.create(zipFilePath);
  encoder.addDirectory(Directory("$appDir/logs/"));
  encoder.close();
  final zipFile = XFile(zipFilePath);
  Share.shareXFiles([zipFile]);
}
