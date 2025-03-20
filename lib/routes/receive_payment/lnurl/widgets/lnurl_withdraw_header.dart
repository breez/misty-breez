import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/theme/src/theme.dart';
import 'package:misty_breez/utils/utils.dart';

class LnWithdrawHeader extends StatefulWidget {
  final String callback;
  final int amountSat;
  final String errorMessage;

  const LnWithdrawHeader({
    required this.callback,
    required this.amountSat,
    required this.errorMessage,
    super.key,
  });

  @override
  State<LnWithdrawHeader> createState() => _LnWithdrawHeaderState();
}

class _LnWithdrawHeaderState extends State<LnWithdrawHeader> {
  bool _showFiatCurrency = false;

  @override
  Widget build(BuildContext context) {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;

    final ThemeData themeData = Theme.of(context);

    FiatConversion? fiatConversion;
    if (currencyState.fiatEnabled) {
      fiatConversion = FiatConversion(currencyState.fiatCurrency!, currencyState.fiatExchangeRate!);
    }

    final Uri uri = Uri.parse(widget.callback);
    final String domain = uri.host;
    return Center(
      child: Column(
        children: <Widget>[
          Text(
            'Redeeming funds from',
            style: themeData.primaryTextTheme.displaySmall!.copyWith(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            domain,
            style: themeData.primaryTextTheme.headlineMedium!.copyWith(
              fontSize: 18,
              color: Colors.white,
            ),
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
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: balanceAmountTextStyle.copyWith(
                    color: themeData.colorScheme.onSurface,
                  ),
                  text: _showFiatCurrency && fiatConversion != null
                      ? fiatConversion.format(
                          widget.amountSat,
                          addCurrencySymbol: false,
                          includeDisplayName: true,
                        )
                      : currencyState.bitcoinCurrency.format(
                          widget.amountSat,
                          removeTrailingZeros: true,
                          includeDisplayName: false,
                        ),
                  children: <InlineSpan>[
                    TextSpan(
                      text: _showFiatCurrency && fiatConversion != null
                          ? ''
                          : ' ${currencyState.bitcoinCurrency.displayName}',
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
              fiatConversion.format(
                widget.amountSat,
                addCurrencySymbol: false,
                includeDisplayName: true,
              ),
              style: balanceFiatConversionTextStyle.copyWith(
                fontSize: 18.0,
                color: themeData.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
           */
          if (widget.errorMessage.isNotEmpty) ...<Widget>[
            AutoSizeText(
              widget.errorMessage,
              textAlign: TextAlign.center,
              style: themeData.primaryTextTheme.displaySmall?.copyWith(
                fontSize: 18.0,
                color: themeData.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
