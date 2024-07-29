class PaymentExceededLimitError implements Exception {
  final int limitSat;

  const PaymentExceededLimitError(this.limitSat);
}

class PaymentBelowLimitError implements Exception {
  final int limitSat;

  const PaymentBelowLimitError(this.limitSat);
}

class PaymentBelowReserveError implements Exception {
  final int reserveAmount;

  const PaymentBelowReserveError(this.reserveAmount);
}

class InsufficientLocalBalanceError implements Exception {
  const InsufficientLocalBalanceError();
}

class PaymentBelowSetupFeesError implements Exception {
  final int setupFees;

  const PaymentBelowSetupFeesError(this.setupFees);
}

class PaymentExceedededLiquidityError implements Exception {
  final int limitSat;

  const PaymentExceedededLiquidityError(this.limitSat);
}

class PaymentExceededLiquidityChannelCreationNotPossibleError implements Exception {
  final int limitSat;

  const PaymentExceededLiquidityChannelCreationNotPossibleError(this.limitSat);
}

class NoChannelCreationZeroLiquidityError implements Exception {}
