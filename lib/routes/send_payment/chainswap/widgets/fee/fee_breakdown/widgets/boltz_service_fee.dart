import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/utils/utils.dart';

class BoltzServiceFee extends StatelessWidget {
  final int boltzServiceFee;

  const BoltzServiceFee({required this.boltzServiceFee, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);
    final MinFontSize minFontSize = MinFontSize(context);

    return ListTile(
      title: AutoSizeText(
        texts.reverse_swap_confirmation_boltz_fee,
        style: themeData.primaryTextTheme.headlineMedium?.copyWith(
          fontSize: 18.0,
          color: Colors.white.withValues(alpha: .4),
        ),
        maxLines: 1,
        minFontSize: minFontSize.minFontSize,
        stepGranularity: 0.1,
      ),
      trailing: AutoSizeText(
        texts.reverse_swap_confirmation_boltz_fee_value(
          BitcoinCurrency.sat.format(boltzServiceFee),
        ),
        style: themeData.primaryTextTheme.displaySmall!.copyWith(
          fontSize: 18.0,
          color: themeData.colorScheme.error.withValues(alpha: .4),
        ),
        maxLines: 1,
        minFontSize: minFontSize.minFontSize,
        stepGranularity: 0.1,
      ),
    );
  }
}
