import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final Logger _logger = Logger('HydratedBlocStorage');

class _HydratedBlocStorageConfig {
  /// Default box name used for storage
  static const String boxName = 'hydrated_box';

  /// Default storage directory name
  static const String storageDirectoryName = 'bloc_storage';

  /// Mapping from obfuscated keys to readable keys
  static const Map<String, String> keyMappings = <String, String>{
    'IWa': 'payments_cubit',
    'SWa': 'security_cubit',
    'XWa': 'user_profile_cubit',
    'lVa': 'account_cubit',
    'xVa': 'currency_cubit',
  };

  /// Storage path instance for the application
  static String? _storagePath;

  /// Get the storage path, initializing it if needed
  static Future<String> get storagePath async {
    if (_storagePath == null) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      _storagePath = p.join(appDir.path, storageDirectoryName);
    }
    return _storagePath!;
  }
}

/// Service responsible for initializing HydratedBloc storage with
/// support for migrations.
class HydratedBlocStorage {
  /// Initializes HydratedBloc storage
  Future<void> initialize() async {
    final String storagePath = await _HydratedBlocStorageConfig.storagePath;

    // Initialize Hive for migration
    Hive.init(storagePath);

    await _HydratedBlocMigrator().migrate();

    // Initialize HydratedBloc storage
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(storagePath),
    );

    _logger.config('HydratedBloc storage initialized at: $storagePath');
  }
}

/// Internal class for handling HydratedBloc storage migrations
class _HydratedBlocMigrator {
  /// Migrate data from old keys to new keys
  Future<void> migrate() async {
    final String storagePath = await _HydratedBlocStorageConfig.storagePath;
    final Box<dynamic> box = await Hive.openBox(_HydratedBlocStorageConfig.boxName, path: storagePath);

    try {
      if (await _shouldSkipMigration(box)) {
        return;
      }

      _logger.config('Starting HydratedBloc storage migration...');

      /// Debug storage state before migration begins for comparison
      await _StorageDebugger().debugStorage();

      await _performMigrationAndLogResults(box);
    } catch (e) {
      _logger.warning('Error during migration: $e');
    } finally {
      await box.close();
    }
  }

  /// Check if migration should be skipped
  Future<bool> _shouldSkipMigration(Box<dynamic> box) async {
    final Iterable<dynamic> allKeys = box.keys;

    if (allKeys.isEmpty) {
      _logger.config('No keys found for migration');
      return true;
    }

    return false;
  }

  /// Perform the migration and log the results immediately
  Future<void> _performMigrationAndLogResults(Box<dynamic> box) async {
    int migratedCount = 0;

    for (final dynamic entry in _HydratedBlocStorageConfig.keyMappings.entries) {
      final dynamic oldKey = entry.key;
      final dynamic newKey = entry.value;

      if (await _migrateKeyIfExists(box, oldKey, newKey)) {
        migratedCount++;
      }
    }
    await _logMigrationResults(migratedCount);
  }

  /// Migrate a single key if it exists in the box
  Future<bool> _migrateKeyIfExists(Box<dynamic> box, dynamic oldKey, dynamic newKey) async {
    if (box.containsKey(oldKey)) {
      final dynamic data = box.get(oldKey);
      await box.put(newKey, data);
      await box.delete(oldKey);
      return true;
    }

    return false;
  }

  /// Log migration results and debug storage if needed
  Future<void> _logMigrationResults(int migratedCount) async {
    if (migratedCount > 0) {
      _logger.config('Migration complete: $migratedCount items migrated');
      await _StorageDebugger().debugStorage();
    } else {
      _logger.config('No items were migrated');
    }
  }
}

/// Internal class for debugging storage contents
class _StorageDebugger {
  /// Debug storage contents by listing files and inspecting Hive boxes
  Future<void> debugStorage() async {
    _logger.config('=== STORAGE DEBUG ===');
    await _listFiles();
    await _inspectHiveBoxes();
    _logger.config('====================');
  }

