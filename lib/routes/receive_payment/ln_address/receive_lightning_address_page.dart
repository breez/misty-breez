import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/cubit/webhook/webhook_state.dart';
import 'package:l_breez/routes/receive_payment/ln_address/widgets/address_widget_placeholder.dart';
import 'package:l_breez/routes/receive_payment/widgets/address_widget/address_widget.dart';
import 'package:l_breez/routes/receive_payment/widgets/payment_info_message_box/payment_limits_message_box.dart';
import 'package:l_breez/utils/exceptions.dart';
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
              ? const AddressWidgetPlaceholder()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (webhookState.lnurlPayUrl != null)
                          AddressWidget(
                            address: webhookState.lnurlPayUrl!,
                            title: texts.receive_payment_method_lightning_address,
                            type: AddressWidgetType.lightning,
                            infoWidget: const PaymentLimitsMessageBox(),
                          ),
                        if (webhookState.lnurlPayError != null)
                          _ErrorMessage(
                            message: extractExceptionMessage(webhookState.lnurlPayError!, texts),
                          ),
                      ],
                    ),
                  ),
                ),
          bottomNavigationBar: webhookState.lnurlPayError != null
              ? SingleButtonBottomBar(
                  stickToBottom: true,
                  text: texts.invoice_ln_address_action_retry,
                  onPressed: () => _refreshLnurlPay,
                )
              : SingleButtonBottomBar(
                  stickToBottom: true,
                  text: texts.qr_code_dialog_action_close,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
        );
      },
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
