import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/theme/src/theme.dart';
import 'package:misty_breez/utils/utils.dart';

class LnPaymentHeader extends StatefulWidget {
  final String payeeName;
  final int totalAmount;
  final String errorMessage;

  const LnPaymentHeader({
    required this.payeeName,
    required this.totalAmount,
    required this.errorMessage,
    super.key,
  });

  @override
  State<LnPaymentHeader> createState() => _LnPaymentHeaderState();
}

class _LnPaymentHeaderState extends State<LnPaymentHeader> {
  @override
  Widget build(BuildContext context) {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;

    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    FiatConversion? fiatConversion;
    if (currencyState.fiatEnabled) {
      fiatConversion = FiatConversion(currencyState.fiatCurrency!, currencyState.fiatExchangeRate!);
    }

    return Center(
      child: Column(
        children: <Widget>[
          Text(
            widget.payeeName,
            style: themeData.primaryTextTheme.headlineMedium!.copyWith(
              fontSize: 18,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            widget.payeeName.isEmpty
                ? texts.payment_request_dialog_requested
                : texts.payment_request_dialog_requesting,
            style: themeData.primaryTextTheme.displaySmall!.copyWith(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
            ),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: balanceAmountTextStyle.copyWith(
                  color: themeData.colorScheme.onSurface,
                ),
                text: currencyState.bitcoinCurrency.format(
                  widget.totalAmount,
                  removeTrailingZeros: true,
                  includeDisplayName: false,
                ),
                children: <InlineSpan>[
                  TextSpan(
                    text: ' ${currencyState.bitcoinCurrency.displayName}',
                    style: balanceCurrencyTextStyle.copyWith(
                      color: themeData.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (fiatConversion != null) ...<Widget>[
            AutoSizeText(
              fiatConversion.format(
                widget.totalAmount,
                addCurrencySymbol: false,
                includeDisplayName: true,
              ),
              style: balanceFiatConversionTextStyle.copyWith(
                fontSize: 18.0,
                color: themeData.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (widget.errorMessage.isNotEmpty) ...<Widget>[
            AutoSizeText(
              widget.errorMessage,
              textAlign: TextAlign.center,
              style: themeData.primaryTextTheme.displaySmall?.copyWith(
                fontSize: 18,
                color: themeData.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
