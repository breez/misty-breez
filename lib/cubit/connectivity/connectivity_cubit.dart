import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

export 'connectivity_state.dart';

final Logger _logger = Logger('ConnectivityCubit');

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity = Connectivity();

  ConnectivityCubit() : super(const ConnectivityState.initial()) {
    _initializeConnectivityCubit();
  }

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void _initializeConnectivityCubit() {
    checkConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> connectivityResult,
    ) async {
      _updateConnectivityResult(connectivityResult);
    });
  }

  Future<void> checkConnectivity() async {
    try {
      final List<ConnectivityResult> connectivityResult = await _connectivity.checkConnectivity();
      _updateConnectivityResult(connectivityResult);
    } on PlatformException catch (e) {
      _logger.severe('Failed to check connectivity', e);
      rethrow;
    }
  }

  void _updateConnectivityResult(List<ConnectivityResult> connectivityResult) {
    emit(state.copyWith(connectivityResult: connectivityResult));
    _logger.info('ConnectivityState changed to: $state');
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
