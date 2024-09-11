extension PaymentTitleExtension on String {
  bool get isDefaultTitleWithLiquidNaming {
    return contains("Send to L-BTC address") || contains("Liquid transfer");
  }
}
