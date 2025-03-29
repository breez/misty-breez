import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;

class ReceivePaymentPage extends StatefulWidget {
  static const String routeName = '/receive_payment';
  final int initialPageIndex;

  const ReceivePaymentPage({required this.initialPageIndex, super.key});

  @override
  State<ReceivePaymentPage> createState() => _ReceivePaymentPageState();
}

class _ReceivePaymentPageState extends State<ReceivePaymentPage> {
  static const List<StatefulWidget> pages = <StatefulWidget>[
    ReceiveLightningPaymentPage(),
    ReceiveLightningAddressPage(),
    ReceiveBitcoinAddressPaymentPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final PermissionStatus notificationStatus = context.select<PermissionsCubit, PermissionStatus>(
      (PermissionsCubit cubit) => cubit.state.notificationStatus,
    );
    final bool hasNotificationPermission = notificationStatus == PermissionStatus.granted;

    final bool hasLnAddressStateError = context.select<LnAddressCubit, bool>(
      (LnAddressCubit cubit) => cubit.state.hasError,
    );

    final int currentPageIndex = _getEffectivePageIndex(
      hasNotificationPermission: hasNotificationPermission,
      hasLnAddressStateError: hasLnAddressStateError,
    );

    final bool isLNPaymentPage = currentPageIndex == ReceiveLightningPaymentPage.pageIndex;

    return Scaffold(
      appBar: AppBar(
        leading: back_button.BackButton(
          onPressed: () {
            if (isLNPaymentPage && (!hasNotificationPermission || hasLnAddressStateError)) {
              // Pop to Home page, bypassing LN Address page if
              // - notification permissions are disabled
              // - LnAddressState has errors
              Navigator.of(context).pushReplacementNamed(Home.routeName);
              return;
            }
            Navigator.of(context).pop();
          },
        ),
        title: Text(_getTitle(currentPageIndex)),
        actions: currentPageIndex == ReceiveLightningAddressPage.pageIndex
            ? <Widget>[
                IconButton(
                  alignment: Alignment.center,
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    size: 24.0,
                  ),
                  // TODO(erdemyerebasmaz): Add message to Breez-Translations
                  tooltip: 'Specify amount for invoice',
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      ReceivePaymentPage.routeName,
                      arguments: ReceiveLightningPaymentPage.pageIndex,
                    );
                  },
                ),
              ]
            : <Widget>[],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: pages.elementAt(currentPageIndex),
      ),
    );
  }

  String _getTitle(int pageIndex) {
    final BreezTranslations texts = context.texts();
    switch (pageIndex) {
      case ReceiveLightningPaymentPage.pageIndex:
      case ReceiveLightningAddressPage.pageIndex:
        // TODO(erdemyerebasmaz): Add message to Breez-Translations
        return 'Receive with Lightning';
      case ReceiveBitcoinAddressPaymentPage.pageIndex:
        return texts.invoice_btc_address_title;
      default:
        return texts.invoice_lightning_title;
    }
  }

  // Redirect to Invoice page if LN Address page is opened
  // - without notification permissions
  // - when LN Address state had errors
  int _getEffectivePageIndex({
    required bool hasNotificationPermission,
    required bool hasLnAddressStateError,
  }) {
    final bool isLNAddressPage = widget.initialPageIndex == ReceiveLightningAddressPage.pageIndex;

    if (isLNAddressPage && (!hasNotificationPermission || hasLnAddressStateError)) {
      return ReceiveLightningPaymentPage.pageIndex;
    }

    return widget.initialPageIndex;
  }
}
