import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/bloc/currency/currency_bloc.dart';
import 'package:l_breez/bloc/currency/currency_state.dart';
import 'package:l_breez/theme/theme_extensions.dart';
import 'package:l_breez/widgets/warning_box.dart';
import 'package:logging/logging.dart';

final log = Logger("ExpiryAndFeeMessage");

class ExpiryAndFeeMessage extends StatelessWidget {
  final int feesSat;

  const ExpiryAndFeeMessage({
    super.key,
    required this.feesSat,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, currencyState) {
        return WarningBox(
          boxPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          backgroundColor: themeData.isLightTheme ? const Color(0xFFf3f8fc) : null,
          borderColor: themeData.isLightTheme ? const Color(0xFF0085fb) : null,
          child: Text(
            (feesSat != 0)
                ? texts.qr_code_dialog_warning_message_with_lsp(
                    currencyState.bitcoinCurrency.format(feesSat),
                    currencyState.fiatConversion()?.format(feesSat) ?? "",
                  )
                : texts.qr_code_dialog_warning_message,
            textAlign: TextAlign.center,
            style: themeData.primaryTextTheme.bodySmall,
          ),
        );
      },
    );
  }
}
