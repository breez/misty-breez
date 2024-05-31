import 'dart:async';
import 'dart:io';

import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/exceptions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/bloc/account/account_state.dart';
import 'package:l_breez/bloc/account/account_state_assembler.dart';
import 'package:l_breez/bloc/account/credentials_manager.dart';
import 'package:l_breez/bloc/account/payment_filters.dart';
import 'package:l_breez/bloc/account/payment_result.dart';
import 'package:l_breez/config.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/services/injector.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';

const maxPaymentAmount = 4294967;
const nodeSyncInterval = 60;

final _log = Logger("AccountBloc");

// AccountBloc is the business logic unit that is responsible to communicating with the lightning service
// and reflect the node state. It is responsible for:
// 1. Synchronizing with the node state.
// 2. Abstracting actions exposed by the lightning service.
class AccountBloc extends Cubit<AccountState> with HydratedMixin {
  static const String paymentFilterSettingsKey = "payment_filter_settings";
  static const int defaultInvoiceExpiry = Duration.secondsPerHour;

  final StreamController<PaymentResult> _paymentResultStreamController = StreamController<PaymentResult>();

  Stream<PaymentResult> get paymentResultStream => _paymentResultStreamController.stream;

  final StreamController<PaymentFilters> _paymentFiltersStreamController = BehaviorSubject<PaymentFilters>();

  Stream<PaymentFilters> get paymentFiltersStream => _paymentFiltersStreamController.stream;

  final BreezSDK _breezSDK;
  final CredentialsManager _credentialsManager;

  AccountBloc(
    this._breezSDK,
    this._credentialsManager,
  ) : super(AccountState.initial()) {
    hydrate();
    _paymentFiltersStreamController.add(state.paymentFilters);

    if (!state.initial) connect();

    _listenPaymentResultEvents();
  }

  Stream<liquid_sdk.GetInfoResponse?> walletInfoStream() async* {
    const req = liquid_sdk.GetInfoRequest(withScan: false);
    final liquidSDK = ServiceInjector().liquidSDK;
    yield await liquidSDK?.getInfo(req: req);
    while (true) {
      await Future.delayed(const Duration(seconds: 10));
      yield await liquidSDK?.getInfo(req: req);
    }
  }

  Stream<List<liquid_sdk.Payment>?> paymentsStream() async* {
    final liquidSDK = ServiceInjector().liquidSDK;
    yield await liquidSDK?.listPayments();
    while (true) {
      await Future.delayed(const Duration(seconds: 10));
      yield await liquidSDK?.listPayments();
    }
  }

  // _watchAccountChanges listens to every change in the local storage and assemble a new account state accordingly
  Stream<AccountState> _watchAccountChanges() {
    return Rx.combineLatest3<List<liquid_sdk.Payment>?, PaymentFilters, liquid_sdk.GetInfoResponse?,
        AccountState>(
      paymentsStream().asBroadcastStream(),
      paymentFiltersStream,
      walletInfoStream().asBroadcastStream(),
      (payments, paymentFilters, nodeState) {
        return assembleAccountState(payments, paymentFilters, nodeState, state) ?? state;
      },
    );
  }

  Future connect({
    String? mnemonic,
    bool isRestore = true,
  }) async {
    _log.info("connect new mnemonic: ${mnemonic != null}, restored: $isRestore");
    emit(state.copyWith(connectionStatus: ConnectionStatus.CONNECTING));
    if (mnemonic != null) {
      await _credentialsManager.storeMnemonic(mnemonic: mnemonic);
      emit(state.copyWith(
        initial: false,
        verificationStatus: isRestore ? VerificationStatus.VERIFIED : null,
      ));
    }
    await _startSdkForever(isRestore: isRestore);
  }

