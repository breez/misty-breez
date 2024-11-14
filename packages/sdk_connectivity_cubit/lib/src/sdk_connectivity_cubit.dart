import 'dart:async';

import 'package:bip39/bip39.dart';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:credentials_manager/credentials_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:sdk_connectivity_cubit/sdk_connectivity_cubit.dart';

final _logger = Logger("SdkConnectivityCubit");

class SdkConnectivityCubit extends Cubit<SdkConnectivityState> {
  final CredentialsManager credentialsManager;
  final BreezSDKLiquid breezSdkLiquid;

  SdkConnectivityCubit({
    required this.credentialsManager,
    required this.breezSdkLiquid,
  }) : super(SdkConnectivityState.disconnected);

  Future<void> register() async {
    _logger.info("Registering a new wallet.");
    final mnemonic = generateMnemonic(strength: 128);
    await _connect(mnemonic, storeMnemonic: true);
  }

  Future<void> restore({required String mnemonic}) async {
    _logger.info("Restoring wallet.");
    await _connect(mnemonic, storeMnemonic: true);
  }

  Future<void> reconnect({String? mnemonic}) async {
    _logger.info(mnemonic == null ? "Attempting to reconnect." : "Reconnecting.");
    try {
      final restoredMnemonic = mnemonic ?? await credentialsManager.restoreMnemonic();
      if (restoredMnemonic != null) {
        await _connect(restoredMnemonic);
      } else {
        _logger.warning("Failed to restore mnemonics.");
        throw Exception("Failed to restore mnemonics.");
      }
    } catch (e) {
      _logger.warning("Failed to reconnect. Retrying when network connection is detected.");
      await _retryUntilConnected();
    }
  }

  Future<void> _connect(String mnemonic, {bool storeMnemonic = false}) async {
    try {
      emit(SdkConnectivityState.connecting);
      _logger.info("Retrieving SDK configuration...");
      final sdkConfig = (await AppConfig.instance()).sdkConfig;
      _logger.info("SDK configuration retrieved successfully.");

      final req = ConnectRequest(mnemonic: mnemonic, config: sdkConfig);
      _logger.info("Using the provided mnemonic and SDK configuration to connect to Breez SDK - Liquid.");
      await breezSdkLiquid.connect(req: req);
      _logger.info("Successfully connected to Breez SDK - Liquid.");

      _startSyncing();

      await _storeBreezApiKey(sdkConfig.breezApiKey);
      if (storeMnemonic) {
        await credentialsManager.storeMnemonic(mnemonic: mnemonic);
      }

      emit(SdkConnectivityState.connected);
    } catch (e) {
      _logger.warning("Failed to connect to Breez SDK - Liquid. Reason: $e");
      if (storeMnemonic) {
        _clearStoredCredentials();
      }
      emit(SdkConnectivityState.disconnected);
      rethrow;
    }
  }

  Future<void> _storeBreezApiKey(String? breezApiKey) async {
    final storedBreezApiKey = await credentialsManager.restoreBreezApiKey();
    if (breezApiKey != null && breezApiKey.isNotEmpty && storedBreezApiKey != breezApiKey) {
      await credentialsManager.storeBreezApiKey(breezApiKey: breezApiKey);
    }
  }

  Future<void> _clearStoredCredentials() async {
    _logger.info("Clearing stored credentials.");
    await credentialsManager.deleteBreezApiKey();
    await credentialsManager.deleteMnemonic();
    _logger.info("Successfully cleared stored credentials.");
  }

  void _startSyncing() {
    final syncManager = SyncManager(breezSdkLiquid.instance);
    syncManager.startSyncing();
  }

  Future<void> _retryUntilConnected() async {
    _logger.info("Subscribing to network events.");
    StreamSubscription<List<ConnectivityResult>>? subscription;
    subscription = Connectivity().onConnectivityChanged.listen(
      (event) async {
        final hasNetworkConnection = !(event.contains(ConnectivityResult.none) ||
            event.every(
              (result) => result == ConnectivityResult.vpn,
            ));
        // Attempt to reconnect when internet is back.
        if (hasNetworkConnection && state == SdkConnectivityState.disconnected) {
          _logger.info("Network connection detected.");
          await reconnect();
          if (state == SdkConnectivityState.connected) {
            _logger.info("SDK has reconnected. Unsubscribing from network events.");
            subscription!.cancel();
          }
        }
      },
    );
  }
}
