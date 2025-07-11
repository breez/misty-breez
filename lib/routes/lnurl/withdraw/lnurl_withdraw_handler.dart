import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';

final Logger _logger = Logger('HandleLNURLWithdrawPageResult');

Future<LNURLPageResult?> handleWithdrawRequest(
  BuildContext context,
  LnUrlWithdrawRequestData requestData,
) async {
  final Completer<LNURLPageResult?> completer = Completer<LNURLPageResult?>();
  final BreezTranslations texts = context.texts();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider<PaymentLimitsCubit>(
        create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().breezSdkLiquid),
        child: Scaffold(
          appBar: AppBar(
            leading: const back_button.BackButton(),
            title: Text(texts.lnurl_withdraw_page_title),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LnUrlWithdrawPage(
              requestData: requestData,
              onFinish: (LNURLPageResult? response) {
                completer.complete(response);
                Navigator.of(
                  context,
                ).popUntil((Route<dynamic> route) => route.settings.name == Home.routeName);
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
  _logger.info('handle $result');
  if (result.hasError) {
    _logger.info("Handle LNURL withdraw page result with error '${result.error}'");
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);
    promptError(
      context,
      title: texts.invoice_receive_fail,
      body: Text(
        texts.invoice_receive_fail_message(result.errorMessage),
        style: themeData.dialogTheme.contentTextStyle,
      ),
    );
    throw result.error!;
  } else {
    _logger.info('Handle LNURL withdraw page result with success');
    showPaymentReceivedSheet(context);
  }
}
