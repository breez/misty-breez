import 'dart:convert';
import 'dart:io';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:logging/logging.dart';

final Logger _logger = Logger('BreezLogger');
final Logger _breezSdkLiquidLogger = Logger('BreezSdkLiquid');

class BreezLogger {
  BreezLogger() {
    Logger.root.level = Level.CONFIG;

    if (kDebugMode) {
      Logger.root.onRecord.listen((LogRecord record) {
        _printWrapped(_recordToString(record));
      });
    }

    _createSessionLogFile();

    FlutterError.onError = (FlutterErrorDetails details) async {
      FlutterError.presentError(details);
      final String name = details.context?.name ?? 'FlutterError';
      final String exception = details.exceptionAsString();
      _logger.severe('$exception -- $name', details, details.stack);
    };

    DeviceInfoPlugin().deviceInfo.then(
      (BaseDeviceInfo deviceInfo) {
        _logger.info('Device info:');
        deviceInfo.data.forEach((String key, dynamic value) => _logger.info('$key: $value'));
      },
      onError: (Object? error) {
        _logger.severe('Failed to get device info', error);
      },
    );
  }

  /// Prints long text by splitting it into chunks of 800 characters to avoid
  /// Dart's print buffer limitations in debug console output.
  void _printWrapped(String text) {
    // Latter part of the regex is to avoid splitting words
    final RegExp pattern = RegExp(r'.{1,800}(?=\s|$)|.{1,800}');
    pattern.allMatches(text).forEach((RegExpMatch match) {
      if (kDebugMode) {
        print(match.group(0));
      }
    });
  }

  void _createSessionLogFile() async {
    try {
      final AppConfig config = await AppConfig.instance();
      final Directory appDir = Directory(config.sdkConfig.workingDir);

      _pruneLogs(appDir);

      final File logFile = File('${appDir.path}/logs/${DateTime.now().millisecondsSinceEpoch}.app.log');
      logFile.createSync(recursive: true);

      final IOSink sync = logFile.openWrite(mode: FileMode.append);
      Logger.root.onRecord.listen(
        (LogRecord record) => sync.writeln(_recordToString(record)),
        onDone: () async {
          await sync.flush();
          await sync.close();
        },
      );
    } catch (e) {
      _logger.severe('Failed to create log file', e);
    }
  }

  void _pruneLogs(Directory appDir) {
    final Directory loggingFolder = Directory('${appDir.path}/logs/');
    if (!loggingFolder.existsSync()) {
      return;
    }

    // Get and sort log files by modified date
    final List<File> logFiles =
        loggingFolder
            .listSync(followLinks: false)
            .whereType<File>()
            .where((File file) => file.path.endsWith('.log'))
            .toList()
          ..sort((File a, File b) => a.statSync().modified.compareTo(b.statSync().modified));

    // Delete all except the last 10 log files
    if (logFiles.length > 10) {
      final Iterable<File> filesToDelete = logFiles.take(logFiles.length - 10);
      for (File file in filesToDelete) {
        file.deleteSync();
      }
    }
  }

  void registerBreezSdkLiquidLogs(BreezSDKLiquid breezSdkLiquid) {
    breezSdkLiquid.logStream.listen(
      (liquid_sdk.LogEntry e) => _logBreezSdkLiquidEntries(e, _breezSdkLiquidLogger),
    );
  }

  void registerBreezServiceLogs(Stream<liquid_sdk.LogEntry> serviceLogStream) {
    serviceLogStream.listen((liquid_sdk.LogEntry e) {
      _logBreezSdkLiquidEntries(e, _breezSdkLiquidLogger);
      _writeToExtensionLog(e);
    });
  }

  IOSink? _extensionLogSink;

  void _writeToExtensionLog(liquid_sdk.LogEntry log) {
    if (_extensionLogSink == null) {
      _createExtensionLogFile();
    }
    _extensionLogSink?.writeln('${DateTime.now().toIso8601String()} ${log.level}: ${log.line}');
  }

  void _createExtensionLogFile() async {
    try {
      final AppConfig config = await AppConfig.instance();
      final Directory appDir = Directory(config.sdkConfig.workingDir);
      final File logFile = File(
        '${appDir.path}/logs/${DateTime.now().millisecondsSinceEpoch}.android-extension.log',
      );
      if (!logFile.existsSync()) {
        logFile.createSync(recursive: true);
      }
      _extensionLogSink = logFile.openWrite(mode: FileMode.append);
    } catch (e) {
      _logger.severe('Failed to create extension log file', e);
    }
  }

  void _logBreezSdkLiquidEntries(liquid_sdk.LogEntry log, Logger logger) {
    switch (log.level) {
      case 'ERROR':
        logger.severe(log.line);
        break;
      case 'WARN':
        logger.warning(log.line);
        break;
      case 'INFO':
        logger.info(log.line);
        break;
      case 'DEBUG':
        logger.config(log.line);
        break;
      case 'TRACE':
        logger.finest(log.line);
        break;
    }
  }

  String _recordToString(LogRecord record) {
    final String header = '[${record.loggerName}] {${record.level.name}} (${_formatTime(record.time)})';
    final String message = _formatMessage(record.message);
    final String error = record.error != null ? '\nERROR: ${record.error}' : '';
    final String stack = record.stackTrace != null ? '\nSTACK: ${record.stackTrace}' : '';

    return '$header: $message$error$stack';
  }

  /// Formats log messages by detecting and pretty-printing embedded JSON.
  String _formatMessage(String message) {
    final int jsonStart = _findFirstJsonStart(message);
    if (jsonStart == -1) {
      return message;
    }

    final String prefix = message.substring(0, jsonStart);
    final String jsonPart = message.substring(jsonStart);

    try {
      final dynamic parsed = jsonDecode(jsonPart);
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      return '$prefix\n${encoder.convert(parsed)}';
    } catch (e) {
      return message;
    }
  }

  /// Finds the first occurrence of JSON start characters ('{' or '[') in a string.
  int _findFirstJsonStart(String message) {
    final int brace = message.indexOf('{');
    final int bracket = message.indexOf('[');

    if (brace == -1) {
      return bracket;
    }
    if (bracket == -1) {
      return brace;
    }
    return brace < bracket ? brace : bracket;
  }

  String _formatTime(DateTime time) => time.toUtc().toIso8601String();
}
