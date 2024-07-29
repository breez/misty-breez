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
    await _connect(mnemonic, storeMnemonic: true);
  }

  Future<void> restore({required String mnemonic}) async {
    await _connect(mnemonic, storeMnemonic: true);
  }

  Future<void> reconnect() async {
    try {
      final mnemonic = await credentialsManager.restoreMnemonic();
      if (mnemonic != null) {
        await _connect(mnemonic);
      } else {
        throw Exception("No mnemonics");
      }
    } catch (e) {
      await _retryUntilConnected();
    }
  }

  Future<void> _connect(String mnemonic, {bool storeMnemonic = false}) async {
    try {
      emit(SdkConnectivityState.connecting);

      final config = await AppConfig.instance();
      final req = ConnectRequest(mnemonic: mnemonic, config: config.sdkConfig);
      await liquidSDK.connect(req: req);

      if (storeMnemonic) {
        await credentialsManager.storeMnemonic(mnemonic: mnemonic);
      }

      emit(SdkConnectivityState.connected);
    } catch (e) {
      if (storeMnemonic) {
        await credentialsManager.deleteMnemonic();
      }
      emit(SdkConnectivityState.disconnected);
      rethrow;
    }
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
