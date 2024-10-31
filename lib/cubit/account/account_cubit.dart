library account_cubit;

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/account/account_cubit.dart';
import 'package:logging/logging.dart';

export 'account_state.dart';

final _log = Logger("AccountCubit");

class AccountCubit extends Cubit<AccountState> with HydratedMixin {
  final BreezSDKLiquid _liquidSdk;

  AccountCubit(this._liquidSdk) : super(AccountState.initial()) {
    hydrate();

    _listenAccountChanges();
  }

  void _listenAccountChanges() {
    _log.info("Listening to account changes");
    _liquidSdk.walletInfoStream.distinct().listen((walletInfo) {
      final newState = state.copyWith(
        isInitial: false,
        walletInfo: walletInfo,
      );
      _log.info("AccountState changed: $newState");
      emit(newState);
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
}
