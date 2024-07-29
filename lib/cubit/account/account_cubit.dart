library account_cubit;

import 'dart:async';
import 'dart:io';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:credentials_manager/credentials_manager.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/account/account_cubit.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';

export 'account_state.dart';
export 'account_state_assembler.dart';

const nodeSyncInterval = 60;

final _log = Logger("AccountCubit");

// AccountCubit is the business logic unit that is responsible to communicating with the lightning service
// and reflect the wallet state. It is responsible for:
// 1. Synchronizing with the wallet state.
// 2. Abstracting actions exposed by the lightning service.
class AccountCubit extends Cubit<AccountState> with HydratedMixin {
  final CredentialsManager _credentialsManager;
  final BreezSDKLiquid _liquidSdk;

  AccountCubit(
    this._liquidSdk,
    this._credentialsManager,
  ) : super(AccountState.initial()) {
    hydrate();
    if (!state.initial) connect();
  }

  // _watchAccountChanges listens to every change in the local storage and assemble a new account state accordingly
  Stream<AccountState> _watchAccountChanges() {
    return Rx.combineLatest3<List<liquid_sdk.Payment>?, PaymentFilters, liquid_sdk.GetInfoResponse?,
        AccountState>(
      _liquidSdk.paymentsStream,
      paymentFiltersStream,
      _liquidSdk.walletInfoStream,
      (payments, paymentFilters, walletInfo) {
        return assembleAccountState(payments, paymentFilters, walletInfo, state) ?? state;
      },
    );
  }

  Future connect({
    String? mnemonic,
    bool isRestore = true,
  }) async {
    _log.info("connect new mnemonic: ${mnemonic != null}, restored: $isRestore");
    emit(state.copyWith(connectionStatus: ConnectionStatus.connecting));
    if (mnemonic != null) {
      await _credentialsManager.storeMnemonic(mnemonic: mnemonic);
    }
    await _startSdkForever(isRestore: isRestore);
  }


    // in case we failed to start (lack of inet connection probably)
    if (state.connectionStatus == ConnectionStatus.disconnected) {
      StreamSubscription<List<ConnectivityResult>>? subscription;
      subscription = Connectivity().onConnectivityChanged.listen((event) async {
        // we should try fetch the selected lsp information when internet is back.
        if (event.contains(ConnectivityResult.none) &&
            state.connectionStatus == ConnectionStatus.disconnected) {
          await _startSdkOnce();
          if (state.connectionStatus == ConnectionStatus.connected) {
            subscription!.cancel();
            _onConnected();
          }
        }
      });
    } else {
      _onConnected();
    }
  }

  Future _startSdkOnce({bool isRestore = true}) async {
    _log.info("starting sdk once");
    var config = await AppConfig.instance();
    try {
      emit(state.copyWith(connectionStatus: ConnectionStatus.connecting));
      final mnemonic = await _credentialsManager.restoreMnemonic();
      _log.info("connecting to breez lib");
      final req = liquid_sdk.ConnectRequest(
        config: config.sdkConfig,
        mnemonic: mnemonic,
      );
      await _liquidSdk.connect(req: req);
      _log.info("connected to breez lib");
      emit(state.copyWith(
        initial: false,
        connectionStatus: ConnectionStatus.connected,
        verificationStatus: isRestore ? VerificationStatus.verified : null,
      ));
      _watchAccountChanges().listen((acc) {
        _log.info("State changed: $acc");
        emit(acc);
      });
    } catch (e) {
      _log.warning("failed to connect to breez lib", e);
      emit(state.copyWith(connectionStatus: ConnectionStatus.disconnected));
      rethrow;
    }
  }

  // Once connected sync sdk periodically on foreground events.
  void _onConnected() {
    _log.info("on connected");
    var lastSync = DateTime.fromMillisecondsSinceEpoch(0);
    FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground && DateTime.now().difference(lastSync).inSeconds > nodeSyncInterval) {
        _liquidSdk.instance?.sync();
        lastSync = DateTime.now();
      }
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

  Future<List<File>> exportCredentialFiles() async {
    _log.info("exportCredentialFiles");
    return _credentialsManager.exportCredentials();
  }

  void recursiveFolderCopySync(String path1, String path2) {
    _log.info("recursiveFolderCopySync: $path1, $path2");
    Directory dir1 = Directory(path1);
    Directory dir2 = Directory(path2);
    if (!dir2.existsSync()) {
      dir2.createSync(recursive: true);
    }

    dir1.listSync().forEach((element) {
      String elementName = p.basename(element.path);
      String newPath = "${dir2.path}/$elementName";
      if (element is File) {
        File newFile = File(newPath);
        newFile.writeAsBytesSync(element.readAsBytesSync());
      } else {
        recursiveFolderCopySync(element.path, newPath);
      }
    });
  }

  void mnemonicsValidated() {
    _log.info("mnemonicsValidated");
    emit(state.copyWith(verificationStatus: VerificationStatus.verified));
  }

}
