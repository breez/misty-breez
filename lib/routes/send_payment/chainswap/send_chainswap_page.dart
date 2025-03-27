import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';

final Logger _logger = Logger('SendChainSwapPage');

class SendChainSwapPage extends StatefulWidget {
  final BitcoinAddressData? btcAddressData;

  static const String routeName = '/send_chainswap';

  const SendChainSwapPage({required this.btcAddressData, super.key});

  @override
  State<SendChainSwapPage> createState() => _SendChainSwapPageState();
}

class _SendChainSwapPageState extends State<SendChainSwapPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool isDrain = false;

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.reverse_swap_title),
      ),
      body: BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
        builder: (BuildContext context, PaymentLimitsState snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ScrollableErrorMessageWidget(
                showIcon: true,
                title: texts.payment_limits_generic_error_title,
                message: ExceptionHandler.extractMessage(snapshot.errorMessage, texts),
              ),
            );
          }
          final OnchainPaymentLimitsResponse? onchainPaymentLimits = snapshot.onchainPaymentLimits;
          if (onchainPaymentLimits == null) {
            return Center(
              child: Loader(
                color: themeData.primaryColor.withValues(alpha: .5),
              ),
            );
          }

          if (snapshot.onchainPaymentLimits == null) {
            final ThemeData themeData = Theme.of(context);

            return Center(
              child: Loader(
                color: themeData.primaryColor.withValues(alpha: .5),
              ),
            );
          }

          final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
          final CurrencyState currencyState = currencyCubit.state;
          return SendChainSwapFormPage(
            formKey: _formKey,
            amountController: _amountController,
            addressController: _addressController,
            bitcoinCurrency: currencyState.bitcoinCurrency,
            paymentLimits: snapshot.onchainPaymentLimits!,
            btcAddressData: widget.btcAddressData,
            isDrain: isDrain,
            onChanged: (bool value) {
              setState(() {
                isDrain = value;
              });
            },
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
        builder: (BuildContext context, PaymentLimitsState snapshot) {
          return snapshot.hasError
              ? SingleButtonBottomBar(
                  stickToBottom: true,
                  text: texts.invoice_btc_address_action_retry,
                  onPressed: () {
                    final PaymentLimitsCubit paymentLimitsCubit = context.read<PaymentLimitsCubit>();
                    paymentLimitsCubit.fetchOnchainLimits();
                  },
                )
              : snapshot.lightningPaymentLimits == null
                  ? const SizedBox.shrink()
                  : SingleButtonBottomBar(
                      text: texts.withdraw_funds_action_next,
                      onPressed: _prepareSendChainSwap,
                    );
        },
      ),
    );
  }

  void _prepareSendChainSwap() async {
    final BreezTranslations texts = context.texts();
    final NavigatorState navigator = Navigator.of(context);
    if (_formKey.currentState?.validate() ?? false) {
      final TransparentPageRoute<void> loaderRoute = createLoaderRoute(context);
      navigator.push(loaderRoute);
      try {
        final int amount = _getAmount();
        if (loaderRoute.isActive) {
          navigator.removeRoute(loaderRoute);
        }
        navigator.push(
          FadeInRoute<void>(
            builder: (_) => SendChainSwapConfirmationPage(
              amountSat: amount,
              onchainRecipientAddress: _addressController.text,
              isDrain: isDrain,
            ),
          ),
        );
      } catch (error) {
        if (loaderRoute.isActive) {
          navigator.removeRoute(loaderRoute);
        }
        _logger.severe('Received error: $error');
        if (!context.mounted) {
          return;
        }
        showFlushbar(
          context,
          message: texts.reverse_swap_upstream_generic_error_message(
            ExceptionHandler.extractMessage(error, texts),
          ),
        );
      } finally {
        if (loaderRoute.isActive) {
          navigator.removeRoute(loaderRoute);
        }
      }
    }
  }

  int _getAmount() {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;
    int amount = 0;
    try {
      amount = currencyState.bitcoinCurrency.parse(_amountController.text);
    } catch (e) {
      _logger.warning('Failed to parse the input amount', e);
    }
    return amount;
  }
}
