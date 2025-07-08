import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';

class SenderAmount extends StatelessWidget {
  final int amountSat;
  final String? title;

  const SenderAmount({required this.amountSat, this.title, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);
    final MinFontSize minFont = MinFontSize(context);

    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          AutoSizeText(
            // TODO(erdemyerebasmaz): Add message to Breez-Translations
            title ?? 'To send:',
            style: themeData.primaryTextTheme.headlineMedium?.copyWith(fontSize: 18.0, color: Colors.white),
            maxLines: 1,
            minFontSize: minFont.minFontSize,
            stepGranularity: 0.1,
            overflow: TextOverflow.ellipsis,
            group: feeBreakDownLabelGroup,
          ),
          const SizedBox(width: 8.0),
          BlocBuilder<CurrencyCubit, CurrencyState>(
            builder: (BuildContext context, CurrencyState currency) {
              final FiatConversion? fiatConversion = currency.fiatConversion();

              return Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: AutoSizeText(
                    fiatConversion == null
                        ? texts.sweep_all_coins_amount_no_fiat(BitcoinCurrency.sat.format(amountSat))
                        : texts.sweep_all_coins_amount_with_fiat(
                            BitcoinCurrency.sat.format(amountSat),
                            fiatConversion.format(amountSat),
                          ),
                    style: themeData.primaryTextTheme.displaySmall!.copyWith(
                      fontSize: 18.0,
                      color: themeData.colorScheme.error,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    minFontSize: minFont.minFontSize,
                    stepGranularity: 0.1,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
