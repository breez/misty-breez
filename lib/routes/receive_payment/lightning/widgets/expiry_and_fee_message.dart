import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/warning_box.dart';

class ExpiryAndFeeMessage extends StatelessWidget {
  final int feesSat;

  const ExpiryAndFeeMessage({super.key, required this.feesSat});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return BlocBuilder<CurrencyCubit, CurrencyState>(
      builder: (context, currencyState) {
        return WarningBox(
          boxPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          backgroundColor: themeData.isLightTheme ? const Color(0xFFf3f8fc) : null,
          borderColor: themeData.isLightTheme ? const Color(0xFF0085fb) : null,
          child: Text(
            (feesSat != 0)
                ? texts
                    .qr_code_dialog_warning_message_with_lsp(
                      currencyState.bitcoinCurrency.format(feesSat),
                      currencyState.fiatConversion()?.format(feesSat) ?? "",
                    )
                    .replaceAll(" setup", "")
                : texts.qr_code_dialog_warning_message,
            textAlign: TextAlign.center,
            style: themeData.primaryTextTheme.bodySmall,
          ),
        );
      },
    );
  }
}
