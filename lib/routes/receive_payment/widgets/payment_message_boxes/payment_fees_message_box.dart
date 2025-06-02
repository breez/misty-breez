import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';

class PaymentFeesMessageBox extends StatelessWidget {
  final int feesSat;

  const PaymentFeesMessageBox({required this.feesSat, super.key});

  @override
  Widget build(BuildContext context) {
    return PaymentInfoMessageBox(message: _formatFeesMessage(context, feesSat));
  }

  String _formatFeesMessage(BuildContext context, int feesSat) {
    final BreezTranslations texts = context.texts();

    if (feesSat == 0) {
      return texts.payment_fees_warning_message;
    }

    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;
    final String formattedFees = currencyState.bitcoinCurrency.format(feesSat);
    final FiatConversion? fiatConversion = currencyState.fiatConversion();
    if (fiatConversion == null) {
      return texts.payment_fees_message(formattedFees);
    } else {
      return texts.payment_fees_message_with_fiat(formattedFees, fiatConversion.format(feesSat));
    }
  }
}
