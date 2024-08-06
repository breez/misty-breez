import 'package:breez_translations/generated/breez_translations.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/cubit/payments/models/models.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:logging/logging.dart';

final _log = Logger("PaymentValidator");

class PaymentValidator {
  final BitcoinCurrency currency;
  final void Function(int amount, bool outgoing) validatePayment;
  final BreezTranslations texts;

  const PaymentValidator({
    required this.validatePayment,
    required this.currency,
    required this.texts,
  });

  String? validateIncoming(int amount) {
    return _validate(amount, false);
  }

  String? validateOutgoing(int amount) {
    return _validate(amount, true);
  }

  String? _validate(int amount, bool outgoing) {
    _log.info("Validating for $amount and $outgoing");
    try {
      validatePayment(amount, outgoing);
    } on PaymentExceededLimitError catch (e) {
      _log.info("Got PaymentExceededLimitError", e);
      return texts.invoice_payment_validator_error_payment_exceeded_limit(
        currency.format(e.limitSat.toInt()),
      );
    } on PaymentBelowLimitError catch (e) {
      _log.info("Got PaymentBelowLimitError", e);
      return texts.invoice_payment_validator_error_payment_below_invoice_limit(
        currency.format(e.limitSat.toInt()),
      );
    } on PaymentBelowReserveError catch (e) {
      _log.info("Got PaymentBelowReserveError", e);
      return texts.invoice_payment_validator_error_payment_below_limit(
        currency.format(e.reserveAmount),
      );
    } on PaymentExceedededLiquidityError catch (e) {
      return "Insufficient inbound liquidity (${currency.format(e.limitSat.toInt())})";
    } on InsufficientLocalBalanceError {
      return texts.invoice_payment_validator_error_insufficient_local_balance;
    } on PaymentBelowSetupFeesError catch (e) {
      _log.info("Got PaymentBelowSetupFeesError", e);
      return texts.invoice_payment_validator_error_payment_below_setup_fees_error(
        currency.format(e.setupFees),
      );
    } on PaymentExceededLiquidityChannelCreationNotPossibleError catch (e) {
      return texts.lnurl_fetch_invoice_error_max(currency.format(e.limitSat.toInt()));
    } on NoChannelCreationZeroLiquidityError {
      return texts.lsp_error_cannot_open_channel;
    } catch (e) {
      _log.info("Got Generic error", e);
      return texts.invoice_payment_validator_error_unknown(
        extractExceptionMessage(e, texts),
      );
    }

    return null;
  }
}
