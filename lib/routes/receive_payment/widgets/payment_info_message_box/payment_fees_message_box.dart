import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/receive_payment/widgets/payment_info_message_box/payment_info_message_box.dart';

class PaymentFeesMessageBox extends StatelessWidget {
  final int feesSat;

  const PaymentFeesMessageBox({
    super.key,
    required this.feesSat,
  });

  @override
  Widget build(BuildContext context) {
    return PaymentInfoMessageBox(message: _formatFeesMessage(context, feesSat));
  }

  String _formatFeesMessage(BuildContext context, int feesSat) {
    final texts = context.texts();

    if (feesSat == 0) return texts.payment_fees_warning_message;

    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;
    final formattedFees = currencyState.bitcoinCurrency.format(feesSat);
    final fiatConversion = currencyState.fiatConversion();
    if (fiatConversion == null) {
      return texts.payment_fees_message(formattedFees);
    } else {
      return texts.payment_fees_message_with_fiat(
        formattedFees,
        fiatConversion.format(feesSat),
      );
    }
  }
}
