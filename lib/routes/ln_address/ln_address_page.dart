import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/cubit/webhook/webhook_state.dart';
import 'package:l_breez/routes/create_invoice/widgets/successful_payment.dart';
import 'package:l_breez/routes/ln_address/ln_address_widget.dart';
import 'package:l_breez/routes/ln_address/widgets/address_widget_placeholder.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/single_button_bottom_bar.dart';
import 'package:l_breez/widgets/transparent_page_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

final _log = Logger("LnAddressPage");

class LnAddressPage extends StatefulWidget {
  static const routeName = "/ln_address";

  const LnAddressPage();

  @override
  State<StatefulWidget> createState() {
    return LnAddressPageState();
  }
}

class LnAddressPageState extends State<LnAddressPage> {
  @override
  void initState() {
    super.initState();
    _refreshLnurlPay();
    _trackPayment();
  }

  void _refreshLnurlPay() {
    final webhookCubit = context.read<WebhookCubit>();
    webhookCubit.refreshLnurlPay();
  }

  void _trackPayment() {
    var inputCubit = context.read<InputCubit>();
    inputCubit.trackPayment(null).then((value) {
      Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _onPaymentFinished();
        }
      });
    }).catchError((e) {
      _log.warning("Failed to track payment", e);
    });
  }

  void _onPaymentFinished() {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(TransparentPageRoute((ctx) => const SuccessfulPaymentRoute()));
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return BlocBuilder<WebhookCubit, WebhookState>(
      builder: (context, webhookState) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: const back_button.BackButton(),
            title: Text(texts.invoice_ln_address_title),
          ),
          body: webhookState.isLoading
              ? AddressWidgetPlaceholder()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      if (webhookState.lnurlPayUrl != null) LnAddressWidget(webhookState.lnurlPayUrl!),
                      if (webhookState.lnurlPayError != null) ...[
                        _ErrorMessage(
                          message: extractExceptionMessage(webhookState.lnurlPayError!, texts),
                        ),
                      ]
                    ],
                  ),
                ),
          bottomNavigationBar: webhookState.lnurlPayError != null
              ? SingleButtonBottomBar(
                  text: texts.invoice_ln_address_action_retry,
                  onPressed: () => _refreshLnurlPay,
                )
              : const SizedBox(),
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
