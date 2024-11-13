import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

const String profileImageCacheKey = 'profileImageCache';
const String profileImagesDirName = 'ProfileImages';

final _logger = Logger("UserProfileImageCache");

class UserProfileImageCache {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  static final UserProfileImageCache _instance = UserProfileImageCache._internal();

  factory UserProfileImageCache() {
    return _instance;
  }

  UserProfileImageCache._internal();

  Future<File?> getProfileImageFile({required String fileName}) async {
    final cachedFile = await _getCachedProfileImageFile();
    if (cachedFile != null) {
      return cachedFile;
    }

    return await _loadProfileImageFileFromDocuments(fileName);
  }

  Future<File?> _getCachedProfileImageFile() async {
    final cachedFileInfo = await _cacheManager.getFileFromCache(profileImageCacheKey);
    return cachedFileInfo?.file;
  }

  Future<File?> _loadProfileImageFileFromDocuments(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory(path.join(directory.path, profileImagesDirName));
      final profileImageFilePath = path.join(profileImagesDir.path, fileName);
      final profileImageFile = File(profileImageFilePath);

      if (await profileImageFile.exists()) {
        await cacheProfileImage(await profileImageFile.readAsBytes());
        return profileImageFile;
      }
    } catch (e) {
      _logger.warning('Error loading profile image file: $e');
    }

    return null;
  }

  Future<void> cacheProfileImage(Uint8List bytes) async {
    try {
      _logger.info("Caching profile image, size: ${bytes.length} bytes");
      await _cacheManager.removeFile(profileImageCacheKey);
      await _cacheManager.putFile(
        profileImageCacheKey,
        bytes,
        maxAge: const Duration(days: 30),
        eTag: profileImageCacheKey,
      );
    } catch (e) {
      _logger.warning('Error caching profile image: $e');
      rethrow;
    }
  }
}
