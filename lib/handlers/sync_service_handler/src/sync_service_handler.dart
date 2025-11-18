import 'dart:async';

import 'package:another_flushbar/flushbar.dart';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/handlers/handlers.dart';
import 'package:misty_breez/theme/theme.dart';

final Logger _logger = Logger('SyncServiceHandler');

class SyncServiceHandler extends Handler {
  StreamSubscription<SyncStatus>? _subscription;
  Flushbar<dynamic>? _flushbar;

  @override
  void init(HandlerContextProvider<StatefulWidget> contextProvider) {
    super.init(contextProvider);
    _subscription = contextProvider.getBuildContext()!.read<SyncServiceCubit>().stream.distinct().listen(
      _listen,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
    _subscription = null;
    _flushbar = null;
  }

  void _listen(SyncStatus syncStatus) async {
    _logger.info('Received syncStatus $syncStatus');
    if (syncStatus == SyncStatus.failed) {
      showSyncFailedFlushbar();
    } else if (syncStatus == SyncStatus.synced) {
      dismissFlushbarIfNeed();
    }
  }

  void showSyncFailedFlushbar() {
    dismissFlushbarIfNeed();
    final BuildContext? context = contextProvider?.getBuildContext();
    if (context == null) {
      _logger.info('Skipping sync flushbar as context is null');
      return;
    }
    _flushbar = _getSyncFailedFlushbar(context);
    _flushbar?.show(context);
  }

  void dismissFlushbarIfNeed() async {
    final Flushbar<dynamic>? flushbar = _flushbar;
    if (flushbar == null) {
      return;
    }

    if (flushbar.flushbarRoute != null && flushbar.flushbarRoute!.isActive) {
      final BuildContext? context = contextProvider?.getBuildContext();
      if (context == null) {
        _logger.info('Skipping dismissing sync flushbar as context is null');
        return;
      }
      Navigator.of(context).removeRoute(flushbar.flushbarRoute!);
    }
    _flushbar = null;
  }

  Flushbar<dynamic>? _getSyncFailedFlushbar(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Flushbar<dynamic>(
      isDismissible: false,
      flushbarPosition: FlushbarPosition.TOP,
      icon: Icon(Icons.sync_problem, size: 28.0, color: themeData.colorScheme.error),
      messageText: Text(
        // TODO(erdemyerebasmaz): Add message to Breez-Translations
        'Sync service unavailable', // context.texts().sync_failed_flushbar_message,
        style: snackBarStyle,
        textAlign: TextAlign.center,
      ),
      backgroundColor: snackBarBackgroundColor,
    );
  }
}
