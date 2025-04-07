import 'package:logging/logging.dart';
import 'package:misty_breez/models/models.dart';

final Logger _logger = Logger('UserProfileState');

class UserProfileState {
  final UserProfileSettings profileSettings;

  UserProfileState({required this.profileSettings});

  UserProfileState.initial() : this(profileSettings: UserProfileSettings.initial());

  UserProfileState copyWith({UserProfileSettings? profileSettings}) {
    return UserProfileState(profileSettings: profileSettings ?? this.profileSettings);
  }

  factory UserProfileState.fromJson(Map<String, dynamic> json) {
    try {
      final dynamic profileSettingsJson = json['profileSettings'];
      if (profileSettingsJson == null) {
        return UserProfileState.initial();
      }

      return UserProfileState(
        profileSettings: UserProfileSettings.fromJson(profileSettingsJson as Map<String, dynamic>),
      );
    } catch (e) {
      _logger.warning('Error deserializing UserProfileState: $e');
      return UserProfileState.initial();
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'profileSettings': profileSettings.toJson(),
    };
  }
}
