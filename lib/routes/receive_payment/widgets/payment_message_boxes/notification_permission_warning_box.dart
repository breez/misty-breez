import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/widgets/widgets.dart';

final Logger _logger = Logger('NotificationPermissionWarningBox');

/// Warning box for notification permission status
class NotificationPermissionWarningBox extends StatelessWidget {
  const NotificationPermissionWarningBox({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final PermissionsCubit permissionsCubit = context.read<PermissionsCubit>();

    return BlocBuilder<PermissionsCubit, PermissionsState>(
      builder: (BuildContext context, PermissionsState state) {
        // Skip loading this widget until we've actually checked permissions
        if (state.notificationStatus == PermissionStatus.unknown) {
          _logger.info('Permission status is unknown, triggering check');
          // Trigger permission check and avoid showing anything until we have a result
          Future<void>.microtask(() => permissionsCubit.checkNotificationPermission());
          return const SizedBox.shrink();
        }

        if (state.hasNotificationPermission) {
          return const SizedBox.shrink();
        }

        _logger.info('No notification permission, showing warning box');
        // TODO(erdemyerebasmaz): Add message to Breez-Translations
        final String warningMessage =
            'Your Lightning address is disabled because '
            'notifications are not allowed in this app';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _requestPermission(context),
            child: WarningBox(
              boxPadding: EdgeInsets.zero,
              backgroundColor: themeData.colorScheme.error.withValues(alpha: .1),
              contentPadding: const EdgeInsets.all(16.0),
              child: RichText(
                text: TextSpan(
                  text: warningMessage,
                  style: themeData.textTheme.titleLarge?.copyWith(color: themeData.colorScheme.error),
                  children: <InlineSpan>[
                    TextSpan(
                      // TODO(erdemyerebasmaz): Add message to Breez-Translations
                      text: '\n\nTap here',
                      style: themeData.textTheme.titleLarge?.copyWith(
                        color: themeData.colorScheme.error.withValues(alpha: .7),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(
                      text:
                          ' to enable them'
                          '${state.hasNotificationPermissionPermanentlyDenied ? ' in settings.' : '.'}',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  void _requestPermission(BuildContext context) {
    final PermissionsCubit permissionsCubit = context.read<PermissionsCubit>();
    if (permissionsCubit.state.hasNotificationPermissionPermanentlyDenied) {
      permissionsCubit.openAppSettings();
    } else {
      permissionsCubit.requestNotificationPermission();
    }
  }
}
