import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/account/account_cubit.dart';
import 'package:l_breez/cubit/account/account_state.dart';
import 'package:l_breez/cubit/currency/currency_cubit.dart';
import 'package:l_breez/cubit/currency/currency_state.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;

class WithdrawFundsAvailableBtc extends StatelessWidget {
  const WithdrawFundsAvailableBtc({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Padding(
      padding: const EdgeInsets.only(top: 36.0),
      child: BlocBuilder<AccountCubit, AccountState>(builder: (context, account) {
        return Row(
          children: [
            Text(
              texts.withdraw_funds_balance,
              style: theme.textStyle,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: BlocBuilder<CurrencyCubit, CurrencyState>(
                builder: (context, currencyState) {
                  return Text(
                    currencyState.bitcoinCurrency.format(account.balance),
                    style: theme.textStyle,
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