  Future _startSdkForever({bool isRestore = true}) async {
    _log.info("starting sdk forever");
    await _startSdkOnce(isRestore: isRestore);

    // in case we failed to start (lack of inet connection probably)
    if (state.connectionStatus == ConnectionStatus.DISCONNECTED) {
      StreamSubscription<List<ConnectivityResult>>? subscription;
      subscription = Connectivity().onConnectivityChanged.listen((event) async {
        // we should try fetch the selected lsp information when internet is back.
        if (event.contains(ConnectivityResult.none) &&
            state.connectionStatus == ConnectionStatus.DISCONNECTED) {
          await _startSdkOnce();
          if (state.connectionStatus == ConnectionStatus.CONNECTED) {
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
    var config = await Config.instance();
    try {
      emit(state.copyWith(connectionStatus: ConnectionStatus.CONNECTING));
      final mnemonic = await _credentialsManager.restoreMnemonic();
      _log.info("connecting to breez lib");
      final req = liquid_sdk.ConnectRequest(
        mnemonic: mnemonic,
        dataDir: config.workingDir,
        network: config.network,
      );
      final liquidSDK = await liquid_sdk.connect(req: req);
      ServiceInjector().setLiquidSdk(liquidSDK);
      _log.info("connected to breez lib");
      emit(state.copyWith(connectionStatus: ConnectionStatus.CONNECTED));
      _watchAccountChanges().listen((acc) {
        _log.info("State changed: $acc");
        emit(acc);
      });
    } catch (e) {
      _log.warning("failed to connect to breez lib", e);
      emit(state.copyWith(connectionStatus: ConnectionStatus.DISCONNECTED));
      rethrow;
    }
  }

  // Once connected sync sdk periodically on foreground events.
  void _onConnected() {
    _log.info("on connected");
    var lastSync = DateTime.fromMillisecondsSinceEpoch(0);
    FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground && DateTime.now().difference(lastSync).inSeconds > nodeSyncInterval) {
        await ServiceInjector().liquidSDK?.sync();
        lastSync = DateTime.now();
      }
    });
  }

  Future<liquid_sdk.PrepareSendResponse> prepareSendPayment(String invoice) async {
    _log.info("prepareSendPayment: $invoice");
    try {
      final req = liquid_sdk.PrepareSendRequest(invoice: invoice);
      return await ServiceInjector().liquidSDK!.prepareSendPayment(req: req);
    } catch (e) {
      _log.severe("prepareSendPayment error", e);
      return Future.error(e);
    }
  }

  Future<liquid_sdk.SendPaymentResponse> sendPayment(liquid_sdk.PrepareSendResponse req) async {
    _log.info("sendPayment: $req");
    try {
      return await ServiceInjector().liquidSDK!.sendPayment(req: req);
    } catch (e) {
      _log.severe("sendPayment error", e);
      return Future.error(e);
    }
  }

  Future<liquid_sdk.PrepareReceiveResponse> prepareReceivePayment(int payerAmountSat) async {
    _log.info("prepareReceivePayment: $payerAmountSat");
    try {
      final req = liquid_sdk.PrepareReceiveRequest(payerAmountSat: BigInt.from(payerAmountSat));
      return ServiceInjector().liquidSDK!.prepareReceivePayment(req: req);
    } catch (e) {
      _log.severe("prepareSendPayment error", e);
      return Future.error(e);
    }
  }

  Future<liquid_sdk.ReceivePaymentResponse> receivePayment(liquid_sdk.PrepareReceiveResponse req) async {
    _log.info("receivePayment: ${req.payerAmountSat}, fees: ${req.feesSat}");
    try {
      return ServiceInjector().liquidSDK!.receivePayment(req: req);
    } catch (e) {
      _log.severe("prepareSendPayment error", e);
      return Future.error(e);
    }
  }

  Future cancelPayment(String bolt11) async {
    _log.info("cancelPayment: $bolt11");
    throw Exception("not implemented");
  }

  Future<bool> isValidBitcoinAddress(String? address) async {
    _log.info("isValidBitcoinAddress: $address");
    if (address == null) return false;
    return _breezSDK.isValidBitcoinAddress(address);
  }

  // validatePayment is used to validate that outgoing/incoming payments meet the liquidity
  // constraints.
  void validatePayment(
    int amount,
    bool outgoing,
  ) {
    _log.info("validatePayment: $amount, $outgoing");
    /*
    var accState = state;
    if (amount > accState.maxPaymentAmount) {
      _log.info("Amount $amount is bigger than maxPaymentAmount ${accState.maxPaymentAmount}");
      throw PaymentExceededLimitError(accState.maxPaymentAmount);
    }

    if (!outgoing) {
      if (accState.maxInboundLiquidity == 0) {
        throw NoChannelCreationZeroLiqudityError();
      } else if (accState.maxInboundLiquidity < amount) {
        throw PaymentExcededLiqudityChannelCreationNotPossibleError(accState.maxInboundLiquidity);
      } else if (amount > accState.maxInboundLiquidity) {
        throw PaymentExceedLiquidityError(accState.maxInboundLiquidity);
      } else if (amount > accState.maxAllowedToReceive) {
        throw PaymentExceededLimitError(accState.maxAllowedToReceive);
      }
    }

    if (outgoing && amount > accState.maxAllowedToPay) {
      _log.info("Outgoing but amount $amount is bigger than ${accState.maxAllowedToPay}");
      if (accState.reserveAmount > 0) {
        _log.info("Reserve amount ${accState.reserveAmount}");
        throw PaymentBelowReserveError(accState.reserveAmount);
      }
      throw const InsufficientLocalBalanceError();
    }*/
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
    // TODO: Liquid - Listen to Liquid SDK's payment result stream
    _breezSDK.paymentResultStream.listen((paymentInfo) {
      _paymentResultStreamController.add(
        PaymentResult(paymentInfo: paymentInfo),
      );
    }, onError: (error) {
      _log.info("Error in paymentResultStream", error);
      var paymentHash = "";
      if (error is PaymentException) {
        final invoice = error.data.invoice;
        if (invoice != null) {
          paymentHash = invoice.paymentHash;
        }
      }
      _paymentResultStreamController
          .add(PaymentResult(error: PaymentResultError.fromException(paymentHash, error)));
    });
  }

  void mnemonicsValidated() {
    _log.info("mnemonicsValidated");
    emit(state.copyWith(verificationStatus: VerificationStatus.VERIFIED));
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
    // TODO: Liquid - Return chronologically sorted list
    return filteredPayments.reversed.toList();
  }
}
