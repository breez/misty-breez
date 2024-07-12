import 'package:l_breez/models/user_profile.dart';

class UserProfileState {
  final UserProfileSettings profileSettings;

  UserProfileState({required this.profileSettings});

  UserProfileState.initial() : this(profileSettings: UserProfileSettings.initial());

  UserProfileState copyWith({UserProfileSettings? profileSettings}) {
    return UserProfileState(profileSettings: profileSettings ?? this.profileSettings);
  }
}
