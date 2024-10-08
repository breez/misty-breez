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

    if (feesSat == 0) {
      return texts.qr_code_dialog_warning_message;
    }
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    // TODO: https://github.com/breez/Breez-Translations/issues/39 - This is a quick workaround as placeholder
    return texts
        .qr_code_dialog_warning_message_with_lsp(
          currencyState.bitcoinCurrency.format(feesSat),
          currencyState.fiatConversion()?.format(feesSat) ?? "",
        )
        .replaceAll(" setup", "");
  }
}
