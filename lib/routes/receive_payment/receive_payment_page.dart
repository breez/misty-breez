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
    final int currentPageIndex = _getEffectivePageIndex(notificationStatus);

    return Scaffold(
      appBar: AppBar(
        leading: back_button.BackButton(
          onPressed: () {
            if (currentPageIndex == ReceiveLightningPaymentPage.pageIndex &&
                notificationStatus != PermissionStatus.granted) {
              // Pop to Home page, bypassing LN Address page if notification permissions are disabled
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

  int _getEffectivePageIndex(PermissionStatus notificationStatus) {
    // Redirect to Invoice page if LN Address page is opened without notification permissions
    if (widget.initialPageIndex == ReceiveLightningAddressPage.pageIndex &&
        notificationStatus != PermissionStatus.granted) {
      return ReceiveLightningPaymentPage.pageIndex;
    }

    final bool hasLnAddressStateError = context.select<LnAddressCubit, bool>(
      (LnAddressCubit cubit) => cubit.state.hasError,
    );

    if (!hasLnAddressStateError) {
      return ReceiveLightningPaymentPage.pageIndex;
    }

    return widget.initialPageIndex;
  }
}
