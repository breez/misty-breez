class LnPaymentValidatorUtils {
  String formatLnPaymentValidatorUrl({
    required String invoice,
    required String preimage,
    String lnPaymentValidator = 'https://validate-payment.netlify.app/',
  }) {
    return '$lnPaymentValidator/?invoice=$invoice&preimage=$preimage';
  }
}
