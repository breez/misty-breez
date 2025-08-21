class PaymentTrackingConfig {
  final String? expectedDestination;
  final String? lnAddress;
  final bool isBitcoinPayment;

  const PaymentTrackingConfig({this.expectedDestination, this.lnAddress, this.isBitcoinPayment = false});
}
