import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/home/widgets/dashboard/fiat_balance_text.dart';
import 'package:l_breez/routes/home/widgets/dashboard/placeholder_balance_text.dart';
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
    final themeData = Theme.of(context);

    return BlocBuilder<CurrencyCubit, CurrencyState>(
      builder: (context, currencyState) {
        return BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, userProfileState) {
            return BlocBuilder<AccountCubit, AccountState>(
              builder: (context, accountState) {
                final hiddenBalance = userProfileState.profileSettings.hideBalance;
                final showBalance = !accountState.isRestoring && accountState.walletInfo != null;

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
                    Positioned(
                      top: 60 - _kBalanceOffsetTransition * widget.offsetFactor,
                      child: showBalance
                          ? BalanceText(
                              hiddenBalance: hiddenBalance,
                              currencyState: currencyState,
                              accountState: accountState,
                              offsetFactor: widget.offsetFactor,
                            )
                          : PlaceholderBalanceText(
                              offsetFactor: widget.offsetFactor,
                            ),
                    ),
                    Positioned(
                      top: 100 - _kBalanceOffsetTransition * widget.offsetFactor,
                      child: FiatBalanceText(
                        hiddenBalance: hiddenBalance,
                        currencyState: currencyState,
                        accountState: accountState,
                        offsetFactor: widget.offsetFactor,
                      ),
                    ),
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
