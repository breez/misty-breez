import 'dart:async';
import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/user_profile.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

export 'user_profile_image_cache.dart';
export 'user_profile_state.dart';

final Logger _logger = Logger('UserProfileCubit');

class UserProfileCubit extends Cubit<UserProfileState> with HydratedMixin<UserProfileState> {
  UserProfileCubit() : super(UserProfileState.initial()) {
    hydrate();
    UserProfileState profile = state;
    _logger.info('State: ${profile.profileSettings.toJson()}');
    final UserProfileSettings settings = profile.profileSettings;
    if (settings.color == null || settings.animal == null || settings.name == null) {
      _logger.info('Profile is missing fields, generating new random ones…');
      final DefaultProfile defaultProfile = generateDefaultProfile();
      final String color = settings.color ?? defaultProfile.color;
      final String animal = settings.animal ?? defaultProfile.animal;
      final String name = settings.name ?? DefaultProfile(color, animal).buildName(getSystemLocale());
      profile = profile.copyWith(
        profileSettings: settings.copyWith(
          color: color,
          animal: animal,
          name: name,
        ),
      );
    }
    emit(profile);
  }

  Future<String> saveProfileImage(Uint8List bytes) async {
    try {
      _logger.info('Saving profile image, size: ${bytes.length} bytes');
      final String profileImageFilePath = await _createProfileImageFilePath();
      await io.File(profileImageFilePath).writeAsBytes(bytes, flush: true);
      await UserProfileImageCache().cacheProfileImage(bytes);
      return path.basename(profileImageFilePath);
    } catch (e) {
      _logger.warning('Error saving profile image: $e');
      rethrow;
    }
  }

  Future<String> _createProfileImageFilePath() async {
    final io.Directory directory = await getApplicationDocumentsDirectory();
    final io.Directory profileImagesDir = Directory(path.join(directory.path, profileImagesDirName));
    await profileImagesDir.create(recursive: true);
    final String fileName = 'profile-${DateTime.now().millisecondsSinceEpoch}.png';
    return path.join(profileImagesDir.path, fileName);
  }

  void updateProfile({
    String? name,
    String? color,
    String? animal,
    String? image,
    bool? hideBalance,
    AppMode? appMode,
    bool? expandPreferences,
  }) {
    _logger.info('updateProfile');
    UserProfileSettings profile = state.profileSettings;
    profile = profile.copyWith(
      name: name ?? profile.name,
      color: color ?? profile.color,
      animal: animal ?? profile.animal,
      image: image ?? profile.image,
      hideBalance: hideBalance ?? profile.hideBalance,
      appMode: appMode ?? profile.appMode,
      expandPreferences: expandPreferences ?? profile.expandPreferences,
    );
    emit(state.copyWith(profileSettings: profile));
  }

  @override
  UserProfileState fromJson(Map<String, dynamic> json) {
    return UserProfileState(profileSettings: UserProfileSettings.fromJson(json));
  }

  @override
  Map<String, dynamic> toJson(UserProfileState state) {
    return state.profileSettings.toJson();
  }
}
