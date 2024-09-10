import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/routes/receive_payment/lightning/receive_lightning_page.dart';
import 'package:l_breez/routes/receive_payment/ln_address/receive_lightning_address_page.dart';
import 'package:l_breez/routes/receive_payment/onchain/bitcoin_address/receive_bitcoin_address_payment_page.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;

class ReceivePaymentPage extends StatefulWidget {
  static const routeName = "/receive_payment";
  final int initialPageIndex;

  const ReceivePaymentPage({super.key, required this.initialPageIndex});

  @override
  State<ReceivePaymentPage> createState() => _ReceivePaymentPageState();
}

class _ReceivePaymentPageState extends State<ReceivePaymentPage> {
  late PageController pageController;
  int selectedPageIndex = 0;

  static const pages = [
    ReceiveLightningPaymentPage(),
    ReceiveLightningAddressPage(),
    ReceiveBitcoinAddressPaymentPage(),
  ];

  @override
  void initState() {
    super.initState();
    setState(() {
      selectedPageIndex = widget.initialPageIndex;
      pageController = PageController(initialPage: selectedPageIndex);
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      selectedPageIndex = index;
    });
  }

  void _changePage(int index) {
    pageController.jumpToPage(index);
    _onPageChanged(index);
  }

  void _nextPage() {
    _changePage((selectedPageIndex + 1) % pages.length);
  }

  void _previousPage() {
    _changePage((selectedPageIndex - 1) % pages.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(_getTitle()),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        child: Column(
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
                      _getMethodName(),
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
      ),
    );
  }

  String _getTitle() {
    final texts = context.texts();
    switch (selectedPageIndex) {
      case ReceiveLightningPaymentPage.pageIndex:
        return texts.invoice_lightning_title;
      case ReceiveLightningAddressPage.pageIndex:
        return texts.invoice_ln_address_title;
      case ReceiveBitcoinAddressPaymentPage.pageIndex:
        return texts.invoice_btc_address_title;
      default:
        return texts.invoice_lightning_title;
    }
  }

  String _getMethodName() {
    final texts = context.texts();
    switch (selectedPageIndex) {
      case ReceiveLightningPaymentPage.pageIndex:
        return texts.receive_payment_method_lightning_invoice;
      case ReceiveLightningAddressPage.pageIndex:
        return texts.receive_payment_method_lightning_address;
      case ReceiveBitcoinAddressPaymentPage.pageIndex:
        return texts.receive_payment_method_btc_address;
      default:
        return texts.receive_payment_method_lightning_invoice;
    }
  }
}
