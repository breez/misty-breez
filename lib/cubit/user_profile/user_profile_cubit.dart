import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:breez_preferences/breez_preferences.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
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

    _initializeProfile();
  }
  void _initializeProfile() {
    if (_isProfileIncomplete) {
      _logger.info('Profile is missing fields, generating new random ones…');
      _generateAndSetDefaultProfile();
    }

    _ensureDefaultProfileNameIsSet();
  }

  bool get _isProfileIncomplete {
    final UserProfileSettings settings = state.profileSettings;
    return settings.color == null || settings.animal == null || settings.name == null;
  }

  void _generateAndSetDefaultProfile() {
    final DefaultProfile defaultProfile = generateDefaultProfile();
    final UserProfileSettings currentSettings = state.profileSettings;

    emit(
      state.copyWith(
        profileSettings: currentSettings.copyWith(
          color: currentSettings.color ?? defaultProfile.color,
          animal: currentSettings.animal ?? defaultProfile.animal,
          name: currentSettings.name ?? defaultProfile.buildName(getSystemLocale()),
        ),
      ),
    );
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
  UserProfileState? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      _logger.severe('No stored data found.');
      return null;
    }

    try {
      final UserProfileState result = UserProfileState.fromJson(json);
      _logger.fine('Successfully hydrated with $result');
      return result;
    } catch (e, stackTrace) {
      _logger.severe('Error hydrating: $e');
      _logger.fine('Stack trace: $stackTrace');
      return UserProfileState.initial();
    }
  }

  @override
  Map<String, dynamic>? toJson(UserProfileState state) {
    try {
      final Map<String, dynamic> result = state.toJson();
      _logger.fine('Serialized: $result');
      return result;
    } catch (e) {
      _logger.severe('Error serializing: $e');
      return null;
    }
  }

  @override
  String get storagePrefix => 'user_profile_cubit';
}
