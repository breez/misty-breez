library account_cubit;

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/account/account_cubit.dart';
import 'package:logging/logging.dart';

export 'account_state.dart';

final _log = Logger("AccountCubit");

class AccountCubit extends Cubit<AccountState> with HydratedMixin {
  final BreezSDKLiquid liquidSDK;

  AccountCubit({
    required this.liquidSDK,
  }) : super(AccountState.initial()) {
    hydrate();
    _listenAccountChanges();
    _listenInitialSyncEvent();
  }

  void _listenAccountChanges() {
    _log.info("Listening to account changes");
    liquidSDK.walletInfoStream.distinct().listen((walletInfo) {
      final newState = state.copyWith(walletInfo: walletInfo);
      _log.info("AccountState changed: $newState");
      emit(newState);
    });
  }

  void _listenInitialSyncEvent() {
    _log.info("Listening to initial sync event.");
    liquidSDK.didCompleteInitialSyncStream.listen((_) {
      _log.info("Initial sync complete.");
      emit(state.copyWith(didCompleteInitialSync: true));
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

  void setOnboardingComplete(bool isComplete) {
    emit(state.copyWith(isOnboardingComplete: isComplete));
  }
}
