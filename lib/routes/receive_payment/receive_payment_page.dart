import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;

class ReceivePaymentPage extends StatefulWidget {
  static const String routeName = '/receive_payment';

  final int? initialPageIndex;

  const ReceivePaymentPage({this.initialPageIndex, super.key});

  @override
  State<ReceivePaymentPage> createState() => _ReceivePaymentPageState();
}

class _ReceivePaymentPageState extends State<ReceivePaymentPage> {
  static const List<StatefulWidget> pages = <StatefulWidget>[
    ReceiveLightningPaymentPage(),
    ReceiveLightningAddressPage(),
    ReceiveAmountlessBitcoinAddressPage(),
    ReceiveBitcoinAddressPaymentPage(),
    ReceiveBolt12OfferPage(),
  ];

  bool _hasNotificationPermission = false;
  bool _hasLnAddressStateError = false;
  bool _hasAmountlessBtcAddressError = false;

  late int _currentPageIndex;
  bool _showInvoicePage = false;
  bool _showBtcPaymentRequestPage = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _currentPageIndex = widget.initialPageIndex ?? _indexOf<ReceiveLightningAddressPage>();
    });
  }

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
            if (_showBtcPaymentRequestPage && canReturnToAmountlessBtcPage) {
              setState(() {
                _showBtcPaymentRequestPage = false;
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
          if (_hasAmountToggle)
            IconButton(
              alignment: Alignment.center,
              icon: const Icon(Icons.edit_note_rounded, size: 24.0),
              // TODO(erdemyerebasmaz): Add message to Breez-Translations
              tooltip: 'Specify amount for payment request',
              onPressed: () {
                final StatefulWidget currentPage = pages[_currentPageIndex];
                if (currentPage is ReceiveLightningAddressPage) {
                  setState(() {
                    _showInvoicePage = true;
                  });
                } else if (currentPage is ReceiveAmountlessBitcoinAddressPage) {
                  setState(() {
                    _showBtcPaymentRequestPage = true;
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
      return shouldRedirect
          ? _indexOf<ReceiveLightningPaymentPage>()
          : _indexOf<ReceiveLightningAddressPage>();
    }

    if (_currentPaymentMethod == PaymentMethod.bolt12Offer) {
      return _indexOf<ReceiveBolt12OfferPage>();
    }

    // Redirect to BTC Invoice page if amountless BTC Address page is opened
    // - when Amountless BTC Address state had errors
    if (_currentPaymentMethod == PaymentMethod.bitcoinAddress) {
      final bool shouldRedirect = _showBtcPaymentRequestPage || _hasAmountlessBtcAddressError;
      return shouldRedirect
          ? _indexOf<ReceiveBitcoinAddressPaymentPage>()
          : _indexOf<ReceiveAmountlessBitcoinAddressPage>();
    }

    return _currentPageIndex;
  }

  bool get _hasAmountToggle =>
      _currentPaymentMethod == PaymentMethod.bolt11Invoice ||
      _currentPaymentMethod == PaymentMethod.bitcoinAddress;

  PaymentMethod get _currentPaymentMethod {
    final StatefulWidget currentPage = pages[_currentPageIndex];
    if (currentPage is ReceiveAmountlessBitcoinAddressPage || currentPage is ReceiveBitcoinAddressPaymentPage) {
      return PaymentMethod.bitcoinAddress;
    }
    if (currentPage is ReceiveBolt12OfferPage) {
      return PaymentMethod.bolt12Offer;
    }
    return PaymentMethod.bolt11Invoice;
  }

  Future<void> _onPaymentMethodChanged(PaymentMethod newMethod) async {
    if (newMethod == PaymentMethod.liquidAddress || newMethod == _currentPaymentMethod) {
      return;
    }
    Future<void>.microtask(() async {
      setState(() {
        _showInvoicePage = false;
        _showBtcPaymentRequestPage = false;
        _currentPageIndex = _getPageIndexForPaymentMethod(newMethod);
      });
    });
  }

  static int _indexOf<T>() {
    final int index = pages.indexWhere((StatefulWidget p) => p is T);
    assert(index >= 0, 'Page type $T not found in pages list');
    return index;
  }

  // Get the appropriate page index for a payment method
  int _getPageIndexForPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bitcoinAddress:
        return _indexOf<ReceiveAmountlessBitcoinAddressPage>();
      case PaymentMethod.bolt12Offer:
        return _indexOf<ReceiveBolt12OfferPage>();
      case PaymentMethod.bolt11Invoice:
        return _indexOf<ReceiveLightningAddressPage>();
      case PaymentMethod.liquidAddress:
        return _indexOf<ReceiveAmountlessBitcoinAddressPage>(); // Fallback
    }
  }
}
