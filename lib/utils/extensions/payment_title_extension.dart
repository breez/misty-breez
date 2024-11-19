extension PaymentTitleExtension on String {
  // TODO(erdemyerebasmaz): Remove once default descriptions from the SDK is removed
  bool get isDefaultTitleWithLiquidNaming {
    return contains('Send to L-BTC address') || contains('Liquid transfer');
  }
}
