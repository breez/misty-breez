import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:breez_preferences/breez_preferences.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/user_profile.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

export 'user_profile_image_cache.dart';
export 'user_profile_name_cache.dart';
export 'user_profile_state.dart';

final Logger _logger = Logger('UserProfileCubit');

class UserProfileCubit extends Cubit<UserProfileState> with HydratedMixin<UserProfileState> {
  final BreezPreferences _breezPreferences;
  final UserProfileNameCache _profileNameCache = UserProfileNameCache();
  final UserProfileImageCache _profileImageCache = UserProfileImageCache();

  UserProfileCubit(
    this._breezPreferences,
  ) : super(UserProfileState.initial()) {
    hydrate();

    _logger.info('UserProfileState after hydration: ${state.toJson()}');

    _initializeProfile();

    _logger.info('UserProfileState after initialization: ${state.toJson()}');
  }

  void _initializeProfile() async {
    _logger.info('Initializing profile with current state: ${state.toJson()}');

    final bool nameRestored = await _restoreProfileName();
    if (!nameRestored) {
      _logger.info('Profile name is still missing after restoration attempts.');
    }

    final bool colorAnimalRestored = await _restoreProfileColorAndAnimal();
    if (!colorAnimalRestored) {
      _logger.info('Still missing color or animal. Generating defaults.');
      _generateDefaultColorAnimal();
    }

    await _ensureDefaultProfileNameIsSet();

    _logger.info('Profile initialized: ${state.toJson()}');
  }

  Future<bool> _restoreProfileName() async {
    if (state.profileSettings.name != null) {
      return true;
    }
    if (await _tryRestoreProfileNameFromCache()) {
      return true;
    }
    return await _tryRestoreProfileNameFromPreferences();
  }

  Future<bool> _restoreProfileColorAndAnimal() async {
    if (state.profileSettings.color != null && state.profileSettings.animal != null) {
      return true;
    }
    return await _tryRestoreProfileColorsFromPreferences();
  }

  Future<bool> _tryRestoreProfileNameFromCache() async {
    try {
      final String? cachedName = await _profileNameCache.getProfileName(
        fileName: profileNameFileName,
      );
      if (cachedName == null) {
        _logger.info('No cached profile name found.');
        return false;
      }
      _logger.info('Found cached profile name: $cachedName');
      emit(
        state.copyWith(
          profileSettings: state.profileSettings.copyWith(
            name: cachedName,
          ),
        ),
      );
      return true;
    } catch (e) {
      _logger.warning('Error restoring profile name from cache: $e');
      return false;
    }
  }

  Future<bool> _tryRestoreProfileNameFromPreferences() async {
    try {
      final String? name = await _breezPreferences.defaultProfileName;

      if (name == null) {
        // Try to construct name from color and animal if available
        final String? color = await _breezPreferences.defaultProfileColor;
        final String? animal = await _breezPreferences.defaultProfileAnimal;

        if (color != null && animal != null) {
          final String generatedName = DefaultProfile(color, animal).buildName(getSystemLocale());
          emit(
            state.copyWith(
              profileSettings: state.profileSettings.copyWith(
                name: generatedName,
              ),
            ),
          );
          return true;
        }

        return false;
      }

      emit(
        state.copyWith(
          profileSettings: state.profileSettings.copyWith(
            name: name,
          ),
        ),
      );
      return true;
    } catch (e) {
      _logger.warning('Error restoring profile name from preferences: $e');
      return false;
    }
  }

  Future<bool> _tryRestoreProfileColorsFromPreferences() async {
    try {
      final String? color = await _breezPreferences.defaultProfileColor;
      final String? animal = await _breezPreferences.defaultProfileAnimal;

      final UserProfileSettings currentSettings = state.profileSettings;
      UserProfileSettings updatedSettings = currentSettings;
      bool anyFieldRestored = false;

      if (currentSettings.color == null && color != null) {
        updatedSettings = updatedSettings.copyWith(color: color);
        anyFieldRestored = true;
      }

      if (currentSettings.animal == null && animal != null) {
        updatedSettings = updatedSettings.copyWith(animal: animal);
        anyFieldRestored = true;
      }

      // If we still have missing fields and have a name, try to extract missing fields
      if ((currentSettings.color == null || currentSettings.animal == null) && currentSettings.name != null) {
        final Map<String, String>? extracted = _extractColorAndAnimalFromName(currentSettings.name!);
        if (extracted != null) {
          // Apply extracted values only for missing fields
          if (currentSettings.color == null && extracted['color'] != null) {
            updatedSettings = updatedSettings.copyWith(color: extracted['color']);
            anyFieldRestored = true;
          }

          if (currentSettings.animal == null && extracted['animal'] != null) {
            updatedSettings = updatedSettings.copyWith(animal: extracted['animal']);
            anyFieldRestored = true;
          }
        }
      }

      // Apply updates if any field was restored
      if (anyFieldRestored) {
        emit(state.copyWith(profileSettings: updatedSettings));
        return true;
      }

      return false;
    } catch (e) {
      _logger.warning('Error restoring profile colors from preferences: $e');
      return false;
    }
  }

