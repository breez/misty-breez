import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/cubit/webhook/webhook_state.dart';
import 'package:l_breez/routes/receive_payment/widgets/destination_widget/destination_widget.dart';
import 'package:l_breez/routes/receive_payment/widgets/destination_widget/destination_widget_placeholder.dart';
import 'package:l_breez/routes/receive_payment/widgets/payment_info_message_box/payment_limits_message_box.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/scrollable_error_message_widget.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';

class ReceiveLightningAddressPage extends StatefulWidget {
  static const routeName = "/lightning_address";
  static const pageIndex = 1;

  const ReceiveLightningAddressPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return ReceiveLightningAddressPageState();
  }
}

class ReceiveLightningAddressPageState extends State<ReceiveLightningAddressPage> {
  @override
  void initState() {
    super.initState();
    _refreshLnurlPay();
  }

  void _refreshLnurlPay() {
    final webhookCubit = context.read<WebhookCubit>();
    webhookCubit.refreshLnurlPay();
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return BlocBuilder<WebhookCubit, WebhookState>(
      builder: (context, webhookState) {
        return Scaffold(
          body: webhookState.isLoading
              ? const DestinationWidgetPlaceholder()
              : (webhookState.lnurlPayError != null)
                  ? ScrollableErrorMessageWidget(
                      title: webhookState.lnurlPayErrorTitle ?? texts.lightning_address_service_error_title,
                      message: extractExceptionMessage(webhookState.lnurlPayError!, texts),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (webhookState.lnurlPayUrl != null)
                              DestinationWidget(
                                isLnAddress: true,
                                destination: webhookState.lnurlPayUrl!,
                                title: texts.receive_payment_method_lightning_address,
                                infoWidget: const PaymentLimitsMessageBox(),
                              ),
                          ],
                        ),
                      ),
                    ),
          bottomNavigationBar: BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
            builder: (BuildContext context, PaymentLimitsState snapshot) {
              return webhookState.lnurlPayError != null
                  ? SingleButtonBottomBar(
                      stickToBottom: true,
                      text: texts.invoice_ln_address_action_retry,
                      onPressed: () => _refreshLnurlPay(),
                    )
                  : snapshot.hasError
                      ? SingleButtonBottomBar(
                          stickToBottom: true,
                          text: texts.invoice_ln_address_action_retry,
                          onPressed: () {
                            final paymentLimitsCubit = context.read<PaymentLimitsCubit>();
                            paymentLimitsCubit.fetchLightningLimits();
                          },
                        )
                      : SingleButtonBottomBar(
                          stickToBottom: true,
                          text: texts.qr_code_dialog_action_close,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        );
            },
          ),
        );
      },
    );
  }
}
