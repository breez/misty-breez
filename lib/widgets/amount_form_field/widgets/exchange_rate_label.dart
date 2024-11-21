import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/utils/fiat_conversion.dart';

class ExchangeRateLabel extends StatelessWidget {
  final ValueNotifier<double?> exchangeRateNotifier;
  final Animation<Color?>? colorAnimation;

  const ExchangeRateLabel({
    required this.exchangeRateNotifier,
    this.colorAnimation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;

    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    final FiatConversion? fiatConversion = currencyState.fiatConversion();

    return ValueListenableBuilder<double?>(
      valueListenable: exchangeRateNotifier,
      builder: (BuildContext context, double? exchangeRate, Widget? child) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              fiatConversion != null
                  ? texts.currency_converter_dialog_rate(
                      fiatConversion.formatFiat(
                        currencyState.fiatExchangeRate!,
                        addCurrencySymbol: false,
                        removeTrailingZeros: true,
                      ),
                      fiatConversion.currencyData.id,
                    )
                  : '',
              style: themeData.primaryTextTheme.titleSmall!.copyWith(
                fontSize: 13.0,
                fontWeight: FontWeight.w400,
                color: colorAnimation?.value,
              ),
            ),
          ),
        );
      },
    );
  }
}
