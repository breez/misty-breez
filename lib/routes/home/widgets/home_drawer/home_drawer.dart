import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/widgets.dart';

export 'widgets/widgets.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return BlocBuilder<UserProfileCubit, UserProfileState>(
      builder: (BuildContext context, UserProfileState user) {
        final UserProfileSettings settings = user.profileSettings;

        return BlocBuilder<RefundCubit, RefundState>(
          builder: (BuildContext context, RefundState refundState) {
            return BreezNavigationDrawer(
              <DrawerItemConfigGroup>[
                if (refundState.hasRefundables) ...<DrawerItemConfigGroup>[
                  DrawerItemConfigGroup(<DrawerItemConfig>[
                    DrawerItemConfig(
                      GetRefundPage.routeName,
                      texts.home_drawer_item_title_get_refund,
                      'assets/icons/get_refund.png',
                    ),
                  ]),
                ],
                DrawerItemConfigGroup(<DrawerItemConfig>[
                  DrawerItemConfig(
                    '',
                    texts.home_drawer_item_title_balance,
                    'assets/icons/balance.png',
                    isSelected: settings.appMode == AppMode.balance,
                    onItemSelected: (_) {
                      // TODO(ademar111190): add protectAdminAction
                    },
                  ),
                ]),
                DrawerItemConfigGroup(
                  <DrawerItemConfig>[
                    const DrawerItemConfig(NwcPage.routeName, 'Nostr Wallet Connect', 'assets/icons/nwc.png'),
                    DrawerItemConfig(
                      FiatCurrencySettings.routeName,
                      texts.home_drawer_item_title_fiat_currencies,
                      'assets/icons/fiat_currencies.png',
                    ),
                    DrawerItemConfig(
                      SecuritySettings.routeName,
                      texts.home_drawer_item_title_security_and_backup,
                      'assets/icons/security.png',
                    ),
                    DrawerItemConfig(
                      DevelopersView.routeName,
                      texts.home_drawer_item_title_developers,
                      'assets/icons/developers.png',
                    ),
                  ],
                  groupTitle: texts.home_drawer_item_title_preferences,
                  groupAssetImage: '',
                  isExpanded: settings.expandPreferences,
                ),
              ],
              (String routeName) {
                Navigator.of(context).pushNamed(routeName).then((Object? message) {
                  if (message != null && message is String && context.mounted) {
                    showFlushbar(context, message: message);
                  }
                });
              },
            );
          },
        );
      },
    );
  }
}
