import 'dart:async';

import 'package:bip39/bip39.dart';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:credentials_manager/credentials_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:sdk_connectivity_cubit/sdk_connectivity_cubit.dart';

class SdkConnectivityCubit extends Cubit<SdkConnectivityState> {
  final CredentialsManager credentialsManager;
  final BreezSDKLiquid liquidSDK;

  SdkConnectivityCubit({
    required this.credentialsManager,
    required this.liquidSDK,
  }) : super(SdkConnectivityState.disconnected);

  Future<void> register() async {
    final mnemonic = generateMnemonic(strength: 128);
    await _connect(mnemonic, storeCredentials: true);
  }

  Future<void> restore({required String mnemonic}) async {
    await _connect(mnemonic, storeCredentials: true);
  }

  Future<void> reconnect({String? mnemonic}) async {
    try {
      final restoredMnemonic = mnemonic ?? await credentialsManager.restoreMnemonic();
      if (restoredMnemonic != null) {
        await _connect(restoredMnemonic);
      } else {
        throw Exception("No mnemonics");
      }
    } catch (e) {
      await _retryUntilConnected();
    }
  }

  Future<void> _connect(String mnemonic, {bool storeCredentials = false}) async {
    try {
      emit(SdkConnectivityState.connecting);

      final config = await AppConfig.instance();
      final req = ConnectRequest(mnemonic: mnemonic, config: config.sdkConfig);
      await liquidSDK.connect(req: req);

      _startSyncing();

      if (storeCredentials) {
        _storeCredentials(breezApiKey: config.sdkConfig.breezApiKey, mnemonic: mnemonic);
      }

      emit(SdkConnectivityState.connected);
    } catch (e) {
      if (storeCredentials) {
        _clearStoredCredentials();
      }
      emit(SdkConnectivityState.disconnected);
      rethrow;
    }
  }

  Future<void> _storeCredentials({required String mnemonic, String? breezApiKey}) async {
    await _storeBreezApiKey(breezApiKey);
    await credentialsManager.storeMnemonic(mnemonic: mnemonic);
  }

  Future<void> _storeBreezApiKey(String? breezApiKey) async {
    final storedBreezApiKey = await credentialsManager.restoreBreezApiKey();

    // Store the API key from AppConfig if it's not stored yet or if it has changed
    if (breezApiKey != null && breezApiKey.isNotEmpty) {
      if (storedBreezApiKey == null || storedBreezApiKey.isEmpty || storedBreezApiKey != breezApiKey) {
        await credentialsManager.storeBreezApiKey(breezApiKey: breezApiKey);
      }
    }
  }

  Future<void> _clearStoredCredentials() async {
    await credentialsManager.deleteBreezApiKey();
    await credentialsManager.deleteMnemonic();
  }

  void _startSyncing() {
    final syncManager = SyncManager(liquidSDK.instance);
    syncManager.startSyncing();
  }

  Future<void> _retryUntilConnected() async {
    StreamSubscription<List<ConnectivityResult>>? subscription;
    subscription = Connectivity().onConnectivityChanged.listen(
      (event) async {
        final hasNetworkConnection = !(event.contains(ConnectivityResult.none) ||
            event.every(
              (result) => result == ConnectivityResult.vpn,
            ));
        // Attempt to reconnect when internet is back.
        if (hasNetworkConnection && state == SdkConnectivityState.disconnected) {
          await reconnect();
          if (state == SdkConnectivityState.connected) {
            subscription!.cancel();
          }
        }
      },
    );
  }
}
