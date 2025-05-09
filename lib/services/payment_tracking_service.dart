import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

final Logger _logger = Logger('PaymentTrackingService');

enum PaymentTrackingType { lightningAddress, lightningInvoice, bitcoinTransaction, none }

typedef PaymentReceivedCallback = void Function(bool success);

class PaymentTrackingService {
  final BreezSDKLiquid _breezSdkLiquid;
  final PaymentsCubit _paymentsCubit;

  // Tracking state
  PaymentTrackingType _currentTrackingType = PaymentTrackingType.none;
  String? _currentDestination;

  // Subscriptions
  StreamSubscription<PaymentData?>? _lightningAddressSubscription;
  StreamSubscription<PaymentEvent>? _directPaymentSubscription;
  StreamSubscription<PaymentData?>? _btcPaymentSubscription;
  Timer? _delayedTrackingTimer;

  // Callback to notify when payment is received
  PaymentReceivedCallback? _onPaymentReceived;

  PaymentTrackingService(this._breezSdkLiquid, this._paymentsCubit);

  /// Start tracking payments for the given parameters
  void startTracking({
    required PaymentTrackingType trackingType,
    String? destination,
    String? lnAddress,
    PaymentReceivedCallback? onPaymentReceived,
  }) {
    // First stop any existing tracking
    _resetTrackingState();

    _currentTrackingType =
        (lnAddress != null && lnAddress.isNotEmpty) ? PaymentTrackingType.lightningAddress : trackingType;
    _currentDestination = destination;
    _onPaymentReceived = onPaymentReceived;

    _logger
        .info('Starting payment tracking of type: $_currentTrackingType, destination: $_currentDestination');

    switch (_currentTrackingType) {
      case PaymentTrackingType.lightningAddress:
        _startLightningAddressTracking(lnAddress!);
        break;
      case PaymentTrackingType.lightningInvoice:
        _startLightningInvoiceTracking(destination);
        break;
      case PaymentTrackingType.bitcoinTransaction:
        _startBitcoinTransactionTracking(destination);
        break;
      case PaymentTrackingType.none:
        break;
    }
  }

  void _startLightningAddressTracking(String lnAddress) {
    _logger.info('Setting up Lightning Address tracking for: $lnAddress');

    // Ignore new payments for a duration upon generating LN Address.
    _delayedTrackingTimer = Timer(
      // This delay is added to avoid popping the page before user gets the chance to copy,
      // share or get their LN address scanned.
      const Duration(milliseconds: 1600),
      () {
        _logger.info('Starting delayed Lightning Address payment tracking');

        _lightningAddressSubscription?.cancel();
        _lightningAddressSubscription = _filteredPaymentsStream().listen(
          (PaymentData? payment) {
            // Null cases are filtered out on where clause
            final PaymentData newPayment = payment!;
            _logger.info(
              'Lightning Address Payment Received! Id: ${newPayment.id}, Status: ${newPayment.status}',
            );
            _notifyPaymentReceived(true);
          },
          onError: (Object e) => _handleTrackingError(e),
        );
      },
    );
  }

  void _startLightningInvoiceTracking(String? destination) {
    if (_isValidDestination(destination)) {
      _logger.warning('Cannot track Lightning Invoice without destination');
      return;
    }
    _logger.info('Starting Lightning Invoice tracking for: $destination');
    _trackDirectPayment(destination!, PaymentType.receive);
  }

  void _startBitcoinTransactionTracking(String? destination) {
    if (_isValidDestination(destination)) {
      _logger.warning('Cannot track Bitcoin Transaction without destination');
      return;
    }
    _logger.info('Starting Bitcoin Transaction tracking for: $destination');
    _btcPaymentSubscription?.cancel();
    _btcPaymentSubscription = _filteredPaymentsStream(isBitcoin: true).listen(
      (PaymentData? payment) {
        // Null cases are filtered out on where clause
        final PaymentData newPayment = payment!;
        _logger.info(
          'Bitcoin Payment Received! Id: ${newPayment.id}, Status: ${newPayment.status}',
        );
        _notifyPaymentReceived(true);
      },
      onError: (Object e) => _handleTrackingError(e),
    );
  }

