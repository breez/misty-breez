import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

final Logger _logger = Logger('PaymentTrackingService');

/// Types of payment tracking supported by the application
enum PaymentTrackingType { lightningAddress, lightningInvoice, bitcoinTransaction, none }

typedef PaymentCompleteCallback = void Function(bool success);

/// Service responsible for tracking payments of various types
class PaymentTrackingService {
  final BreezSDKLiquid _breezSdkLiquid;
  final PaymentsCubit _paymentsCubit;

  // Tracking state
  PaymentTrackingType _currentTrackingType = PaymentTrackingType.none;
  String? _currentDestination;

  // Subscriptions
  final Map<PaymentTrackingType, StreamSubscription<dynamic>?> _subscriptions =
      <PaymentTrackingType, StreamSubscription<dynamic>?>{
    PaymentTrackingType.lightningAddress: null,
    PaymentTrackingType.lightningInvoice: null,
    PaymentTrackingType.bitcoinTransaction: null,
  };

  Timer? _delayedTrackingTimer;

  // Callback to notify when payment is received
  PaymentCompleteCallback? _onPaymentReceived;

  PaymentTrackingService(this._breezSdkLiquid, this._paymentsCubit);

  /// Start tracking payments for the given parameters
  void startTracking({
    // Common parameters
    required PaymentType paymentType,
    required String? destination,
    required PaymentCompleteCallback onPaymentComplete,

    // Parameters for specific payment types
    PaymentTrackingType trackingType = PaymentTrackingType.none,
    String? lnAddress,
  }) {
    // Validate input parameters and handle early returns
    if (!_validateTrackingParameters(trackingType, destination, lnAddress, paymentType)) {
      return;
    }

    // Reset tracking state and set callback
    _resetTrackingState();
    _onPaymentReceived = onPaymentComplete;

    // Route to appropriate tracking method based on payment type
    if (paymentType == PaymentType.send) {
      _setupOutgoingPaymentTracking(destination!);
    } else {
      _setupIncomingPaymentTracking(trackingType, destination, lnAddress);
    }
  }

  /// Validates tracking parameters and logs warnings for invalid configurations
  bool _validateTrackingParameters(
    PaymentTrackingType trackingType,
    String? destination,
    String? lnAddress,
    PaymentType paymentType,
  ) {
    // Case 1: Lightning Address tracking requires a valid Lightning Address
    if (trackingType == PaymentTrackingType.lightningAddress) {
      if (lnAddress == null || lnAddress.isEmpty) {
        _logger.warning('Cannot track Lightning Address payment: missing Lightning Address');
        return false;
      }
    }
    // Case 2: All other tracking types require a valid destination
    else if (!_isValidDestination(destination)) {
      final String direction = paymentType == PaymentType.send ? 'outgoing' : 'incoming';
      _logger.warning('Cannot track $direction payment: invalid destination');
      return false;
    }

    return true;
  }

  /// Sets up tracking for outgoing payments
  void _setupOutgoingPaymentTracking(String destination) {
    _logger.info('Starting outgoing payment tracking for: $destination');
    _trackDirectPayment(destination, PaymentType.send);
  }

  /// Sets up tracking for incoming payments based on the tracking type
  void _setupIncomingPaymentTracking(
    PaymentTrackingType trackingType,
    String? destination,
    String? lnAddress,
  ) {
    // Determine specific tracking type (prioritize Lightning Address if provided)
    _currentTrackingType =
        (lnAddress != null && lnAddress.isNotEmpty) ? PaymentTrackingType.lightningAddress : trackingType;
    _currentDestination = destination;
    _startTrackingByType(_currentTrackingType, destination, lnAddress);
  }

  /// Start tracking based on the specific payment tracking type
  void _startTrackingByType(
    PaymentTrackingType trackingType,
    String? destination,
    String? lnAddress,
  ) {
    // Early return for none type
    if (trackingType == PaymentTrackingType.none) {
      return;
    }

    // Map of tracking functions by type
    final Map<PaymentTrackingType, Function> trackingFunctions = <PaymentTrackingType, Function>{
      PaymentTrackingType.lightningAddress: () => _startLightningAddressTracking(lnAddress!),
      PaymentTrackingType.lightningInvoice: () => _startLightningInvoiceTracking(destination!),
      PaymentTrackingType.bitcoinTransaction: () => _startBitcoinPaymentTracking(destination!),
    };

    // Execute the appropriate tracking function or log warning
    if (trackingFunctions.containsKey(trackingType)) {
      _logger.info(
        'Starting payment tracking of type: $_currentTrackingType, destination: $_currentDestination',
      );
      trackingFunctions[trackingType]!();
    } else {
      _logger.warning('Unhandled payment tracking type: $trackingType');
    }
  }

