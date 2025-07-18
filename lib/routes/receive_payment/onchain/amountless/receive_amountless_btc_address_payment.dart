import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/widgets.dart';

export 'widgets/widgets.dart';

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
