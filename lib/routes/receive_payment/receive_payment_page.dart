import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/receive_payment/lightning/receive_lightning_page.dart';
import 'package:l_breez/routes/receive_payment/ln_address/receive_lightning_address_page.dart';
import 'package:l_breez/routes/receive_payment/onchain/bitcoin_address/receive_bitcoin_address_payment_page.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;

class ReceivePaymentPage extends StatefulWidget {
  static const routeName = "/receive_payment";

  const ReceivePaymentPage({super.key});

  @override
  State<ReceivePaymentPage> createState() => _ReceivePaymentPageState();
}

class _ReceivePaymentPageState extends State<ReceivePaymentPage> {
  final PageController pageController = PageController();
  int selectedPage = 0;
  PaymentMethod selectedMethod = PaymentMethod.lightning;

  static const pages = [
    ReceiveLightningPaymentPage(),
    ReceiveLightningAddressPage(),
    ReceiveBitcoinAddressPaymentPage(),
  ];

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      selectedPage = index;
      selectedMethod = _getCurrentPaymentMethod(index);
    });
  }

  void _changePage(int index) {
    pageController.jumpToPage(index);
    _onPageChanged(index);
  }

  void _nextPage() {
    _changePage((selectedPage + 1) % pages.length);
  }

  void _previousPage() {
    _changePage((selectedPage - 1) % pages.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(_getTitle(selectedPage)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  alignment: Alignment.centerRight,
                  onPressed: _previousPage,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Text(
                    _getMethodName(selectedPage),
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  alignment: Alignment.centerLeft,
                  onPressed: _nextPage,
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              physics: const NeverScrollableScrollPhysics(),
              controller: pageController,
              onPageChanged: _onPageChanged,
              itemCount: pages.length,
              itemBuilder: (context, index) => pages.elementAt(index),
            ),
          ),
        ],
      ),
    );
  }

  PaymentMethod _getCurrentPaymentMethod(int index) {
    switch (index) {
      case 0:
        return PaymentMethod.lightning;
      case 1:
        return PaymentMethod.lightning;
      case 2:
        return PaymentMethod.bitcoinAddress;
      default:
        return PaymentMethod.lightning;
    }
  }

  String _getTitle(int index) {
    final texts = context.texts();
    switch (index) {
      case 0:
        return texts.invoice_lightning_title;
      case 1:
        return texts.invoice_ln_address_title;
      case 2:
        return texts.invoice_btc_address_title;
      default:
        return texts.invoice_lightning_title;
    }
  }

  String _getMethodName(int index) {
    final texts = context.texts();
    switch (index) {
      case 0:
        return texts.receive_payment_method_lightning_invoice;
      case 1:
        return texts.receive_payment_method_lightning_address;
      case 2:
        return texts.receive_payment_method_btc_address;
      default:
        return texts.receive_payment_method_lightning_invoice;
    }
  }
}
