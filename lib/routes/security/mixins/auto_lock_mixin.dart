import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart' as cubit;
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('AutoLockMixin');

/// A mixin that automatically shows the lock screen when the app is locked.
///
/// This mixin should be used on StatefulWidget states that need to enforce
/// authentication when the app is locked.
mixin AutoLockMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    _setupLockListener();
  }

  /// Sets up a listener for lock state changes
  void _setupLockListener() {
    final cubit.SecurityCubit securityCubit = context.read<cubit.SecurityCubit>();

    securityCubit.stream
        .distinct()
        .where((cubit.SecurityState state) => state.lockState == cubit.LockState.locked)
        .listen(_handleLockStateChange);

    _logger.fine('Auto lock listener set up');
  }

  /// Handles lock state changes
  void _handleLockStateChange(cubit.SecurityState state) {
    if (!mounted) {
      return;
    }

    _logger.info('Lock state changed to locked, showing lock screen');

    Navigator.of(context, rootNavigator: true).push(
      FadeInRoute<void>(
        builder: (_) => const LockScreen(
          authorizedAction: AuthorizedAction.popPage,
        ),
      ),
    );
  }
}
