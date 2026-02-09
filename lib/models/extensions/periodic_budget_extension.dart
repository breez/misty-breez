import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/utils/utils.dart';

extension PeriodicBudgetRequestBuilder on PeriodicBudgetRequest {
  static PeriodicBudgetRequest? fromSats({required int? maxBudgetSat, int? renewalIntervalMins}) {
    if (maxBudgetSat == null) {
      return null;
    }
    return PeriodicBudgetRequest(
      maxBudgetSat: BigInt.from(maxBudgetSat),
      renewalTimeMins: renewalIntervalMins != null && renewalIntervalMins > 0 ? renewalIntervalMins : null,
    );
  }
}

extension PeriodicBudgetExtension on PeriodicBudget {
  /// Renewal interval in days, computed from (renewsAt - updatedAt) in seconds.
  int? get renewalIntervalDays {
    if (renewsAt == null) {
      return null;
    }
    return ((renewsAt! - updatedAt) / 60 / TimeConstants.minutesPerDay).round();
  }
}
