import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/services/services.dart';

/// Service responsible for tracking payments of various types
class PaymentTrackingService {
  final BreezSDKLiquid _breezSdkLiquid;
  final PaymentsCubit _paymentsCubit;

  // Helper components
  late final PaymentStreamFactory _streamFactory;
  StreamSubscription<dynamic>? _activeSubscription;

  PaymentTrackingService(this._breezSdkLiquid, this._paymentsCubit) {
    _streamFactory = PaymentStreamFactory(_breezSdkLiquid, _paymentsCubit);
  }

  /// Start tracking payments based on the provided configuration
  Future<void> startTracking({required PaymentTrackingConfig config}) async {
    if (config.isValid) {
      _resetTrackingState();
      _activeSubscription = await _streamFactory.subscribeToStream(config);
    }
  }

  /// Clean up resources and stop tracking
  void dispose() {
    _resetTrackingState();
    _streamFactory.dispose();
  }

  void _resetTrackingState() {
    _activeSubscription?.cancel();
    _activeSubscription = null;
  }
}
