import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/utils/utils.dart';

class SenderAmount extends StatelessWidget {
  final int amountSat;

  const SenderAmount({required this.amountSat, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);
    final MinFontSize minFont = MinFontSize(context);

    return ListTile(
      title: AutoSizeText(
        texts.sweep_all_coins_label_send,
        maxLines: 1,
        minFontSize: minFont.minFontSize,
        stepGranularity: 0.1,
      ),
      trailing: BlocBuilder<CurrencyCubit, CurrencyState>(
        builder: (BuildContext context, CurrencyState currency) {
          final FiatConversion? fiatConversion = currency.fiatConversion();

          return AutoSizeText(
            fiatConversion == null
                ? texts.sweep_all_coins_amount_no_fiat(
                    BitcoinCurrency.sat.format(amountSat),
                  )
                : texts.sweep_all_coins_amount_with_fiat(
                    BitcoinCurrency.sat.format(amountSat),
                    fiatConversion.format(amountSat),
                  ),
            style: TextStyle(color: themeData.colorScheme.error),
            maxLines: 1,
            minFontSize: minFont.minFontSize,
            stepGranularity: 0.1,
          );
        },
      ),
    );
  }
}
