import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/bloc/user_profile/user_profile_bloc.dart';
import 'package:l_breez/bloc/user_profile/user_profile_state.dart';
import 'package:l_breez/models/user_profile.dart';
import 'package:l_breez/routes/home/widgets/drawer/breez_navigation_drawer.dart';
import 'package:l_breez/widgets/flushbar.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => HomeDrawerState();
}

class HomeDrawerState extends State<HomeDrawer> {
  // TODO: Liquid - Hide Fiat Currency route until it's supported on Liquid SDK
  final Set<String> _hiddenRoutes = {"/fiat_currency"};
  final List<DrawerItemConfig> _screens = [
    const DrawerItemConfig("breezHome", "Misty Breez", ""),
  ];
  final Map<String, Widget> _screenBuilders = {};

  String _activeScreen = "breezHome";

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, user) {
        final settings = user.profileSettings;

        return BreezNavigationDrawer(
          [
            ...[
              DrawerItemConfigGroup([
                DrawerItemConfig(
                  "",
                  texts.home_drawer_item_title_balance,
                  "src/icon/balance.png",
                  isSelected: settings.appMode == AppMode.balance,
                  onItemSelected: (_) {
                    // TODO add protectAdminAction
                  },
                )
              ]),
            ],
            DrawerItemConfigGroup(
              _filterItems(_drawerConfigToFilter()),
              groupTitle: texts.home_drawer_item_title_preferences,
              groupAssetImage: "",
              isExpanded: settings.expandPreferences,
            ),
          ],
          (screenName) {
            if (_screens.map((sc) => sc.name).contains(screenName)) {
              setState(() {
                _activeScreen = screenName;
              });
            } else {
              Navigator.of(context).pushNamed(screenName).then((message) {
                if (message != null && message is String) {
                  showFlushbar(context, message: message);
                }
              });
            }
          },
        );
      },
    );
  }

  List<DrawerItemConfig> _drawerConfigToFilter() {
    final texts = context.texts();
    return [
      DrawerItemConfig(
        "/fiat_currency",
        texts.home_drawer_item_title_fiat_currencies,
        "src/icon/fiat_currencies.png",
      ),
      DrawerItemConfig(
        "/security",
        texts.home_drawer_item_title_security_and_backup,
        "src/icon/security.png",
      ),
      ..._drawerConfigAdvancedFlavorItems(),
    ];
  }

  List<DrawerItemConfig> _drawerConfigAdvancedFlavorItems() {
    final texts = context.texts();
    return [
      DrawerItemConfig(
        "/developers",
        texts.home_drawer_item_title_developers,
        "src/icon/developers.png",
      ),
    ];
  }

  List<DrawerItemConfig> _filterItems(List<DrawerItemConfig> items) {
    return items.where((c) => !_hiddenRoutes.contains(c.name)).toList();
  }

  Widget? screen() {
    return _screenBuilders[_activeScreen];
  }
}
