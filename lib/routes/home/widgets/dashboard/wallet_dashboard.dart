import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/bloc/account/account_bloc.dart';
import 'package:l_breez/bloc/account/account_state.dart';
import 'package:l_breez/bloc/currency/currency_bloc.dart';
import 'package:l_breez/bloc/currency/currency_state.dart';
import 'package:l_breez/bloc/user_profile/user_profile_bloc.dart';
import 'package:l_breez/bloc/user_profile/user_profile_state.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/routes/home/widgets/dashboard/fiat_balance_text.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;

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
    final userProfileBloc = context.read<UserProfileBloc>();
    final currencyBloc = context.read<CurrencyBloc>();
    final themeData = Theme.of(context);

    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, currencyState) {
        return BlocBuilder<UserProfileBloc, UserProfileState>(
          builder: (context, userProfileState) {
            final profileSettings = userProfileState.profileSettings;

            return BlocBuilder<AccountBloc, AccountState>(
              builder: (context, accountState) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  child: Stack(
                    alignment: AlignmentDirectional.topCenter,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: widget.height,
                        decoration: BoxDecoration(
                          color: themeData.customData.dashboardBgColor,
                        ),
                      ),
                      Positioned(
                        top: 60 - _kBalanceOffsetTransition * widget.offsetFactor,
                        child: Center(
                          child: !accountState.initial
                              ? TextButton(
                                  style: ButtonStyle(
                                    overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(WidgetState.focused)) {
                                        return themeData.customData.paymentListBgColor;
                                      }
                                      if (states.contains(WidgetState.hovered)) {
                                        return themeData.customData.paymentListBgColor;
                                      }
                                      return null;
                                    }),
                                  ),
                                  onPressed: () {
                                    if (profileSettings.hideBalance == true) {
                                      userProfileBloc.updateProfile(hideBalance: false);
                                      return;
                                    }
                                    final list = BitcoinCurrency.currencies;
                                    final index = list.indexOf(
                                      BitcoinCurrency.fromTickerSymbol(currencyState.bitcoinTicker),
                                    );
                                    final nextCurrencyIndex = (index + 1) % list.length;
                                    if (nextCurrencyIndex == 1) {
                                      userProfileBloc.updateProfile(hideBalance: true);
                                    }
                                    currencyBloc.setBitcoinTicker(list[nextCurrencyIndex].tickerSymbol);
                                  },
                                  child: BalanceText(
                                    userProfileState: userProfileState,
                                    currencyState: currencyState,
                                    accountState: accountState,
                                    offsetFactor: widget.offsetFactor,
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      ),
                      Positioned(
                        top: 100 - _kBalanceOffsetTransition * widget.offsetFactor,
                        child: Center(
                          child: currencyState.fiatEnabled && !profileSettings.hideBalance
                              ? FiatBalanceText(
                                  currencyState: currencyState,
                                  accountState: accountState,
                                  offsetFactor: widget.offsetFactor,
                                )
                              : const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
