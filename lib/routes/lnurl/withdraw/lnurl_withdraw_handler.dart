import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/payment_limits/payment_limits_cubit.dart';
import 'package:l_breez/routes/home/home_page.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_page_result.dart';
import 'package:l_breez/routes/receive_payment/lightning/receive_lightning_page.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/widgets.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/error_dialog.dart';
import 'package:l_breez/widgets/transparent_page_route.dart';
import 'package:logging/logging.dart';
import 'package:service_injector/service_injector.dart';

final _log = Logger("HandleLNURLWithdrawPageResult");

Future<LNURLPageResult?> handleWithdrawRequest(
  BuildContext context,
  LnUrlWithdrawRequestData requestData,
) async {
  Completer<LNURLPageResult?> completer = Completer();
  final texts = context.texts();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().liquidSDK),
        child: Scaffold(
          appBar: AppBar(
            leading: const back_button.BackButton(),
            title: Text("Receive via ${texts.lnurl_payment_page_title}"),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
            child: ReceiveLightningPaymentPage(
              requestData: requestData,
              onFinish: (LNURLPageResult? response) {
                completer.complete(response);
                Navigator.of(context).popUntil((route) => route.settings.name == Home.routeName);
              },
            ),
          ),
        ),
      ),
    ),
  );

  return completer.future;
}

void handleLNURLWithdrawPageResult(BuildContext context, LNURLPageResult result) {
  _log.info("handle $result");
  if (result.hasError) {
    _log.info("Handle LNURL withdraw page result with error '${result.error}'");
    final texts = context.texts();
    final themeData = Theme.of(context);
    promptError(
      context,
      texts.invoice_receive_fail,
      Text(
        texts.invoice_receive_fail_message(result.errorMessage),
        style: themeData.dialogTheme.contentTextStyle,
      ),
    );
    throw result.error!;
  } else {
    _log.info("Handle LNURL withdraw page result with success");
    Navigator.of(context).push(
      TransparentPageRoute((ctx) => const SuccessfulPaymentRoute()),
    );
  }
}
