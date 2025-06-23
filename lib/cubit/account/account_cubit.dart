import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/account/distinct_get_info_response.dart';
import 'package:misty_breez/cubit/cubit.dart';

export 'account_state.dart';
export 'get_info_response_extension.dart';
export 'onboarding_preferences.dart';

final Logger _logger = Logger('AccountCubit');

class AccountCubit extends Cubit<AccountState> with HydratedMixin<AccountState> {
  final BreezSDKLiquid breezSdkLiquid;

  AccountCubit(this.breezSdkLiquid) : super(AccountState.initial()) {
    hydrate();

    _listenAccountChanges();
    _listenInitialSyncEvent();
  }

  void _listenAccountChanges() {
    _logger.info('Initial AccountState: $state');
    _logger.info('Listening to account changes');
    breezSdkLiquid.getInfoResponseStream
        .map((GetInfoResponse e) => DistinctGetInfoResponse(e))
        .distinct()
        .map((DistinctGetInfoResponse e) => e.inner)
        .listen((GetInfoResponse getInfoResponse) {
          getInfoResponse.logChanges(state);
          emit(
            state.copyWith(
              walletInfo: getInfoResponse.walletInfo,
              blockchainInfo: getInfoResponse.blockchainInfo,
            ),
          );
        });
  }

  void _listenInitialSyncEvent() {
    _logger.info('Listening to initial sync event.');
    breezSdkLiquid.didCompleteInitialSyncStream.listen((_) {
      _logger.info('Initial sync complete.');
      emit(state.copyWith(isRestoring: false, didCompleteInitialSync: true));
    });
  }

  @override
  AccountState? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      _logger.severe('No stored data found.');
      return null;
    }

    try {
      final AccountState result = AccountState.fromJson(json);
      _logger.fine('Successfully hydrated with $result');
      return result;
    } catch (e, stackTrace) {
      _logger.severe('Error hydrating: $e');
      _logger.fine('Stack trace: $stackTrace');
      return AccountState.initial();
    }
  }

  @override
  Map<String, dynamic>? toJson(AccountState state) {
    try {
      final Map<String, dynamic> result = state.toJson();
      _logger.fine('Serialized: $result');
      return result;
    } catch (e) {
      _logger.severe('Error serializing: $e');
      return null;
    }
  }

  @override
  String get storagePrefix => defaultTargetPlatform == TargetPlatform.iOS ? 'lVa' : 'AccountCubit';

  void setIsRestoring(bool isRestoring) {
    emit(state.copyWith(isRestoring: isRestoring));
  }
}
