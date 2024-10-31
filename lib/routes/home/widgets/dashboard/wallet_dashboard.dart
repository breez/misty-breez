import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/routes/home/widgets/dashboard/fiat_balance_text.dart';
import 'package:l_breez/theme/theme.dart';

import 'balance_text.dart';

const _kBalanceOffsetTransition = 60.0;

class WalletDashboard extends StatefulWidget {
  final double height;
  final double offsetFactor;

  const WalletDashboard({
    super.key,
    required this.height,
    required this.offsetFactor,
  });

  @override
  State<WalletDashboard> createState() => _WalletDashboardState();
}

class _WalletDashboardState extends State<WalletDashboard> {
  @override
  Widget build(BuildContext context) {
    final userProfileCubit = context.read<UserProfileCubit>();
    final currencyCubit = context.read<CurrencyCubit>();
    final themeData = Theme.of(context);

    return BlocBuilder<CurrencyCubit, CurrencyState>(
      builder: (context, currencyState) {
        return BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, userProfileState) {
            final profileSettings = userProfileState.profileSettings;

            return BlocBuilder<AccountCubit, AccountState>(
              builder: (context, accountState) {
                return Stack(
                  alignment: AlignmentDirectional.topCenter,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: themeData.customData.dashboardBgColor,
                      ),
                    ),
                    if (!accountState.isInitial) ...[
                      Positioned(
                        top: 60 - _kBalanceOffsetTransition * widget.offsetFactor,
                        child: Center(
                          child: TextButton(
                            style: ButtonStyle(
                              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                                  if (states.contains(WidgetState.focused)) {
                                    return themeData.customData.paymentListBgColor;
                                  }
                                  if (states.contains(WidgetState.hovered)) {
                                    return themeData.customData.paymentListBgColor;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            onPressed: () {
                              if (profileSettings.hideBalance == true) {
                                userProfileCubit.updateProfile(hideBalance: false);
                                return;
                              }
                              final list = BitcoinCurrency.currencies;
                              final index = list.indexOf(
                                BitcoinCurrency.fromTickerSymbol(currencyState.bitcoinTicker),
                              );
                              final nextCurrencyIndex = (index + 1) % list.length;
                              if (nextCurrencyIndex == 1) {
                                userProfileCubit.updateProfile(hideBalance: true);
                              }
                              currencyCubit.setBitcoinTicker(list[nextCurrencyIndex].tickerSymbol);
                            },
                            child: BalanceText(
                              userProfileState: userProfileState,
                              currencyState: currencyState,
                              accountState: accountState,
                              offsetFactor: widget.offsetFactor,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (currencyState.fiatEnabled && !profileSettings.hideBalance) ...[
                      Positioned(
                        top: 100 - _kBalanceOffsetTransition * widget.offsetFactor,
                        child: Center(
                          child: FiatBalanceText(
                            currencyState: currencyState,
                            accountState: accountState,
                            offsetFactor: widget.offsetFactor,
                          ),
                        ),
                      )
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
