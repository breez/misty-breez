import 'package:breez_translations/generated/breez_translations.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('PaymentValidator');

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
    _logger.info('Validating for $amount and $outgoing');
    try {
      validatePayment(amount, outgoing);
    } on Exception catch (e) {
      return _handleException(e);
    }

    return null;
  }

  String _handleException(Exception e) {
    _logger.warning('Failed to validate payment.', e);
    if (e is PaymentExceededLimitError) {
      return texts.invoice_payment_validator_error_payment_exceeded_limit(
        currency.format(e.limitSat.toInt()),
      );
    } else if (e is PaymentBelowLimitError) {
      return texts.invoice_payment_validator_error_payment_below_invoice_limit(
        currency.format(e.limitSat.toInt()),
      );
    } else if (e is PaymentBelowReserveError) {
      return texts.invoice_payment_validator_error_payment_below_limit(currency.format(e.reserveAmount));
    } else if (e is PaymentExceededLiquidityError) {
      return 'Insufficient inbound liquidity (${currency.format(e.limitSat.toInt())})';
    } else if (e is InsufficientLocalBalanceError) {
      return texts.invoice_payment_validator_error_insufficient_local_balance;
    } else if (e is PaymentBelowSetupFeesError) {
      return texts.invoice_payment_validator_error_payment_below_setup_fees_error(
        currency.format(e.setupFees),
      );
    } else if (e is PaymentExceededLiquidityChannelCreationNotPossibleError) {
      return texts.lnurl_fetch_invoice_error_max(currency.format(e.limitSat.toInt()));
    } else if (e is NoChannelCreationZeroLiquidityError) {
      return texts.lsp_error_cannot_open_channel;
    } else {
      return texts.invoice_payment_validator_error_unknown(extractExceptionMessage(e, texts));
    }
  }
}
