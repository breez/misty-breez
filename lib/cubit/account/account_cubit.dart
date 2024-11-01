library account_cubit;

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:keychain/keychain.dart';
import 'package:l_breez/cubit/account/account_cubit.dart';
import 'package:logging/logging.dart';

export 'account_state.dart';

final _log = Logger("AccountCubit");

const String accountIsOnboardingComplete = "account_is_onboarding_complete";

class AccountCubit extends Cubit<AccountState> with HydratedMixin {
  final BreezSDKLiquid liquidSDK;
  final KeyChain keyChain;

  AccountCubit({required this.liquidSDK, required this.keyChain}) : super(AccountState.initial()) {
    hydrate();
    restoreIsOnboardingCompleteFlag();
    _listenAccountChanges();
  }

  void _listenAccountChanges() {
    _log.info("Listening to account changes");
    liquidSDK.walletInfoStream.distinct().listen((walletInfo) {
      final newState = state.copyWith(walletInfo: walletInfo);
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

  Future storeIsOnboardingCompleteFlag({
    required bool isOnboardingComplete,
  }) async {
    try {
      await keyChain.write(accountIsOnboardingComplete, isOnboardingComplete.toString());
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  Future<bool> restoreIsOnboardingCompleteFlag() async {
    try {
      String? isOnboardingCompleteStr = await keyChain.read(accountIsOnboardingComplete);
      bool isOnboardingComplete = isOnboardingCompleteStr == null ? false : isOnboardingCompleteStr == 'true';
      final newState = state.copyWith(isOnboardingComplete: isOnboardingComplete);
      emit(newState);
      return isOnboardingComplete;
    } catch (err) {
      throw Exception(err.toString());
    }
  }
}
