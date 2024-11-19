import 'dart:io';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:l_breez/handlers/handlers.dart';
import 'package:l_breez/routes/home/account_page.dart';
import 'package:l_breez/routes/home/widgets/app_bar/home_app_bar.dart';
import 'package:l_breez/routes/home/widgets/bottom_actions_bar/bottom_actions_bar.dart';
import 'package:l_breez/routes/home/widgets/drawer/home_drawer.dart';
import 'package:l_breez/routes/home/widgets/qr_action_button.dart';
import 'package:l_breez/routes/security/auto_lock_mixin.dart';
import 'package:l_breez/widgets/error_dialog.dart';

class Home extends StatefulWidget {
  static const String routeName = '/';

  const Home({super.key});

  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home> with AutoLockMixin<Home>, HandlerContextProvider<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey firstPaymentItemKey = GlobalKey();
  final ScrollController scrollController = ScrollController();
  final List<Handler> handlers = <Handler>[];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      handlers.addAll(<Handler>[
        InputHandler(firstPaymentItemKey, _scaffoldKey),
        NetworkConnectivityHandler(),
        WalletConnectivityHandler(),
      ]);
      for (Handler handler in handlers) {
        handler.init(this);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    for (Handler handler in handlers) {
      handler.dispose();
    }
    handlers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Size mediaSize = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeData.appBarTheme.systemOverlayStyle!.copyWith(
        systemNavigationBarColor: themeData.bottomAppBarTheme.color,
      ),
      child: PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          if (didPop) {
            return;
          }
          // Only close drawer if it's open
          final NavigatorState navigator = Navigator.of(context);
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            navigator.pop();
            return;
          }

          // If drawer is not open, prompt user to approve exiting the app
          final BreezTranslations texts = context.texts();
          final bool? shouldPop = await promptAreYouSure(
            context,
            texts.close_popup_title,
            Text(texts.close_popup_message),
          );
          if (shouldPop ?? false) {
            exit(0);
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          key: _scaffoldKey,
          appBar: HomeAppBar(themeData: themeData, scaffoldKey: _scaffoldKey),
          drawerDragStartBehavior: DragStartBehavior.down,
          drawerEdgeDragWidth: mediaSize.width,
          drawer: const HomeDrawer(),
          bottomNavigationBar: BottomActionsBar(firstPaymentItemKey),
          floatingActionButton: QrActionButton(firstPaymentItemKey),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          body: AccountPage(firstPaymentItemKey, scrollController),
        ),
      ),
    );
  }
}
