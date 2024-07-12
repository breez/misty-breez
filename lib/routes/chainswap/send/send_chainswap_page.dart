import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/chainswap/send/send_chainswap_form_page.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/loader.dart';

class SendChainSwapPage extends StatefulWidget {
  final BitcoinAddressData? btcAddressData;

  const SendChainSwapPage({super.key, required this.btcAddressData});

  @override
  State<SendChainSwapPage> createState() => _SendChainSwapPageState();
}

class _SendChainSwapPageState extends State<SendChainSwapPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<OnchainPaymentLimitsResponse>? _onchainPaymentLimitsFuture;
  @override
  void initState() {
    super.initState();
    _fetchOnchainLimits();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchOnchainLimits();
    }
  }

  Future _fetchOnchainLimits() async {
    final chainSwapCubit = context.read<ChainSwapCubit>();
    setState(() {
      _onchainPaymentLimitsFuture = chainSwapCubit.fetchOnchainLimits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.bottom_action_bar_send_btc_address),
      ),
      body: FutureBuilder<OnchainPaymentLimitsResponse>(
        future: _onchainPaymentLimitsFuture,
        builder: (BuildContext context, AsyncSnapshot<OnchainPaymentLimitsResponse> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                child: Text(
                  texts.reverse_swap_upstream_generic_error_message(
                    extractExceptionMessage(snapshot.error!, texts),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) {
            return Center(
              child: Loader(
                color: themeData.primaryColor.withOpacity(0.5),
              ),
            );
          }

          var currencyState = context.read<CurrencyCubit>().state;
          return SendChainSwapFormPage(
            bitcoinCurrency: currencyState.bitcoinCurrency,
            btcAddressData: widget.btcAddressData,
            paymentLimits: snapshot.data!,
          );
        },
      ),
    );
  }
}
