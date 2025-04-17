import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;

class ReceivePaymentPage extends StatefulWidget {
  static const String routeName = '/receive_payment';

  const ReceivePaymentPage({super.key});

  @override
  State<ReceivePaymentPage> createState() => _ReceivePaymentPageState();
}

class _ReceivePaymentPageState extends State<ReceivePaymentPage> {
  static const List<StatefulWidget> pages = <StatefulWidget>[
    ReceiveLightningPaymentPage(),
    ReceiveLightningAddressPage(),
    ReceiveBitcoinAddressPaymentPage(),
  ];

  bool _hasNotificationPermission = false;
  bool _hasLnAddressStateError = false;

  int _currentPageIndex = ReceiveLightningAddressPage.pageIndex;
  bool _showInvoicePage = false;

  @override
  Widget build(BuildContext context) {
    final PermissionStatus notificationStatus = context.select<PermissionsCubit, PermissionStatus>(
      (PermissionsCubit cubit) => cubit.state.notificationStatus,
    );
    _hasNotificationPermission = notificationStatus == PermissionStatus.granted;
    _hasLnAddressStateError = context.select<LnAddressCubit, bool>(
      (LnAddressCubit cubit) => cubit.state.hasError,
    );

    _updatePageIndex();

    return Scaffold(
      appBar: AppBar(
        leading: back_button.BackButton(
          onPressed: () {
            final bool canReturnToLNAddressPage = (_hasNotificationPermission && !_hasLnAddressStateError);
            if (_showInvoicePage && canReturnToLNAddressPage) {
              setState(() {
                _showInvoicePage = false;
              });
              return;
            }
            Navigator.of(context).pushReplacementNamed(Home.routeName);
          },
        ),
        title: PaymentMethodDropdown(
          currentPaymentMethod: _currentPaymentMethod,
          onPaymentMethodChanged: _onPaymentMethodChanged,
        ),
        centerTitle: true,
        actions: _currentPageIndex == ReceiveLightningAddressPage.pageIndex
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
                    setState(() {
                      _showInvoicePage = true;
                    });
                  },
                ),
              ]
            : <Widget>[],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: pages.elementAt(_currentPageIndex),
      ),
    );
  }

  void _updatePageIndex() {
    final int effectivePageIndex = _getEffectivePageIndex();

    if (effectivePageIndex != _currentPageIndex) {
      setState(() {
        _currentPageIndex = effectivePageIndex;
      });
    }
  }

  int _getEffectivePageIndex() {
    if (_currentPaymentMethod == PaymentMethod.bitcoinAddress) {
      return ReceiveBitcoinAddressPaymentPage.pageIndex;
    }

    // Redirect to Invoice page if LN Address page is opened
    // - without notification permissions
    // - when LN Address state had errors
    final bool shouldRedirect = !_hasNotificationPermission || _hasLnAddressStateError;
    if (_showInvoicePage || _currentPaymentMethod == PaymentMethod.lightning && shouldRedirect) {
      return ReceiveLightningPaymentPage.pageIndex;
    }

    return ReceiveLightningAddressPage.pageIndex;
  }

  PaymentMethod get _currentPaymentMethod {
    return _currentPageIndex == ReceiveBitcoinAddressPaymentPage.pageIndex
        ? PaymentMethod.bitcoinAddress
        : PaymentMethod.lightning;
  }

  Future<void> _onPaymentMethodChanged(PaymentMethod newMethod) async {
    if (newMethod == PaymentMethod.liquidAddress || newMethod == _currentPaymentMethod) {
      return;
    }
    Future<void>.microtask(() async {
      setState(() {
        _showInvoicePage = false;
        _currentPageIndex = _getPageIndexForPaymentMethod(newMethod);
      });
    });
  }

  // Get the appropriate page index for a payment method
  int _getPageIndexForPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bolt12Invoice:
        // We should not have to handle this payment method as a user
        // selection, it is purely the task of the Notifification Plugin
        return ReceiveBitcoinAddressPaymentPage.pageIndex;
      case PaymentMethod.bolt12Offer:
        // TODO: Add a BOLT12 offer payment page to show the offer QR code
        return ReceiveBitcoinAddressPaymentPage.pageIndex;
      case PaymentMethod.bitcoinAddress:
        return ReceiveBitcoinAddressPaymentPage.pageIndex;
      case PaymentMethod.lightning:
        return ReceiveLightningAddressPage.pageIndex;
      case PaymentMethod.liquidAddress:
        return ReceiveBitcoinAddressPaymentPage.pageIndex; // Fallback
    }
  }
}
