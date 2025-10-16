import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('SyncServiceCubit');

class SyncServiceCubit extends Cubit<SyncStatus> {
  final BreezSDKLiquid _sdk;
  StreamSubscription<SyncStatus>? _subscription;

  SyncServiceCubit(this._sdk) : super(SyncStatus.initial) {
    _initializeSyncServiceCubit();
  }

  void _initializeSyncServiceCubit() {
    _subscription = _sdk.syncStatusStream.listen((SyncStatus status) {
      emit(status);
      _logger.info('SyncStatus changed to: $status');
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
