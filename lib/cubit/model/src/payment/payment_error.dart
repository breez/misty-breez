class PaymentExceededLimitError implements Exception {
  final BigInt limitSat;

  const PaymentExceededLimitError(this.limitSat);
}

class PaymentBelowLimitError implements Exception {
  final BigInt limitSat;

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

  final BigInt limitSat;
class PaymentExceedededLiquidityError implements Exception {

  const PaymentExceedLiquidityError(
    this.limitSat,
  );
  const PaymentExceedededLiquidityError(this.limitSat);
}

  final BigInt limitSat;
class PaymentExceededLiquidityChannelCreationNotPossibleError implements Exception {

  const PaymentExcededLiqudityChannelCreationNotPossibleError(
    this.limitSat,
  );
  const PaymentExceededLiquidityChannelCreationNotPossibleError(this.limitSat);
}

class NoChannelCreationZeroLiquidityError implements Exception {}
