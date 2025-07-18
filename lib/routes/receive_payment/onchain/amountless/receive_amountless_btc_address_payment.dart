import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

/// Page that displays the user's amountless Bitcoin Address for receiving payments.
class ReceiveAmountlessBitcoinAddressPage extends StatefulWidget {
  static const String routeName = '/amountless_bitcoin_address';
  static const int pageIndex = 2;

  const ReceiveAmountlessBitcoinAddressPage({super.key});

  @override
  State<StatefulWidget> createState() => ReceiveAmountlessBitcoinAddressPageState();
}

class ReceiveAmountlessBitcoinAddressPageState extends State<ReceiveAmountlessBitcoinAddressPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final AmountlessBtcCubit amountlessBtcCubit = context.read<AmountlessBtcCubit>();
      amountlessBtcCubit.generateAmountlessAddress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return BlocBuilder<AmountlessBtcCubit, AmountlessBtcState>(
      builder: (BuildContext context, AmountlessBtcState amountlessBtcState) {
        return Scaffold(
          body: _getAmountlessBtcAddressContent(amountlessBtcState),
          bottomNavigationBar: BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
            builder: (BuildContext context, PaymentLimitsState limitsState) {
              final bool hasError = limitsState.hasError || amountlessBtcState.hasError;

              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SingleButtonBottomBar(
                  stickToBottom: true,
                  text: hasError ? texts.invoice_btc_address_action_retry : texts.qr_code_dialog_action_close,
                  onPressed: hasError ? () => _fetchOnchainLimits() : () => Navigator.of(context).pop(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _getAmountlessBtcAddressContent(AmountlessBtcState amountlessBtcState) {
    if (amountlessBtcState.isLoading) {
      return const CenteredLoader();
    }

    if (amountlessBtcState.hasError) {
      return AmountlessBtcAddressErrorView(error: amountlessBtcState.error!);
    }

    if (amountlessBtcState.hasValidAddress) {
      return AmountlessBtcAddressSuccessView(amountlessBtcState);
    }

    return const SizedBox.shrink();
  }

  void _fetchOnchainLimits() {
    final PaymentLimitsCubit paymentLimitsCubit = context.read<PaymentLimitsCubit>();
    paymentLimitsCubit.fetchOnchainLimits();

    final AmountlessBtcCubit amountlessBtcCubit = context.read<AmountlessBtcCubit>();
    amountlessBtcCubit.generateAmountlessAddress();
  }
}

class AmountlessBtcAddressSuccessView extends StatelessWidget {
  final AmountlessBtcState amountlessBtcState;

  const AmountlessBtcAddressSuccessView(this.amountlessBtcState, {super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              decoration: ShapeDecoration(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                color: themeData.customData.surfaceBgColor,
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
              child: Column(
                children: <Widget>[
                  DestinationWidget(
                    destination: amountlessBtcState.address,
                    paymentLabel: texts.receive_payment_method_btc_address,
                    infoWidget: AmountlessBtcAddressMessageBox(amountlessBtcState),
                    isBitcoinPayment: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AmountlessBtcAddressErrorView extends StatelessWidget {
  final Object error;

  const AmountlessBtcAddressErrorView({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          final AmountlessBtcCubit amountlessBtcCubit = context.read<AmountlessBtcCubit>();
          amountlessBtcCubit.generateAmountlessAddress();
        },
        child: WarningBox(
          boxPadding: EdgeInsets.zero,
          backgroundColor: themeData.colorScheme.error.withValues(alpha: .1),
          contentPadding: const EdgeInsets.all(16.0),
          child: RichText(
            text: TextSpan(
              text: ExceptionHandler.extractMessage(error, texts),
              style: themeData.textTheme.bodyLarge?.copyWith(color: themeData.colorScheme.error),
              children: <InlineSpan>[
                TextSpan(
                  text: '\n\nTap here to retry',
                  style: themeData.textTheme.titleLarge?.copyWith(
                    color: themeData.colorScheme.error.withValues(alpha: .7),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class AmountlessBtcAddressMessageBox extends StatelessWidget {
  final AmountlessBtcState amountlessBtcState;

  const AmountlessBtcAddressMessageBox(this.amountlessBtcState, {super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
      builder: (BuildContext context, PaymentLimitsState snapshot) {
        if (snapshot.hasError) {
          return ScrollableErrorMessageWidget(
            title: texts.payment_limits_generic_error_title,
            padding: const EdgeInsets.symmetric(vertical: 20),
            message: texts.reverse_swap_upstream_generic_error_message(snapshot.errorMessage),
          );
        }
        if (snapshot.onchainPaymentLimits == null) {
          return const CenteredLoader();
        }

        final String limitsMessage = _formatAmountlessBtcMessage(context, snapshot, amountlessBtcState);
        const String feeInfoUrl =
            'https://sdk-doc-liquid.breez.technology/guide/base_fees.html#receiving-from-a-btc-address';
        return PaymentInfoMessageBox(message: limitsMessage, linkUrl: feeInfoUrl);
      },
    );
  }

  String _formatAmountlessBtcMessage(
    BuildContext context,
    PaymentLimitsState snapshot,
    AmountlessBtcState amountlessBtcState,
  ) {
    final BreezTranslations texts = context.texts();
    final CurrencyState currencyState = context.read<CurrencyCubit>().state;

    final Limits limits = snapshot.onchainPaymentLimits!.receive;
    final String minReceivableFormatted = currencyState.bitcoinCurrency.format(limits.minSat.toInt());
    final String maxReceivableFormatted = currencyState.bitcoinCurrency.format(limits.maxSat.toInt());
    // TODO(erdemyerebasmaz): Add fee info message to Breez-Translations.
    final String feeInfoMsg = 'Receiving funds incurs a fee as specified';
    return '${texts.payment_limits_message(minReceivableFormatted, maxReceivableFormatted)} This address can be used only once. $feeInfoMsg ';
  }
}
