import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme.dart';

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
              style: textStyle,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: BlocBuilder<CurrencyCubit, CurrencyState>(
                builder: (context, currencyState) {
                  return Text(
                    currencyState.bitcoinCurrency.format(account.balance),
                    style: textStyle,
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
