import 'package:misty_breez/models/user_profile.dart';

class UserProfileState {
  final UserProfileSettings profileSettings;

  UserProfileState({required this.profileSettings});

  UserProfileState.initial() : this(profileSettings: UserProfileSettings.initial());

  UserProfileState copyWith({UserProfileSettings? profileSettings}) {
    return UserProfileState(profileSettings: profileSettings ?? this.profileSettings);
  }

  factory UserProfileState.fromJson(Map<String, dynamic> json) {
    return UserProfileState(
      profileSettings: UserProfileSettings.fromJson(json['profileSettings'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'profileSettings': profileSettings.toJson(),
    };
  }
}
