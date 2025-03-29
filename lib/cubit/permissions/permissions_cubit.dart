import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

export 'permissions_state.dart';

/// Logger for PermissionsCubit
final Logger _logger = Logger('PermissionsCubit');

/// Cubit that manages permission states and listens for app lifecycle changes
class PermissionsCubit extends Cubit<PermissionsState> {
  /// Stream subscription for foreground/background events
  StreamSubscription<FGBGType>? fgBgEventsStreamSubscription;

  PermissionsCubit() : super(PermissionsState.initial()) {
    _initializePermissions();
  }

  /// Initialize permissions and set up event listeners
  Future<void> _initializePermissions() async {
    _logger.info('Initializing permissions');
    await checkNotificationPermission();
    _setupForegroundBackgroundListener();
  }

  /// Set up listener for foreground/background events
  void _setupForegroundBackgroundListener() {
    _logger.fine('Setting up foreground/background event listener');
    fgBgEventsStreamSubscription = FGBGEvents.instance.stream.listen(_handleForegroundBackgroundEvent);
  }

  /// Handle foreground/background events
  void _handleForegroundBackgroundEvent(FGBGType event) {
    if (event == FGBGType.foreground) {
      _logger.info('App came to foreground, checking permissions');
      checkNotificationPermission();
    }
  }

  /// Check notification permission
  Future<void> checkNotificationPermission() async {
    try {
      final ph.PermissionStatus status = await ph.Permission.notification.status;
      _logger.info('Raw notification permission status: ${status.name}');

      final PermissionStatus mappedStatus = _mapPermissionStatus(status);

      emit(
        state.copyWith(
          notificationStatus: mappedStatus,
        ),
      );
      _logger.info('Mapped notification permission status: $mappedStatus');
    } catch (error) {
      _logger.severe('Error checking notification permission', error);
    }
  }

  /// Request notification permission
  Future<void> requestNotificationPermission() async {
    try {
      final ph.PermissionStatus status = await ph.Permission.notification.request();
      _logger.info('Raw notification permission request result: ${status.name}');

      final PermissionStatus mappedStatus = _mapPermissionStatus(status);

      emit(
        state.copyWith(
          notificationStatus: mappedStatus,
        ),
      );
      _logger.info('Mapped notification permission request result: $mappedStatus');
    } catch (error) {
      _logger.severe('Error requesting notification permission', error);
    }
  }

  /// Opens app settings to enable permissions
  Future<bool> openAppSettings() async {
    try {
      final bool result = await ph.openAppSettings();
      _logger.info('Opened app settings. Result: $result');
      return result;
    } catch (error) {
      _logger.severe('Error opening app settings', error);
      return false;
    }
  }

  /// Map permission_handler status to our enum
  PermissionStatus _mapPermissionStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
        return PermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return PermissionStatus.denied;
      case ph.PermissionStatus.permanentlyDenied:
      case ph.PermissionStatus.restricted:
      case ph.PermissionStatus.limited:
        return PermissionStatus.permanentlyDenied;
      default:
        return PermissionStatus.unknown;
    }
  }

  @override
  Future<void> close() async {
    _logger.info('Closing PermissionsCubit');
    await fgBgEventsStreamSubscription?.cancel();
    return super.close();
  }
}
