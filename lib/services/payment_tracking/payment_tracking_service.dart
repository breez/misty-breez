import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/services/services.dart';

final Logger _logger = Logger('PaymentTrackingService');

/// Service responsible for tracking payments of various types
class PaymentTrackingService {
  final BreezSDKLiquid _breezSdkLiquid;

  StreamSubscription<Payment>? _activeSubscription;

  PaymentTrackingService(this._breezSdkLiquid);

  /// Start tracking payments based on the provided configuration
  Future<void> startTracking({required PaymentTrackingConfig config}) async {
    dispose();
    if (config is ReceivePaymentTrackingConfig && config.trackingDelay != Duration.zero) {
      await Future<void>.delayed(config.trackingDelay);
    }

    _logger.info('Tracking ${config.infoMessage}');
    _activeSubscription = _breezSdkLiquid.paymentEventStream
        .where((PaymentEvent event) => event.payment.matches(config))
        .map((PaymentEvent e) => e.payment)
        .listen(
      (Payment payment) {
        _logger.info(config.successMessage(payment));
        config.onPaymentComplete(true);
        _activeSubscription?.cancel();
      },
      onError: (Object error) {
        _logger.warning('Failed to track payment.', error);
        config.onPaymentComplete(false);
      },
    );
  }

  /// Clean up resources and stop tracking
  void dispose() => _activeSubscription?.cancel();
}
