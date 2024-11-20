import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/widgets.dart';

class ReceiveLightningAddressPage extends StatefulWidget {
  static const String routeName = '/lightning_address';
  static const int pageIndex = 1;

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
    final WebhookCubit webhookCubit = context.read<WebhookCubit>();
    webhookCubit.refreshLnurlPay();
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return BlocBuilder<WebhookCubit, WebhookState>(
      builder: (BuildContext context, WebhookState webhookState) {
        return Scaffold(
          body: webhookState.isLoading
              ? const DestinationWidgetPlaceholder()
              : webhookState.lnurlPayError != null
                  ? ScrollableErrorMessageWidget(
                      title: webhookState.lnurlPayErrorTitle ?? texts.lightning_address_service_error_title,
                      message: extractExceptionMessage(webhookState.lnurlPayError!, texts),
                    )
                  : webhookState.lnurlPayUrl != null
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 40.0),
                          child: SingleChildScrollView(
                            child: DestinationWidget(
                              isLnAddress: true,
                              destination: webhookState.lnurlPayUrl,
                              title: texts.receive_payment_method_lightning_address,
                              infoWidget: const PaymentLimitsMessageBox(),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
          bottomNavigationBar: BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
            builder: (BuildContext context, PaymentLimitsState snapshot) {
              return webhookState.lnurlPayError != null || snapshot.hasError
                  ? SingleButtonBottomBar(
                      stickToBottom: true,
                      text: texts.invoice_ln_address_action_retry,
                      onPressed: webhookState.lnurlPayError != null
                          ? () => _refreshLnurlPay()
                          : () {
                              final PaymentLimitsCubit paymentLimitsCubit =
                                  context.read<PaymentLimitsCubit>();
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
