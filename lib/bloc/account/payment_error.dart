class PaymentExceededLimitError implements Exception {
  final BigInt limitSat;

  const PaymentExceededLimitError(
    this.limitSat,
  );
}

class PaymentBelowLimitError implements Exception {
  final BigInt limitSat;

  const PaymentBelowLimitError(
    this.limitSat,
  );
}

class PaymentBelowReserveError implements Exception {
  final int reserveAmount;

  const PaymentBelowReserveError(
    this.reserveAmount,
  );
}

class InsufficientLocalBalanceError implements Exception {
  const InsufficientLocalBalanceError();
}

class PaymentBelowSetupFeesError implements Exception {
  final int setupFees;

  const PaymentBelowSetupFeesError(
    this.setupFees,
  );
}

class PaymentExceedLiquidityError implements Exception {
  final BigInt limitSat;

  const PaymentExceedLiquidityError(
    this.limitSat,
  );
}

class PaymentExcededLiqudityChannelCreationNotPossibleError implements Exception {
  final BigInt limitSat;

  const PaymentExcededLiqudityChannelCreationNotPossibleError(
    this.limitSat,
  );
}

class NoChannelCreationZeroLiqudityError implements Exception {}
