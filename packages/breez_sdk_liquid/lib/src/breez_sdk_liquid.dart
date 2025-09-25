import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:rxdart/rxdart.dart';

class BreezSDKLiquid {
  static final BreezSDKLiquid _singleton = BreezSDKLiquid._internal();

  factory BreezSDKLiquid() => _singleton;

  late final Stream<void> didCompleteInitialSyncStream;

  final StreamController<void> _didCompleteInitialSyncController = StreamController<void>.broadcast();

  BreezSDKLiquid._internal() {
    initializeLogStream();
    didCompleteInitialSyncStream = _didCompleteInitialSyncController.stream.take(1);
  }

  liquid_sdk.BreezSdkLiquid? _instance;

  liquid_sdk.BreezSdkLiquid? get instance => _instance;

  Future<void> connect({required liquid_sdk.ConnectRequest req}) async {
    try {
      _subscribeToLogStream();
      _instance = await liquid_sdk.connect(req: req);
      _initializeEventsStream(_instance!);
      _subscribeToEventsStream(_instance!);
      await _fetchWalletData(_instance!);
    } catch (e) {
      _instance = null;
      _unsubscribeFromSdkStreams();
      rethrow;
    }
  }

  void disconnect() {
    if (_instance == null) {
      throw Exception();
    }

    _instance!.disconnect();
    _unsubscribeFromSdkStreams();
    _instance = null;
  }

  Future<void> _fetchWalletData(liquid_sdk.BreezSdkLiquid sdk) async {
    await _getInfo(sdk);
    await _listPayments(sdk: sdk);
  }

  Future<liquid_sdk.GetInfoResponse> _getInfo(liquid_sdk.BreezSdkLiquid sdk) async {
    final liquid_sdk.GetInfoResponse getInfoResponse = await sdk.getInfo();
    _getInfoResponseController.add(getInfoResponse);
    return getInfoResponse;
  }

  Future<List<liquid_sdk.Payment>> _listPayments({required liquid_sdk.BreezSdkLiquid sdk}) async {
    const liquid_sdk.ListPaymentsRequest req = liquid_sdk.ListPaymentsRequest();
    final List<liquid_sdk.Payment> paymentsList = await sdk.listPayments(req: req);
    _paymentsController.add(paymentsList);
    return paymentsList;
  }

  StreamSubscription<liquid_sdk.LogEntry>? _breezLogSubscription;

  Stream<liquid_sdk.LogEntry>? _breezLogStream;

  /// Initializes SDK log stream.
  ///
  /// Call once on your Dart entrypoint file, e.g.; `lib/main.dart`.
  void initializeLogStream() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      _breezLogStream ??= const EventChannel('breez_sdk_liquid_logs').receiveBroadcastStream().map(
        (dynamic log) => liquid_sdk.LogEntry(line: log['line'], level: log['level']),
      );
    } else {
      _breezLogStream ??= liquid_sdk.breezLogStream().asBroadcastStream();
    }
  }

  StreamSubscription<liquid_sdk.SdkEvent>? _breezEventsSubscription;

  Stream<liquid_sdk.SdkEvent>? _breezEventsStream;

  void _initializeEventsStream(liquid_sdk.BreezSdkLiquid sdk) {
    _breezEventsStream ??= sdk.addEventListener().asBroadcastStream();
  }

  final StreamController<liquid_sdk.GetInfoResponse> _getInfoResponseController =
      BehaviorSubject<liquid_sdk.GetInfoResponse>();

  Stream<liquid_sdk.GetInfoResponse> get getInfoResponseStream => _getInfoResponseController.stream;

  final StreamController<List<liquid_sdk.Payment>> _paymentsController =
      BehaviorSubject<List<liquid_sdk.Payment>>();

  Stream<List<liquid_sdk.Payment>> get paymentsStream => _paymentsController.stream;

  final StreamController<PaymentEvent> _paymentEventStream = StreamController<PaymentEvent>.broadcast();

  Stream<PaymentEvent> get paymentEventStream => _paymentEventStream.stream;

  /// Subscribes to SdkEvent's stream
  void _subscribeToEventsStream(liquid_sdk.BreezSdkLiquid sdk) {
    _breezEventsSubscription = _breezEventsStream?.listen((liquid_sdk.SdkEvent event) async {
      if (event.isPaymentEvent) {
        _paymentEventStream.add(PaymentEvent.fromSdkEvent(event));
      } else if (event is liquid_sdk.SdkEvent_PaymentFailed) {
        _paymentEventStream.addError(event);
      }
      await _fetchWalletData(sdk);
      if (event is liquid_sdk.SdkEvent_Synced) {
        _didCompleteInitialSyncController.add(null);
      }
    });
  }

  final StreamController<liquid_sdk.LogEntry> _logStreamController =
      StreamController<liquid_sdk.LogEntry>.broadcast();

  Stream<liquid_sdk.LogEntry> get logStream => _logStreamController.stream;

  /// Subscribes to SDK's logs stream
  void _subscribeToLogStream() {
    _breezLogSubscription = _breezLogStream?.listen(
      (liquid_sdk.LogEntry logEntry) {
        _logStreamController.add(logEntry);
      },
      onError: (Object e) {
        _logStreamController.addError(e);
      },
    );
  }

  /// Unsubscribes from SDK's event & log streams.
  void _unsubscribeFromSdkStreams() {
    _breezEventsSubscription?.cancel();
    _breezLogSubscription?.cancel();
  }
}

extension PaymentEventExtension on liquid_sdk.SdkEvent {
  bool get isPaymentEvent {
    return this is liquid_sdk.SdkEvent_PaymentFailed ||
        this is liquid_sdk.SdkEvent_PaymentPending ||
        this is liquid_sdk.SdkEvent_PaymentRefundable ||
        this is liquid_sdk.SdkEvent_PaymentRefunded ||
        this is liquid_sdk.SdkEvent_PaymentRefundPending ||
        this is liquid_sdk.SdkEvent_PaymentSucceeded ||
        this is liquid_sdk.SdkEvent_PaymentWaitingConfirmation ||
        this is liquid_sdk.SdkEvent_PaymentWaitingFeeAcceptance;
  }
}

class PaymentEvent {
  final liquid_sdk.SdkEvent sdkEvent;
  final liquid_sdk.Payment payment;

  PaymentEvent({required this.sdkEvent, required this.payment});

  factory PaymentEvent.fromSdkEvent(liquid_sdk.SdkEvent event) {
    return PaymentEvent(sdkEvent: event, payment: (event as dynamic).details);
  }
}
