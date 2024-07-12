import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

class LnUrlState {
  final LightningPaymentLimitsResponse? limits;

  LnUrlState({this.limits});

  LnUrlState.initial() : this();

  LnUrlState copyWith({
    LightningPaymentLimitsResponse? limits,
  }) {
    return LnUrlState(
      limits: limits ?? this.limits,
    );
  }
}
