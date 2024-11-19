library account_cubit;

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';

export 'account_state.dart';

final Logger _logger = Logger('AccountCubit');

class AccountCubit extends Cubit<AccountState> with HydratedMixin<AccountState> {
  final BreezSDKLiquid breezSdkLiquid;

  AccountCubit({
    required this.breezSdkLiquid,
  }) : super(AccountState.initial()) {
    hydrate();
    _listenAccountChanges();
    _listenInitialSyncEvent();
  }

  void _listenAccountChanges() {
    _logger.info('Listening to account changes');
    breezSdkLiquid.walletInfoStream.distinct().listen(
      (GetInfoResponse walletInfo) {
        final AccountState newState = state.copyWith(walletInfo: walletInfo);
        _logger.info('AccountState changed: $newState');
        emit(newState);
      },
    );
  }

  void _listenInitialSyncEvent() {
    _logger.info('Listening to initial sync event.');
    breezSdkLiquid.didCompleteInitialSyncStream.listen((_) {
      _logger.info('Initial sync complete.');
      emit(state.copyWith(isRestoring: false, didCompleteInitialSync: true));
    });
  }

  @override
  AccountState? fromJson(Map<String, dynamic> json) {
    return AccountState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(AccountState state) {
    return state.toJson();
  }

  void setIsRestoring(bool isRestoring) {
    emit(state.copyWith(isRestoring: isRestoring));
  }

  void setOnboardingComplete(bool isComplete) {
    emit(state.copyWith(isOnboardingComplete: isComplete));
  }
}
