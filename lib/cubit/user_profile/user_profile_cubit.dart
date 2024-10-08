library user_profile_cubit;

import 'dart:async';
import 'dart:typed_data';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_cache_manager/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/model/models.dart';
import 'package:l_breez/cubit/user_profile/user_profile_cubit.dart';
import 'package:l_breez/models/user_profile.dart';
import 'package:logging/logging.dart';

export 'user_profile_state.dart';

const profileImageCacheKey = "profile_image";

final _log = Logger("UserProfileCubit");

class UserProfileCubit extends Cubit<UserProfileState> with HydratedMixin {
  UserProfileCubit() : super(UserProfileState.initial()) {
    hydrate();
    var profile = state;
    _log.info("State: ${profile.profileSettings.toJson()}");
    final settings = profile.profileSettings;
    if (settings.color == null || settings.animal == null || settings.name == null) {
      _log.info("Profile is missing fields, generating new random ones…");
      final defaultProfile = generateDefaultProfile();
      final color = settings.color ?? defaultProfile.color;
      final animal = settings.animal ?? defaultProfile.animal;
      final name = settings.name ?? DefaultProfile(color, animal).buildName(getSystemLocale());
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

  Future<File> cacheImage(Uint8List bytes) async {
    _log.info("cacheImage ${bytes.length}");
    try {
      return await _saveImage(bytes);
    } catch (error) {
      rethrow;
    }
  }

  void updateProfile({
    String? name,
    String? color,
    String? animal,
    String? image,
    bool? registrationRequested,
    bool? hideBalance,
    AppMode? appMode,
    bool? expandPreferences,
  }) {
    _log.info("updateProfile");
    var profile = state.profileSettings;
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

  Future setAdminPassword(String password) async {
    throw Exception("not implemented");
  }

  @override
  UserProfileState fromJson(Map<String, dynamic> json) {
    return UserProfileState(profileSettings: UserProfileSettings.fromJson(json));
  }

  @override
  Map<String, dynamic> toJson(UserProfileState state) {
    return state.profileSettings.toJson();
  }

  Future<File> _saveImage(Uint8List logoBytes) async {
    try {
      final cache = DefaultCacheManager();
      await cache.removeFile(profileImageCacheKey);
      return await cache.putFile(profileImageCacheKey, logoBytes);
    } catch (e) {
      _log.warning('Error saving image: $e');
      rethrow;
    }
  }
}
