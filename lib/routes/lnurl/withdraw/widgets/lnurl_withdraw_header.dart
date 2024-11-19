import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:l_breez/utils/fiat_conversion.dart';

class LnWithdrawHeader extends StatefulWidget {
  final String callback;
  final int amountSat;
  final String errorMessage;

  const LnWithdrawHeader({
    super.key,
    required this.callback,
    required this.amountSat,
    required this.errorMessage,
  });

  @override
  State<LnWithdrawHeader> createState() => _LnWithdrawHeaderState();
}

class _LnWithdrawHeaderState extends State<LnWithdrawHeader> {
  bool _showFiatCurrency = false;

  @override
  Widget build(BuildContext context) {
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    final themeData = Theme.of(context);

    FiatConversion? fiatConversion;
    if (currencyState.fiatEnabled) {
      fiatConversion = FiatConversion(currencyState.fiatCurrency!, currencyState.fiatExchangeRate!);
    }

    final uri = Uri.parse(widget.callback);
    final domain = uri.host;
    return Center(
      child: Column(
        children: <Widget>[
          Text(
            "Redeeming funds from",
            style: themeData.primaryTextTheme.displaySmall!.copyWith(fontSize: 16, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          Text(
            domain,
            style: Theme.of(context)
                .primaryTextTheme
                .headlineMedium!
                .copyWith(fontSize: 16, color: Colors.white),
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
                      fiatConversion.format(widget.amountSat),
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
                          widget.amountSat,
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