  Stream<PaymentData> _filteredPaymentsStream({bool isBitcoin = false}) {
    return _paymentsCubit.stream
        .skip(1)
        .distinct(
          (PaymentsState a, PaymentsState b) =>
              a.payments.isEmpty || b.payments.isEmpty ? true : a.payments.first.id == b.payments.first.id,
        )
        .map((PaymentsState state) => state.payments.isNotEmpty ? state.payments.first : null)
        .where(
          (PaymentData? payment) =>
              payment != null &&
              payment.paymentType == PaymentType.receive &&
              payment.status == PaymentState.pending &&
              (!isBitcoin || payment.details is PaymentDetails_Bitcoin),
        )
        .cast<PaymentData>();
  }

  void trackOutgoingPayment({
    required String? destination,
    required void Function(bool success) onPaymentComplete,
  }) {
    if (_isValidDestination(destination)) {
      _logger.warning('Cannot track outgoing payment without destination');
      return;
    }
    _resetTrackingState();

    _logger.info('Starting outgoing payment tracking for: $destination');
    _onPaymentReceived = onPaymentComplete;
    _trackDirectPayment(destination!, PaymentType.send);
  }

  /// Track a payment directly using the SDK
  void _trackDirectPayment(String destination, PaymentType paymentType) {
    final String direction = paymentType == PaymentType.receive ? 'Incoming' : 'Outgoing';
    _logger.info('$direction payment tracking started for: $destination');

    _directPaymentSubscription?.cancel();
    _directPaymentSubscription = _breezSdkLiquid.paymentEventStream.where((PaymentEvent paymentEvent) {
      final Payment payment = paymentEvent.payment;
      final String newPaymentDestination = payment.destination ?? '';
      final bool doesDestinationMatch = newPaymentDestination == destination;

      /// For outgoing payments, we only consider payments that are complete,
      /// since we're only interested in successful outgoing transactions.
      final bool isPaymentValid = paymentType == PaymentType.receive
          ? (payment.status == PaymentState.pending || payment.status == PaymentState.complete)
          : (payment.status == PaymentState.complete);

      final bool isPaymentOfType = payment.paymentType == paymentType;

      return doesDestinationMatch && isPaymentOfType && isPaymentValid;
    }).listen(
      (PaymentEvent paymentEvent) {
        final Payment payment = paymentEvent.payment;
        _logger.info(
          '$direction payment detected! Destination: ${payment.destination}, Status: ${payment.status}',
        );
        _notifyPaymentReceived(true);
      },
      onError: (Object e) => _handleTrackingError(e),
    );
  }

  void _handleTrackingError(Object error) {
    _logger.warning('Payment tracking error', error);
    _notifyPaymentReceived(false);
  }

  void _notifyPaymentReceived(bool success) {
    _onPaymentReceived?.call(success);
  }

  void dispose() {
    _resetTrackingState();
  }

  /// Stop all payment tracking
  void _resetTrackingState() {
    _logger.info('Stopping all payment tracking');

    _lightningAddressSubscription?.cancel();
    _lightningAddressSubscription = null;

    _directPaymentSubscription?.cancel();
    _directPaymentSubscription = null;

    _btcPaymentSubscription?.cancel();
    _btcPaymentSubscription = null;

    _delayedTrackingTimer?.cancel();
    _delayedTrackingTimer = null;

    _currentTrackingType = PaymentTrackingType.none;
    _currentDestination = null;
    _onPaymentReceived = null;
  }

  /* Helper Methods */

  bool _isValidDestination(String? destination) => destination?.isNotEmpty == true;
}