  void _startLightningAddressTracking(String lnAddress) {
    _logger.info('Starting Lightning Address tracking for: $lnAddress');
    // Add delay to avoid popping the page before user can share or copy the address
    _delayedTrackingTimer = Timer(
      const Duration(milliseconds: 1600),
      () {
        _logger.info('Starting delayed Lightning Address payment tracking');
        _subscriptions[PaymentTrackingType.lightningAddress] = _subscribeToStream(
          _filteredPaymentsStream(),
        );
      },
    );
  }

  void _startLightningInvoiceTracking(String destination) {
    _logger.info('Starting Lightning Invoice tracking for: $destination');
    _trackDirectPayment(destination, PaymentType.receive);
  }

  void _startBitcoinPaymentTracking(String destination) {
    _logger.info('Starting Bitcoin Payment tracking for: $destination');
    _subscriptions[PaymentTrackingType.bitcoinTransaction] = _subscribeToStream(
      _filteredPaymentsStream(isBitcoin: true),
    );
  }

  /// Track a payment directly using the SDK events
  void _trackDirectPayment(String destination, PaymentType paymentType) {
    final String direction = paymentType == PaymentType.receive ? 'Incoming' : 'Outgoing';
    _logger.info('$direction payment tracking started for: $destination');

    final Stream<PaymentEvent> filteredPaymentEventStream = _breezSdkLiquid.paymentEventStream.where(
      (PaymentEvent event) => _isMatchingPayment(event.payment, destination, paymentType),
    );

    _subscriptions[PaymentTrackingType.lightningInvoice] = _subscribeToStream<PaymentEvent>(
      filteredPaymentEventStream,
    );
  }

  void dispose() {
    _resetTrackingState();
  }

  /* Helper Methods */

  /// Stop all payment tracking
  void _resetTrackingState() {
    _logger.info('Stopping all payment tracking');

    // Cancel all subscriptions
    _subscriptions.forEach((_, StreamSubscription<dynamic>? subscription) => subscription?.cancel());
    _subscriptions.updateAll((_, __) => null);

    // Cancel timer
    _delayedTrackingTimer?.cancel();
    _delayedTrackingTimer = null;

    // Reset state
    _currentTrackingType = PaymentTrackingType.none;
    _currentDestination = null;
    _onPaymentReceived = null;
  }

  bool _isMatchingPayment(Payment payment, String destination, PaymentType paymentType) {
    final String paymentDestination = payment.destination ?? '';
    final bool doesDestinationMatch = paymentDestination == destination;

    // For outgoing payments, we only consider payments that are complete
    final bool isPaymentValid = paymentType == PaymentType.receive
        ? (payment.status == PaymentState.pending || payment.status == PaymentState.complete)
        : (payment.status == PaymentState.complete);

    final bool isPaymentOfType = payment.paymentType == paymentType;

    final bool isMatchingPayment = doesDestinationMatch && isPaymentOfType && isPaymentValid;
    if (isMatchingPayment) {
      final String direction = paymentType == PaymentType.receive ? 'Incoming' : 'Outgoing';
      _logger.info(
        '$direction payment detected! Destination: ${payment.destination}, Status: ${payment.status}',
      );
    }
    return isMatchingPayment;
  }

  /// Creates a filtered stream of payments
  Stream<PaymentData> _filteredPaymentsStream({bool isBitcoin = false}) {
    final StreamController<PaymentData> controller = StreamController<PaymentData>();
    _paymentsCubit.stream
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
        .cast<PaymentData>()
        .listen(
      (PaymentData payment) {
        final String paymentType = isBitcoin ? 'Bitcoin' : 'Lightning Address';
        _logger.info(
          '$paymentType Payment Received! Id: ${payment.id}, Status: ${payment.status}',
        );
        controller.add(payment);
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    return controller.stream;
  }

  StreamSubscription<T> _subscribeToStream<T>(Stream<T> stream) {
    return stream.listen(
      (_) => _onPaymentReceived?.call(true),
      onError: (Object error) {
        _logger.warning('Payment tracking error', error);
        _onPaymentReceived?.call(false);
      },
    );
  }

  bool _isValidDestination(String? destination) => destination?.isNotEmpty == true;
}
