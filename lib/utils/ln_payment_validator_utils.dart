class LnPaymentValidatorUtils {
  String formatLnPaymentValidatorUrl({
    required String invoice,
    required String preimage,
    String lnPaymentValidator = 'https://validate-payment.com/',
  }) {
    return '$lnPaymentValidator/?invoice=$invoice&preimage=$preimage';
  }
}
