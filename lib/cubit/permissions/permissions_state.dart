/// Enum representing permission status states
enum PermissionStatus {
  /// Permission is granted
  granted,

  /// Permission is denied
  denied,

  /// Permission is permanently denied and can only be granted from app settings
  permanentlyDenied,

  /// Permission status is unknown (initial state)
  unknown,
}

/// Class that represents the state of the permissions
class PermissionsState {
  /// Notification permission status
  final PermissionStatus notificationStatus;

  const PermissionsState({required this.notificationStatus});

  /// Default state constructor
  factory PermissionsState.initial() => const PermissionsState(notificationStatus: PermissionStatus.unknown);

  /// Creates a copy of this state with the given values
  PermissionsState copyWith({PermissionStatus? notificationStatus}) {
    return PermissionsState(notificationStatus: notificationStatus ?? this.notificationStatus);
  }

  /// Whether notification permissions are granted
  bool get hasNotificationPermission => notificationStatus == PermissionStatus.granted;

  /// Whether notification permissions are permanently denied
  bool get hasNotificationPermissionPermanentlyDenied =>
      notificationStatus == PermissionStatus.permanentlyDenied ||
      notificationStatus == PermissionStatus.denied;
}
