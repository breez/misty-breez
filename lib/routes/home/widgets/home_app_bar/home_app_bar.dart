import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';

export 'widgets/widgets.dart';

class HomeAppBar extends AppBar {
  HomeAppBar({
    required ThemeData themeData,
    required GlobalKey<ScaffoldState> scaffoldKey,
    super.key,
  }) : super(
          centerTitle: false,
          actions: <Widget>[
            const Padding(
              padding: EdgeInsets.all(14.0),
              child: AccountRequiredActionsIndicator(),
            ),
          ],
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/icons/hamburger.svg',
              height: 24.0,
              width: 24.0,
              colorFilter: ColorFilter.mode(
                themeData.appBarTheme.actionsIconTheme!.color!,
                BlendMode.srcATop,
              ),
            ),
            onPressed: () => scaffoldKey.currentState?.openDrawer(),
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
