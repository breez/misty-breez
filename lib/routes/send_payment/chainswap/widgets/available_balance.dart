import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/theme/theme.dart';

class AvailableBalance extends StatelessWidget {
  const AvailableBalance({super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Padding(
      padding: const EdgeInsets.only(top: 36.0),
      child: BlocBuilder<AccountCubit, AccountState>(
        builder: (BuildContext context, AccountState account) {
          return Row(
            children: <Widget>[
              Text(texts.available_balance_label, style: textStyle),
              Padding(
                padding: const EdgeInsets.only(left: 3.0),
                child: BlocBuilder<CurrencyCubit, CurrencyState>(
                  builder: (BuildContext context, CurrencyState currencyState) {
                    return Text(
                      currencyState.bitcoinCurrency.format(account.walletInfo!.balanceSat.toInt()),
                      style: textStyle,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
