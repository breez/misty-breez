import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;

import 'account_required_actions.dart';

class HomeAppBar extends AppBar {
  HomeAppBar({
    super.key,
    required ThemeData themeData,
    required GlobalKey<ScaffoldState> scaffoldKey,
  }) : super(
          centerTitle: false,
          actions: [
            const Padding(
              padding: EdgeInsets.all(14.0),
              child: AccountRequiredActionsIndicator(),
            ),
          ],
          leading: IconButton(
            icon: SvgPicture.asset(
              "src/icon/hamburger.svg",
              height: 24.0,
              width: 24.0,
              colorFilter: ColorFilter.mode(
                themeData.appBarTheme.actionsIconTheme!.color!,
                BlendMode.srcATop,
              ),
            ),
            onPressed: () => scaffoldKey.currentState?.openDrawer(),
          ),
          title: IconButton(
            padding: EdgeInsets.zero,
            icon: SvgPicture.asset(
              "src/images/cloud-logo-color.svg",
              colorFilter: ColorFilter.mode(
                themeData.appBarTheme.actionsIconTheme!.color!,
                BlendMode.srcATop,
              ),
            ),
            iconSize: 64,
            onPressed: () => scaffoldKey.currentState?.openDrawer(),
          ),
          iconTheme: const IconThemeData(
            color: Color.fromARGB(255, 0, 133, 251),
          ),
          backgroundColor: themeData.customData.dashboardBgColor,
          systemOverlayStyle: themeData.isLightTheme
              ? themeData.appBarTheme.systemOverlayStyle!.copyWith(
                  statusBarBrightness: Brightness.light, // iOS
                  statusBarIconBrightness: Brightness.dark, // Android
                )
              : themeData.appBarTheme.systemOverlayStyle!,
        );
}
