import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';

const syncIntervalSeconds = 60;

class SyncManager {
  StreamSubscription<FGBGType>? _lifecycleSubscription;
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;
  DateTime _lastSync = DateTime.fromMillisecondsSinceEpoch(0);

  final BindingLiquidSdk? wallet;

  SyncManager(this.wallet);

  void startSyncing() {
    _lifecycleSubscription = FGBGEvents.stream.skip(1).listen((event) async {
      if (event == FGBGType.foreground && _shouldSync()) {
        await _sync();
      }
    });

    // Force a sync after Network is back
    // TODO: Liquid SDK - This sync should happen on SDK layer after re-establishing connection
    _networkSubscription = Connectivity().onConnectivityChanged.skip(1).listen(
      (event) async {
        final hasNetworkConnection = !(event.contains(ConnectivityResult.none) ||
            event.every(
              (result) => result == ConnectivityResult.vpn,
            ));
        if (hasNetworkConnection) {
          await _sync();
        }
      },
    );
  }

  bool _shouldSync() => DateTime.now().difference(_lastSync).inSeconds > syncIntervalSeconds;

  Future<void> _sync() async {
    if (wallet != null) {
      await wallet!.sync();
      _lastSync = DateTime.now();
    } else {
      disconnect();
    }
  }

  void disconnect() {
    _lifecycleSubscription?.cancel();
    _lifecycleSubscription = null;
    _networkSubscription?.cancel();
    _networkSubscription = null;
    _lastSync = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
