import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';

export 'widgets/widgets.dart';

const double _kBalanceOffsetTransition = 60.0;

class WalletDashboard extends StatefulWidget {
  final double height;
  final double offsetFactor;

  const WalletDashboard({
    required this.height,
    required this.offsetFactor,
    super.key,
  });

  @override
  State<WalletDashboard> createState() => _WalletDashboardState();
}

class _WalletDashboardState extends State<WalletDashboard> {
  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return BlocBuilder<CurrencyCubit, CurrencyState>(
      builder: (BuildContext context, CurrencyState currencyState) {
        return BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (BuildContext context, UserProfileState userProfileState) {
            return BlocBuilder<AccountCubit, AccountState>(
              builder: (BuildContext context, AccountState accountState) {
                final bool hiddenBalance = userProfileState.profileSettings.hideBalance;
                final bool showBalance = !accountState.isRestoring && accountState.walletInfo != null;

                return Stack(
                  alignment: AlignmentDirectional.topCenter,
                  children: <Widget>[
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
