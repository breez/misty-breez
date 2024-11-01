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

  AccountCubit({
    required this.liquidSDK,
    required this.keyChain,
  }) : super(AccountState.initial()) {
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

  Future<void> storeIsOnboardingCompleteFlag({
    required bool isOnboardingComplete,
  }) async {
    final walletInfo = state.walletInfo;
    if (walletInfo == null) {
      _log.info("Failed to store isOnboardingComplete. walletInfo is missing from AccountState.");
      return;
    }

    try {
      final walletKey = accountIsOnboardingComplete + walletInfo.fingerprint;
      await keyChain.write(walletKey, isOnboardingComplete.toString());
      emit(state.copyWith(isOnboardingComplete: isOnboardingComplete));
    } catch (err) {
      _log.severe("Error storing onboarding flag: $err");
    }
  }

  Future<bool> restoreIsOnboardingCompleteFlag() async {
    final walletInfo = state.walletInfo;
    if (walletInfo == null) {
      _log.info("Failed to restore isOnboardingComplete. walletInfo is missing from AccountState.");
      return false;
    }

    try {
      final walletKey = accountIsOnboardingComplete + walletInfo.fingerprint;
      final isOnboardingCompleteStr = await keyChain.read(walletKey);
      final isOnboardingComplete = isOnboardingCompleteStr == 'true';
      emit(state.copyWith(isOnboardingComplete: isOnboardingComplete));
      return isOnboardingComplete;
    } catch (err) {
      _log.severe("Error restoring onboarding flag: $err");
      return false;
    }
  }
}
