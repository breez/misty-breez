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
export 'user_profile_state.dart';

final Logger _logger = Logger('UserProfileCubit');

class UserProfileCubit extends Cubit<UserProfileState> with HydratedMixin<UserProfileState> {
  final BreezPreferences _breezPreferences;

  UserProfileCubit(
    this._breezPreferences,
  ) : super(UserProfileState.initial()) {
    hydrate();

    _logger.info('UserProfileState after hydration: ${state.toJson()}');

    _initializeProfile();

    _logger.info('UserProfileState after initialization: ${state.toJson()}');
  }

  void _initializeProfile() {
    if (_isProfileIncomplete) {
      _logger.info('Profile is missing fields. Attempting to restore profile from preferences.');
      _tryRestoreProfileFromPreferences().then((bool restored) {
        if (!restored) {
          _logger.info('Failed to restore profile from preferences. Generating a new profile.');
          _generateAndSetDefaultProfile();
        }
        _ensureDefaultProfileNameIsSet();
      });
    } else {
      _ensureDefaultProfileNameIsSet();
    }
  }

  bool get _isProfileIncomplete {
    final UserProfileSettings settings = state.profileSettings;
    _logger
        .info('Profile check - color: ${settings.color}, animal: ${settings.animal}, name: ${settings.name}');
    return settings.color == null || settings.animal == null || settings.name == null;
  }

  Future<bool> _tryRestoreProfileFromPreferences() async {
    try {
      final String? name = await _breezPreferences.defaultProfileName;
      final String? color = await _breezPreferences.defaultProfileColor;
      final String? animal = await _breezPreferences.defaultProfileAnimal;

      _logger.info('Trying to restore from preferences - name: $name, color: $color, animal: $animal');

      if (name != null && color != null && animal != null) {
        emit(
          state.copyWith(
            profileSettings: state.profileSettings.copyWith(
              name: name,
              color: color,
              animal: animal,
            ),
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      _logger.warning('Error restoring profile from preferences: $e');
      return false;
    }
  }

  void _generateAndSetDefaultProfile() {
    final DefaultProfile defaultProfile = generateDefaultProfile();
    final UserProfileSettings currentSettings = state.profileSettings;

    final String newColor = currentSettings.color ?? defaultProfile.color;
    final String newAnimal = currentSettings.animal ?? defaultProfile.animal;
    final String newName = currentSettings.name ?? defaultProfile.buildName(getSystemLocale());

    _logger.info('Setting default profile - color: $newColor, animal: $newAnimal, name: $newName');
    _storeProfileInPreferences(
      name: newName,
      color: newColor,
      animal: newAnimal,
    );

    emit(
      state.copyWith(
        profileSettings: currentSettings.copyWith(
          color: newColor,
          animal: newAnimal,
          name: newName,
        ),
      ),
    );
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
  }

  Future<String> saveProfileImage(Uint8List bytes) async {
    try {
      _logger.info('Saving profile image, size: ${bytes.length} bytes');
      final String profileImageFilePath = await _createProfileImageFilePath();
      await File(profileImageFilePath).writeAsBytes(bytes, flush: true);
      await UserProfileImageCache().cacheProfileImage(bytes);
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

  void updateProfileSettings({
    String? name,
    String? color,
    String? animal,
    String? image,
    bool? hideBalance,
    AppMode? appMode,
    bool? expandPreferences,
  }) {
    emit(
      state.copyWith(
        profileSettings: state.profileSettings.copyWith(
          name: name,
          color: color,
          animal: animal,
          image: image,
          hideBalance: hideBalance,
          appMode: appMode,
          expandPreferences: expandPreferences,
        ),
      ),
    );
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
