enum WithdrawKind { withdrawFunds, unexpectedFunds }

class WithdrawFundsPolicy {
  final WithdrawKind withdrawKind;
  final BigInt minValue;
  final BigInt maxValue;

  const WithdrawFundsPolicy(this.withdrawKind, this.minValue, this.maxValue);

  @override
  String toString() {
    return 'WithdrawFundsPolicy{withdrawKind: $withdrawKind, minValue: $minValue, maxValue: $maxValue}';
  }
}
