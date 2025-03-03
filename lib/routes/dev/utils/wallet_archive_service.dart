import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:credentials_manager/credentials_manager.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:service_injector/service_injector.dart';

final Logger _logger = Logger('WalletArchiveService');

class WalletArchiveService {
  WalletArchiveService._();

  /// Creates an archive containing application logs
  static Future<String> createLogsArchive(String workingDir) async {
    try {
      final String zipFilePath = '$workingDir/l-breez.logs.zip';
      final ZipFileEncoder encoder = ZipFileEncoder();

      _logger.info('Creating logs archive at: $zipFilePath');
      encoder.create(zipFilePath);

      final Directory logsDir = Directory('$workingDir/logs/');
      if (await logsDir.exists()) {
        await encoder.addDirectory(logsDir);
        await encoder.close();
        return zipFilePath;
      } else {
        _logger.warning('Logs directory not found: ${logsDir.path}');
        throw Exception('Logs directory not found');
      }
    } catch (e) {
      _logger.severe('Failed to create logs archive: $e');
      rethrow;
    }
  }

  /// Creates an archive containing wallet keys and storage DB
  static Future<String> createKeysArchive({
    required String workingDir,
    required String networkName,
    required String fingerprint,
  }) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String zipFilePath = '${appDir.path}/l-breez.keys.zip';
    final ZipFileEncoder encoder = ZipFileEncoder();
    encoder.create(zipFilePath);

    await _addCredentialsToZip(encoder);
    await _addStorageFileToZip(encoder, workingDir, networkName, fingerprint);

    encoder.close();
    return zipFilePath;
  }

  static Future<void> _addCredentialsToZip(ZipFileEncoder encoder) async {
    final CredentialsManager credentialsManager = ServiceInjector().credentialsManager;
    final List<File> credentialFiles = await credentialsManager.exportCredentials();

    _logger.info('Adding ${credentialFiles.length} credential files to zip');
    for (File file in credentialFiles) {
      try {
        final Uint8List bytes = await file.readAsBytes();
        encoder.addArchiveFile(ArchiveFile(basename(file.path), bytes.length, bytes));
      } catch (e) {
        _logger.warning('Failed to add ${file.path}: $e');
      }
    }
  }

  static Future<void> _addStorageFileToZip(
    ZipFileEncoder encoder,
    String workingDir,
    String networkName,
    String fingerprint,
  ) async {
    final String walletStoragePath = '$workingDir/$networkName/$fingerprint';
    final String storageFilePath = '$walletStoragePath/storage.sql';
    _logger.info('Adding storage file: $storageFilePath');

    final File storageFile = File(storageFilePath);
    if (await storageFile.exists()) {
      await encoder.addFile(storageFile);
    } else {
      _logger.warning('Storage file not found: $storageFilePath');
    }
  }
}
