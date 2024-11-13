import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:l_breez/utils/fiat_conversion.dart';

class LnPaymentHeader extends StatefulWidget {
  final String payeeName;
  final int totalAmount;
  final String errorMessage;

  const LnPaymentHeader({
    super.key,
    required this.payeeName,
    required this.totalAmount,
    required this.errorMessage,
  });

  @override
  State<LnPaymentHeader> createState() => _LnPaymentHeaderState();
}

class _LnPaymentHeaderState extends State<LnPaymentHeader> {
  bool _showFiatCurrency = false;

  @override
  Widget build(BuildContext context) {
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    final texts = context.texts();
    final themeData = Theme.of(context);

    FiatConversion? fiatConversion;
    if (currencyState.fiatEnabled) {
      fiatConversion = FiatConversion(currencyState.fiatCurrency!, currencyState.fiatExchangeRate!);
    }

    return Center(
      child: Column(
        children: <Widget>[
          Text(
            widget.payeeName,
            style: Theme.of(context)
                .primaryTextTheme
                .headlineMedium!
                .copyWith(fontSize: 16, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          Text(
            widget.payeeName.isEmpty
                ? texts.payment_request_dialog_requested
                : texts.payment_request_dialog_requesting,
            style: themeData.primaryTextTheme.displaySmall!.copyWith(fontSize: 16, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPressStart: (_) {
              setState(() {
                _showFiatCurrency = true;
              });
            },
            onLongPressEnd: (_) {
              setState(() {
                _showFiatCurrency = false;
              });
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: double.infinity,
              ),
              child: _showFiatCurrency && fiatConversion != null
                  ? Text(
                      fiatConversion.format(widget.totalAmount),
                      style: balanceAmountTextStyle.copyWith(
                        color: themeData.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : RichText(
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
                        children: [
                          TextSpan(
                            text: " ${currencyState.bitcoinCurrency.displayName}",
                            style: balanceCurrencyTextStyle.copyWith(
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          /*
          if (fiatConversion != null) ...[
            AutoSizeText(
              "≈ ${fiatConversion.format(widget.totalAmount)}",
              style: balanceFiatConversionTextStyle.copyWith(
                color: themeData.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
           */
          if (widget.errorMessage.isNotEmpty) ...[
            AutoSizeText(
              widget.errorMessage,
              textAlign: TextAlign.center,
              style: themeData.primaryTextTheme.displaySmall?.copyWith(
                fontSize: 14.3,
                color: themeData.colorScheme.error,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