  /// List all files in the storage directory
  Future<void> _listFiles() async {
    try {
      final String storagePath = await _HydratedBlocStorageConfig.storagePath;
      final Directory directory = Directory(storagePath);

      if (!await _checkDirectoryExists(directory)) {
        return;
      }

      final List<FileSystemEntity> entities = await _getAllEntities(directory);
      _logger.config('Found ${entities.length} files/directories in storage');

      await _logEntityDetails(entities);
    } catch (e) {
      _logger.warning('Error listing files: $e');
    }
  }

  /// Check if directory exists and log if not
  Future<bool> _checkDirectoryExists(Directory directory) async {
    final String storagePath = await _HydratedBlocStorageConfig.storagePath;
    if (!await directory.exists()) {
      _logger.config('Storage directory does not exist yet: $storagePath');
      return false;
    }
    return true;
  }

  /// Get all entities in directory recursively
  Future<List<FileSystemEntity>> _getAllEntities(Directory directory) async {
    return await directory.list(recursive: true).toList();
  }

  /// Log details for each entity
  Future<void> _logEntityDetails(List<FileSystemEntity> entities) async {
    final String storagePath = await _HydratedBlocStorageConfig.storagePath;
    for (final FileSystemEntity entity in entities) {
      final String relPath = p.relative(entity.path, from: storagePath);
      final FileSystemEntityType type = await FileSystemEntity.type(entity.path);

      await _logSingleEntity(entity, relPath, type);
    }
  }

  /// Log details for a single entity
  Future<void> _logSingleEntity(
    FileSystemEntity entity,
    String relPath,
    FileSystemEntityType type,
  ) async {
    final String entityType = type == FileSystemEntityType.directory ? 'Directory' : 'File';

    if (type == FileSystemEntityType.file) {
      await _logFileWithSize(entity, relPath, entityType);
    } else {
      _logger.config('$entityType: $relPath');
    }
  }

  /// Log file with its size information
  Future<void> _logFileWithSize(FileSystemEntity entity, String relPath, String entityType) async {
    final File file = File(entity.path);
    final int sizeInBytes = await file.length();
    final String sizeInKB = (sizeInBytes / 1024).toStringAsFixed(2);

    _logger.config('$entityType: $relPath ($sizeInKB KB)');
  }

  /// Inspect Hive boxes
  Future<void> _inspectHiveBoxes() async {
    try {
      final List<FileSystemEntity> hiveFiles = await _findHiveFiles();

      _logger.config('Found ${hiveFiles.length} .hive files');

      for (final FileSystemEntity entity in hiveFiles) {
        await _inspectSingleBox(entity);
      }
    } catch (e) {
      _logger.warning('Error during Hive inspection: $e');
    }
  }

  /// Find all Hive database files in the storage directory
  Future<List<FileSystemEntity>> _findHiveFiles() async {
    final String storagePath = await _HydratedBlocStorageConfig.storagePath;
    final Directory directory = Directory(storagePath);

    if (!await directory.exists()) {
      return <FileSystemEntity>[];
    }

    return await directory.list().where((FileSystemEntity entity) => entity.path.endsWith('.hive')).toList();
  }

  /// Inspect a single Hive box file
  Future<void> _inspectSingleBox(FileSystemEntity entity) async {
    final String boxName = p.basename(entity.path).replaceAll('.hive', '');

    try {
      final Box<dynamic> box = await _openBoxSafely(boxName);

      await _logBoxContents(box, boxName);

      await _closeBoxIfNeeded(box, boxName);
    } catch (e) {
      _logger.warning('Error inspecting box $boxName: $e');
    }
  }

  /// Open a box, handling whether it's already open
  Future<Box<dynamic>> _openBoxSafely(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    } else {
      final String storagePath = await _HydratedBlocStorageConfig.storagePath;
      return await Hive.openBox(boxName, path: storagePath);
    }
  }

  /// Log the contents of a box
  Future<void> _logBoxContents(Box<dynamic> box, String boxName) async {
    _logger.config('Box: $boxName, entries: ${box.length}');

    // Only print key info for brevity
    if (box.keys.isNotEmpty) {
      _logger.config('  Keys: ${box.keys.join(', ')}');
    }
  }

  /// Close the box if we opened it
  Future<void> _closeBoxIfNeeded(Box<dynamic> box, String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      await box.close();
    }
  }
}
