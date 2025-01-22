class PaymentExceededLimitError implements Exception {
  final int limitSat;

  const PaymentExceededLimitError(this.limitSat);

  @override
  String toString() => 'Payment amount exceeds the limit of $limitSat satoshis.';
}

class PaymentBelowLimitError implements Exception {
  final int limitSat;

  const PaymentBelowLimitError(this.limitSat);

  @override
  String toString() => 'Payment amount is below the minimum limit of $limitSat satoshis.';
}

class InsufficientLocalBalanceError implements Exception {
  const InsufficientLocalBalanceError();

  @override
  String toString() => 'Insufficient local balance to process the payment.';
}
