import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

const String profileNameFileName = 'profile_name.txt';
const String profileNameCacheKey = 'profileNameCache';
const String profileNameDirName = 'ProfileName';

final Logger _logger = Logger('UserProfileNameCache');

class UserProfileNameCache {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  static final UserProfileNameCache _instance = UserProfileNameCache._internal();

  factory UserProfileNameCache() => _instance;
  UserProfileNameCache._internal();

  Future<String?> getProfileName({required String fileName}) async {
    final String? cachedName = await _getCachedProfileName();
    if (cachedName != null) {
      return cachedName;
    }
    return await _loadProfileNameFromDocuments(fileName);
  }

  Future<String?> _getCachedProfileName() async {
    final FileInfo? cachedFileInfo = await _cacheManager.getFileFromCache(profileNameCacheKey);
    if (cachedFileInfo != null) {
      try {
        final Uint8List bytes = await cachedFileInfo.file.readAsBytes();
        return utf8.decode(bytes);
      } catch (e) {
        _logger.warning('Error reading cached profile name: $e');
      }
    }
    return null;
  }

  Future<String?> _loadProfileNameFromDocuments(String fileName) async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final Directory profileNameDir = Directory(path.join(directory.path, profileNameDirName));
      final String filePath = path.join(profileNameDir.path, fileName);
      final File file = File(filePath);

      if (await file.exists()) {
        final String content = await file.readAsString();
        await cacheProfileName(content);
        return content;
      }
    } catch (e) {
      _logger.warning('Error loading profile name file: $e');
    }
    return null;
  }

  Future<void> cacheProfileName(String profileName) async {
    try {
      _logger.info('Caching profile name: $profileName');
      await _cacheManager.removeFile(profileNameCacheKey);
      await _cacheManager.putFile(
        profileNameCacheKey,
        utf8.encode(profileName),
        eTag: profileNameCacheKey,
      );
    } catch (e) {
      _logger.warning('Error caching profile name: $e');
      rethrow;
    }
  }
}
