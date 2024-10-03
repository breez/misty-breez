import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/user_profile.dart';
import 'package:l_breez/routes/dev/developers_view.dart';
import 'package:l_breez/routes/fiat_currencies/fiat_currency_settings.dart';
import 'package:l_breez/routes/home/widgets/drawer/breez_navigation_drawer.dart';
import 'package:l_breez/routes/refund/get_refund_page.dart';
import 'package:l_breez/routes/security/security_page.dart';
import 'package:l_breez/widgets/flushbar.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return BlocBuilder<UserProfileCubit, UserProfileState>(
      builder: (context, user) {
        final settings = user.profileSettings;

        return BlocBuilder<RefundCubit, RefundState>(
          builder: (context, refundState) {
            final hasRefundables = refundState.refundables?.isNotEmpty ?? false;

            return BreezNavigationDrawer(
              [
                if (hasRefundables) ...[
                  DrawerItemConfigGroup(
                    [
                      DrawerItemConfig(
                        GetRefundPage.routeName,
                        texts.home_drawer_item_title_get_refund,
                        "assets/icons/get_refund.png",
                      ),
                    ],
                  ),
                ],
                DrawerItemConfigGroup([
                  DrawerItemConfig(
                    "",
                    texts.home_drawer_item_title_balance,
                    "assets/icons/balance.png",
                    isSelected: settings.appMode == AppMode.balance,
                    onItemSelected: (_) {
                      // TODO add protectAdminAction
                    },
                  )
                ]),
                DrawerItemConfigGroup(
                  [
                    DrawerItemConfig(
                      FiatCurrencySettings.routeName,
                      texts.home_drawer_item_title_fiat_currencies,
                      "assets/icons/fiat_currencies.png",
                    ),
                    DrawerItemConfig(
                      SecurityPage.routeName,
                      texts.home_drawer_item_title_security_and_backup,
                      "assets/icons/security.png",
                    ),
                    DrawerItemConfig(
                      DevelopersView.routeName,
                      texts.home_drawer_item_title_developers,
                      "assets/icons/developers.png",
                    ),
                  ],
                  groupTitle: texts.home_drawer_item_title_preferences,
                  groupAssetImage: "",
                  isExpanded: settings.expandPreferences,
                ),
              ],
              (routeName) {
                Navigator.of(context).pushNamed(routeName).then(
                  (message) {
                    if (message != null && message is String && context.mounted) {
                      showFlushbar(context, message: message);
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
