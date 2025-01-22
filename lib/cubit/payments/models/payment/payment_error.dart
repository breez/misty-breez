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

class PaymentBelowReserveError implements Exception {
  final int reserveAmount;

  const PaymentBelowReserveError(this.reserveAmount);

  @override
  String toString() => 'Payment amount is below the reserve amount of $reserveAmount satoshis.';
}

class InsufficientLocalBalanceError implements Exception {
  const InsufficientLocalBalanceError();

  @override
  String toString() => 'Insufficient local balance to process the payment.';
}

class PaymentBelowSetupFeesError implements Exception {
  final int setupFees;

  const PaymentBelowSetupFeesError(this.setupFees);

  @override
  String toString() => 'Payment amount is below the setup fees of $setupFees satoshis.';
}

class PaymentExceededLiquidityError implements Exception {
  final int limitSat;

  const PaymentExceededLiquidityError(this.limitSat);

  @override
  String toString() => 'Payment amount exceeds the available liquidity of $limitSat satoshis.';
}

class PaymentExceededLiquidityChannelCreationNotPossibleError implements Exception {
  final int limitSat;

  const PaymentExceededLiquidityChannelCreationNotPossibleError(this.limitSat);

  @override
  String toString() =>
      'Payment amount exceeds available liquidity of $limitSat satoshis, and channel creation is not possible.';
}

class NoChannelCreationZeroLiquidityError implements Exception {
  @override
  String toString() => 'Channel creation is not possible due to zero liquidity.';
}
