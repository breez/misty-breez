import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:shimmer/shimmer.dart';

class PlaceholderBalanceText extends StatefulWidget {
  final double offsetFactor;
  const PlaceholderBalanceText({super.key, required this.offsetFactor});

  @override
  State<PlaceholderBalanceText> createState() => PlaceholderBalanceTextState();
}

class PlaceholderBalanceTextState extends State<PlaceholderBalanceText> {
  double get startSize => balanceAmountTextStyle.fontSize!;
  double get endSize => startSize - 8.0;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final currencyState = context.read<CurrencyCubit>().state;

    return Shimmer.fromColors(
      baseColor: themeData.colorScheme.onSecondary,
      highlightColor: themeData.customData.paymentListBgColor.withOpacity(0.5),
      enabled: true,
      child: TextButton(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if ({WidgetState.focused, WidgetState.hovered}.any(states.contains)) {
                return themeData.customData.paymentListBgColor;
              }
              return null;
            },
          ),
        ),
        onPressed: () {},
        child: RichText(
          text: TextSpan(
            style: balanceAmountTextStyle.copyWith(
              color: themeData.colorScheme.onSecondary,
              fontSize: startSize - (startSize - endSize) * widget.offsetFactor,
            ),
            text: currencyState.bitcoinCurrency.format(
              0,
              removeTrailingZeros: true,
              includeDisplayName: false,
            ),
            children: [
              TextSpan(
                text: " ${currencyState.bitcoinCurrency.displayName}",
                style: balanceCurrencyTextStyle.copyWith(
                  color: themeData.colorScheme.onSecondary,
                  fontSize: startSize * 0.6 - (startSize * 0.6 - endSize) * widget.offsetFactor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
