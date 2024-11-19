import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/chainswap/send/send_chainswap_form_page.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/loader.dart';

class SendChainSwapPage extends StatefulWidget {
  final BitcoinAddressData? btcAddressData;

  static const String routeName = '/send_chainswap';

  const SendChainSwapPage({required this.btcAddressData, super.key});

  @override
  State<SendChainSwapPage> createState() => _SendChainSwapPageState();
}

class _SendChainSwapPageState extends State<SendChainSwapPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.reverse_swap_title),
      ),
      body: BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
        builder: (BuildContext context, PaymentLimitsState snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                child: Text(
                  texts.reverse_swap_upstream_generic_error_message(snapshot.errorMessage),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.onchainPaymentLimits == null) {
            final ThemeData themeData = Theme.of(context);

            return Center(
              child: Loader(
                color: themeData.primaryColor.withOpacity(0.5),
              ),
            );
          }

          final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
          final CurrencyState currencyState = currencyCubit.state;
          return SendChainSwapFormPage(
            bitcoinCurrency: currencyState.bitcoinCurrency,
            paymentLimits: snapshot.onchainPaymentLimits!,
            btcAddressData: widget.btcAddressData,
          );
        },
      ),
    );
  }
}
