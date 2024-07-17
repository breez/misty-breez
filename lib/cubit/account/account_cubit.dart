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
import 'package:l_breez/cubit/model/models.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/utils/constants.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';

export 'account_state.dart';
export 'account_state_assembler.dart';

const nodeSyncInterval = 60;

final _log = Logger("AccountCubit");

// AccountCubit is the business logic unit that is responsible to communicating with the lightning service
// and reflect the node state. It is responsible for:
// 1. Synchronizing with the node state.
// 2. Abstracting actions exposed by the lightning service.
class AccountCubit extends Cubit<AccountState> with HydratedMixin {
  static const String paymentFilterSettingsKey = "payment_filter_settings";
  static const int defaultInvoiceExpiry = Duration.secondsPerHour;

  final StreamController<PaymentResult> _paymentResultStreamController = StreamController<PaymentResult>();

  Stream<PaymentResult> get paymentResultStream => _paymentResultStreamController.stream;

  final StreamController<PaymentFilters> _paymentFiltersStreamController = BehaviorSubject<PaymentFilters>();

  Stream<PaymentFilters> get paymentFiltersStream => _paymentFiltersStreamController.stream;

  final CredentialsManager _credentialsManager;
  final BreezSDKLiquid _liquidSdk;

  AccountCubit(
    this._liquidSdk,
    this._credentialsManager,
  ) : super(AccountState.initial()) {
    hydrate();
    _paymentFiltersStreamController.add(state.paymentFilters);

    if (!state.initial) connect();

    _listenPaymentResultEvents();
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
      emit(state.copyWith(
        initial: false,
        verificationStatus: isRestore ? VerificationStatus.verified : null,
      ));
    }
    await _startSdkForever(isRestore: isRestore);
  }

  Future _startSdkForever({bool isRestore = true}) async {
    _log.info("starting sdk forever");
    await _startSdkOnce(isRestore: isRestore);

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
      emit(state.copyWith(connectionStatus: ConnectionStatus.connected));
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

  Future<liquid_sdk.PrepareSendResponse> prepareSendPayment(String invoice) async {
    _log.info("prepareSendPayment: $invoice");
    try {
      final req = liquid_sdk.PrepareSendRequest(invoice: invoice);
      return await _liquidSdk.instance!.prepareSendPayment(req: req);
    } catch (e) {
      _log.severe("prepareSendPayment error", e);
      return Future.error(e);
    }
  }

  Future<liquid_sdk.SendPaymentResponse> sendPayment(liquid_sdk.PrepareSendResponse req) async {
    _log.info("sendPayment: $req");
    try {
      return await _liquidSdk.instance!.sendPayment(req: req);
    } catch (e) {
      _log.severe("sendPayment error", e);
      return Future.error(e);
    }
  }

  Future<liquid_sdk.PrepareReceiveResponse> prepareReceivePayment(int payerAmountSat) async {
    _log.info("prepareReceivePayment: $payerAmountSat");
    try {
      final req = liquid_sdk.PrepareReceiveRequest(payerAmountSat: BigInt.from(payerAmountSat));
      return _liquidSdk.instance!.prepareReceivePayment(req: req);
    } catch (e) {
      _log.severe("prepareSendPayment error", e);
      return Future.error(e);
    }
  }

  Future<liquid_sdk.ReceivePaymentResponse> receivePayment(liquid_sdk.PrepareReceiveResponse req) async {
    _log.info("receivePayment: ${req.payerAmountSat}, fees: ${req.feesSat}");
    try {
      return _liquidSdk.instance!.receivePayment(req: req);
    } catch (e) {
      _log.severe("prepareSendPayment error", e);
      return Future.error(e);
    }
  }

  Future cancelPayment(String bolt11) async {
    _log.info("cancelPayment: $bolt11");
    throw Exception("not implemented");
  }

  // validatePayment is used to validate that outgoing/incoming payments meet the liquidity
  // constraints.
  void validatePayment(
    int amount,
    bool outgoing,
  ) {
    _log.info("validatePayment: $amount, $outgoing");
    var accState = state;
    if (outgoing) {
      if (amount > accState.balance) {
        throw const InsufficientLocalBalanceError();
      }
    }

    if (amount > accState.maxPaymentAmountSat) {
      _log.info("Amount $amount is bigger than maxPaymentAmount ${accState.maxPaymentAmountSat}");
      throw PaymentExceededLimitError(accState.maxPaymentAmountSat);
    }

    if (amount < minPaymentAmountSat) {
      _log.info("Amount $amount is smaller than minPaymentAmountSat $minPaymentAmountSat");
      throw const PaymentBelowLimitError(minPaymentAmountSat);
    }
  }

  void changePaymentFilter({
    List<liquid_sdk.PaymentType>? filters,
    int? fromTimestamp,
    int? toTimestamp,
  }) async {
    _log.info("changePaymentFilter: $filters, $fromTimestamp, $toTimestamp");
    _paymentFiltersStreamController.add(
      state.paymentFilters.copyWith(
        filters: filters,
        fromTimestamp: fromTimestamp,
        toTimestamp: toTimestamp,
      ),
    );
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

  void _listenPaymentResultEvents() {
    _log.info("_listenPaymentResultEvents");
    _liquidSdk.paymentResultStream.listen((paymentInfo) {
      _paymentResultStreamController.add(
        PaymentResult(paymentInfo: paymentInfo),
      );
    }, onError: (error) {
      _log.info("Error in paymentResultStream", error);
      var swapId = "";
      if (error is PaymentException) {
        if (error.details.swapId != null) {
          swapId = error.details.swapId!;
        }
      }
      _paymentResultStreamController.add(
        PaymentResult(
          error: PaymentResultError.fromException(swapId, error),
        ),
      );
    });
  }

  void mnemonicsValidated() {
    _log.info("mnemonicsValidated");
    emit(state.copyWith(verificationStatus: VerificationStatus.verified));
  }

  List<PaymentMinutiae> filterPaymentList() {
    final nonFilteredPayments = state.payments;
    final paymentFilters = state.paymentFilters;

    var filteredPayments = nonFilteredPayments;
    // Apply date filters, if there's any
    if (paymentFilters.fromTimestamp != null || paymentFilters.toTimestamp != null) {
      filteredPayments = nonFilteredPayments.where((paymentMinutiae) {
        final fromTimestamp = paymentFilters.fromTimestamp;
        final toTimestamp = paymentFilters.toTimestamp;
        final milliseconds = paymentMinutiae.paymentTime.millisecondsSinceEpoch;
        if (fromTimestamp != null && toTimestamp != null) {
          return fromTimestamp < milliseconds && milliseconds < toTimestamp;
        }
        return true;
      }).toList();
    }

    // Apply payment type filters, if there's any
    final paymentTypeFilters = paymentFilters.filters;
    if (paymentTypeFilters != null && paymentTypeFilters != liquid_sdk.PaymentType.values) {
      filteredPayments = filteredPayments.where((paymentMinutiae) {
        return paymentTypeFilters.any(
          (filter) {
            return filter.name == paymentMinutiae.paymentType.name;
          },
        );
      }).toList();
    }
    return filteredPayments;
  }
}