  void _generateDefaultColorAnimal() {
    final DefaultProfile defaultProfile = generateDefaultProfile();
    final UserProfileSettings currentSettings = state.profileSettings;

    final String newColor = currentSettings.color ?? defaultProfile.color;
    final String newAnimal = currentSettings.animal ?? defaultProfile.animal;

    _logger.info('Setting default color/animal - color: $newColor, animal: $newAnimal');
    _storeProfileInPreferences(
      color: newColor,
      animal: newAnimal,
    );

    emit(
      state.copyWith(
        profileSettings: currentSettings.copyWith(
          color: newColor,
          animal: newAnimal,
        ),
      ),
    );
  }

  /// Extracts color and animal from a profile name string
  /// Returns a map with 'color' and 'animal' keys, or null if extraction fails
  Map<String, String>? _extractColorAndAnimalFromName(String name) {
    final List<String> parts = name.split(' ');
    if (parts.length < 2) {
      _logger.info('Could not extract color and animal: Default profile name has fewer than 2 parts');
      return null;
    }

    final bool isColorFirst = isProfileNameInEnglish(name);
    return <String, String>{
      'color': parts[isColorFirst ? 0 : 1],
      'animal': parts[isColorFirst ? 1 : 0],
    };
  }

  Future<void> _storeProfileInPreferences({
    String? name,
    String? color,
    String? animal,
  }) async {
    if (name != null) {
      await _breezPreferences.setDefaultProfileName(name);
    }
    if (color != null) {
      await _breezPreferences.setDefaultProfileColor(color);
    }
    if (animal != null) {
      await _breezPreferences.setDefaultProfileAnimal(animal);
    }
  }

  Future<void> _ensureDefaultProfileNameIsSet() async {
    if (await _breezPreferences.defaultProfileName != null) {
      return;
    }

    final DefaultProfile defaultProfileEn = generateEnglishDefaultProfile(
      state.profileSettings.color!,
      state.profileSettings.animal!,
    );

    /// Default Profile name is used on LN Address Cubit when registering an LN Address for the first time,
    /// It uses English locale by default not to risk l10n introducing special characters.
    final String defaultProfileName = defaultProfileEn.buildName(const Locale('en', ''));
    await _breezPreferences.setDefaultProfileName(defaultProfileName);
    if (state.profileSettings.name == null) {
      emit(
        state.copyWith(
          profileSettings: state.profileSettings.copyWith(
            name: defaultProfileName,
          ),
        ),
      );
      _saveProfileName(defaultProfileName);
    }
  }

  Future<String> saveProfileImage(Uint8List bytes) async {
    try {
      _logger.info('Saving profile image, size: ${bytes.length} bytes');
      final String profileImageFilePath = await _createProfileImageFilePath();
      await File(profileImageFilePath).writeAsBytes(bytes, flush: true);
      await _profileImageCache.cacheProfileImage(bytes);
      return path.basename(profileImageFilePath);
    } catch (e) {
      _logger.warning('Error saving profile image: $e');
      rethrow;
    }
  }

  Future<String> _createProfileImageFilePath() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final Directory profileImagesDir = Directory(path.join(directory.path, profileImagesDirName));
    await profileImagesDir.create(recursive: true);
    final String fileName = 'profile-${DateTime.now().millisecondsSinceEpoch}.png';
    return path.join(profileImagesDir.path, fileName);
  }

  Future<void> _saveProfileName(String profileName) async {
    try {
      _logger.info('Saving profile name: $profileName');
      final String profileNameFilePath = await _createProfileNameFilePath();
      await File(profileNameFilePath).writeAsString(profileName, flush: true);
      await _profileNameCache.cacheProfileName(profileName);
    } catch (e) {
      _logger.warning('Error saving profile name: $e');
      rethrow;
    }
  }

  Future<String> _createProfileNameFilePath() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final Directory profileNameDir = Directory(path.join(directory.path, profileNameDirName));
    await profileNameDir.create(recursive: true);
    return path.join(profileNameDir.path, profileNameFileName);
  }

  void updateProfileSettings({
    String? name,
    String? color,
    String? animal,
    String? image,
    bool? hideBalance,
    AppMode? appMode,
    bool? expandPreferences,
  }) {
    final UserProfileSettings newSettings = state.profileSettings.copyWith(
      name: name,
      color: color,
      animal: animal,
      image: image,
      hideBalance: hideBalance,
      appMode: appMode,
      expandPreferences: expandPreferences,
    );
    emit(state.copyWith(profileSettings: newSettings));
    if (name != null) {
      _saveProfileName(name);
    }
  }

  @override
  UserProfileState? fromJson(Map<String, dynamic> json) {
    try {
      _logger.info('Deserializing state from JSON: $json');
      return UserProfileState.fromJson(json);
    } catch (e) {
      _logger.severe('Error deserializing state: $e');
      return null; // This will trigger the initial state to be used
    }
  }

  @override
  Map<String, dynamic> toJson(UserProfileState state) {
    final Map<String, dynamic> json = state.toJson();
    _logger.info('Serializing state to JSON: $json');
    return json;
  }
}
