import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/payment_limits/payment_limits_cubit.dart';
import 'package:l_breez/routes/create_invoice/create_invoice_page.dart';
import 'package:l_breez/routes/create_invoice/widgets/successful_payment.dart';
import 'package:l_breez/routes/home/home_page.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_page_result.dart';
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
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().liquidSDK),
        child: CreateInvoicePage(
          requestData: requestData,
          onFinish: (LNURLPageResult? response) {
            completer.complete(response);
            Navigator.of(context).popUntil((route) => route.settings.name == Home.routeName);
          },
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
