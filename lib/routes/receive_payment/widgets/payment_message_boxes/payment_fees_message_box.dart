import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';

class PaymentFeesMessageBox extends StatelessWidget {
  final int feesSat;
  final bool isBitcoinPayment;

  const PaymentFeesMessageBox({required this.feesSat, this.isBitcoinPayment = false, super.key});

  @override
  Widget build(BuildContext context) {
    return PaymentInfoMessageBox(message: _formatFeesMessage(context, feesSat));
  }

  String _formatFeesMessage(BuildContext context, int feesSat) {
    final BreezTranslations texts = context.texts();

    final PermissionsCubit permissionsCubit = context.read<PermissionsCubit>();
    final bool hasNotificationPermission = permissionsCubit.state.hasNotificationPermission;
    final String warningMessage = hasNotificationPermission ? '' : ' ${texts.payment_fees_warning_message}';

    if (feesSat == 0) {
      return warningMessage.trim();
    }

    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;
    final String formattedFees = currencyState.bitcoinCurrency.format(feesSat);
    final FiatConversion? fiatConversion = currencyState.fiatConversion();

    final String feeText = fiatConversion == null
        ? formattedFees
        : '$formattedFees (${fiatConversion.format(feesSat)})';

    final String paymentType = isBitcoinPayment ? 'payment request' : 'invoice';

    // TODO(erdemyerebasmaz): Add message to Breez-Translations
    return 'A fee of $feeText is applied to this $paymentType.$warningMessage';
  }
}
