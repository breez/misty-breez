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
    ReceiveAmountlessBitcoinAddressPage(),
    ReceiveBitcoinAddressPaymentPage(),
  ];

  bool _hasNotificationPermission = false;
  bool _hasLnAddressStateError = false;
  bool _hasAmountlessBtcAddressError = false;

  int _currentPageIndex = ReceiveLightningAddressPage.pageIndex;
  bool _showInvoicePage = false;
  bool _showBtcInvoicePage = false;

  @override
  Widget build(BuildContext context) {
    final PermissionStatus notificationStatus = context.select<PermissionsCubit, PermissionStatus>(
      (PermissionsCubit cubit) => cubit.state.notificationStatus,
    );
    _hasNotificationPermission = notificationStatus == PermissionStatus.granted;
    _hasLnAddressStateError = context.select<LnAddressCubit, bool>(
      (LnAddressCubit cubit) => cubit.state.hasError,
    );

    _hasAmountlessBtcAddressError = context.select<AmountlessBtcCubit, bool>(
      (AmountlessBtcCubit cubit) => cubit.state.hasError,
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

            final bool canReturnToAmountlessBtcPage = !_hasAmountlessBtcAddressError;
            if (_showBtcInvoicePage && canReturnToAmountlessBtcPage) {
              setState(() {
                _showBtcInvoicePage = false;
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
        actions: <Widget>[
          IconButton(
            alignment: Alignment.center,
            icon: const Icon(Icons.edit_note_rounded, size: 24.0),
            // TODO(erdemyerebasmaz): Add message to Breez-Translations
            tooltip: 'Specify amount for invoice',
            onPressed: () {
              if (_currentPageIndex == ReceiveLightningAddressPage.pageIndex) {
                setState(() {
                  _showInvoicePage = true;
                });
              } else if (_currentPageIndex == ReceiveAmountlessBitcoinAddressPage.pageIndex) {
                setState(() {
                  _showBtcInvoicePage = true;
                });
              }
            },
          ),
        ],
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
    // Redirect to Invoice page if LN Address page is opened
    // - without notification permissions
    // - when LN Address state had errors
    if (_currentPaymentMethod == PaymentMethod.bolt11Invoice) {
      final bool shouldRedirect = _showInvoicePage || !_hasNotificationPermission || _hasLnAddressStateError;
      return shouldRedirect ? ReceiveLightningPaymentPage.pageIndex : ReceiveLightningAddressPage.pageIndex;
    }

    // Redirect to BTC Invoice page if amountless BTC Address page is opened
    // - when Amountless BTC Address state had errors
    if (_currentPaymentMethod == PaymentMethod.bitcoinAddress) {
      final bool shouldRedirect = _showBtcInvoicePage || _hasAmountlessBtcAddressError;
      return shouldRedirect
          ? ReceiveBitcoinAddressPaymentPage.pageIndex
          : ReceiveAmountlessBitcoinAddressPage.pageIndex;
    }

    return _currentPageIndex;
  }

  PaymentMethod get _currentPaymentMethod {
    return _currentPageIndex == ReceiveAmountlessBitcoinAddressPage.pageIndex ||
            _currentPageIndex == ReceiveBitcoinAddressPaymentPage.pageIndex
        ? PaymentMethod.bitcoinAddress
        : PaymentMethod.bolt11Invoice;
  }

  Future<void> _onPaymentMethodChanged(PaymentMethod newMethod) async {
    if (newMethod == PaymentMethod.liquidAddress || newMethod == _currentPaymentMethod) {
      return;
    }
    Future<void>.microtask(() async {
      setState(() {
        _showInvoicePage = false;
        _showBtcInvoicePage = false;
        _currentPageIndex = _getPageIndexForPaymentMethod(newMethod);
      });
    });
  }

  // Get the appropriate page index for a payment method
  int _getPageIndexForPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bitcoinAddress:
        return ReceiveAmountlessBitcoinAddressPage.pageIndex;
      case PaymentMethod.bolt12Offer:
        // TODO(dangeross): Add a BOLT12 offer to the Lightning address page
        return ReceiveLightningAddressPage.pageIndex;
      case PaymentMethod.bolt11Invoice:
      case PaymentMethod.lightning:
        return ReceiveLightningAddressPage.pageIndex;
      case PaymentMethod.liquidAddress:
        return ReceiveAmountlessBitcoinAddressPage.pageIndex; // Fallback
    }
  }
}
