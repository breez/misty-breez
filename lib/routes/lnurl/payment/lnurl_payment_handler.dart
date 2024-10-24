import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/lnurl/payment/lnurl_payment_dialog.dart';
import 'package:l_breez/routes/lnurl/payment/lnurl_payment_info.dart';
import 'package:l_breez/routes/lnurl/payment/lnurl_payment_page.dart';
import 'package:l_breez/routes/lnurl/payment/success_action/success_action_dialog.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_page_result.dart';
import 'package:l_breez/widgets/payment_dialogs/processing_payment_dialog.dart';
import 'package:l_breez/widgets/route.dart';
import 'package:logging/logging.dart';
import 'package:service_injector/service_injector.dart';

final _log = Logger("HandleLNURLPayRequest");

Future<LNURLPageResult?> handlePayRequest(
  BuildContext context,
  GlobalKey firstPaymentItemKey,
  LnUrlPayRequestData data,
) async {
  LNURLPaymentInfo? paymentInfo;
  bool fixedAmount = data.minSendable == data.maxSendable;
  final paymentLimitsCubit = PaymentLimitsCubit(ServiceInjector().liquidSDK);
  if (fixedAmount && !(data.commentAllowed > 0)) {
    // Show dialog if payment is of fixed amount with no payer comment allowed
    paymentInfo = await showDialog<LNURLPaymentInfo>(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (BuildContext context) => paymentLimitsCubit,
        child: LNURLPaymentDialog(data: data),
      ),
    );
  } else {
    paymentInfo = await Navigator.of(context).push<LNURLPaymentInfo>(
      FadeInRoute(
        builder: (_) => BlocProvider(
          create: (BuildContext context) => paymentLimitsCubit,
          child: LnUrlPaymentPage(requestData: data),
        ),
      ),
    );
  }
  if (paymentInfo == null || !context.mounted) {
    return Future.value();
  }
  // Show Processing Payment Dialog
  return await showDialog(
    useRootNavigator: false,
    context: context,
    barrierDismissible: false,
    builder: (_) => ProcessingPaymentDialog(
      isLnUrlPayment: true,
      firstPaymentItemKey: firstPaymentItemKey,
      paymentFunc: () async {
        final lnurlCubit = context.read<LnUrlCubit>();
        final amountMsat = BigInt.from(paymentInfo!.amount * 1000);
        final prepareReq = PrepareLnUrlPayRequest(
          data: data,
          amountMsat: amountMsat,
          comment: paymentInfo.comment,
        );
        final prepareResponse = await lnurlCubit.prepareLnurlPay(req: prepareReq);
        final req = LnUrlPayRequest(prepareResponse: prepareResponse);
        return await lnurlCubit.lnurlPay(req: req);
      },
    ),
  ).then((result) {
    if (result is LnUrlPayResult) {
      if (result is LnUrlPayResult_EndpointSuccess) {
        _log.info("LNURL payment success, action: ${result.data}");
        return LNURLPageResult(
          protocol: LnUrlProtocol.pay,
          successAction: result.data.successAction,
        );
      } else if (result is LnUrlPayResult_PayError) {
        _log.info("LNURL payment for ${result.data.paymentHash} failed: ${result.data.reason}");
        return LNURLPageResult(
          protocol: LnUrlProtocol.pay,
          error: result.data.reason,
        );
      } else if (result is LnUrlPayResult_EndpointError) {
        _log.info("LNURL payment failed: ${result.data.reason}");
        return LNURLPageResult(
          protocol: LnUrlProtocol.pay,
          error: result.data.reason,
        );
      }
    }
    _log.warning("Error sending LNURL payment", result);
    throw LNURLPageResult(error: result).errorMessage;
  });
}

void handleLNURLPaymentPageResult(BuildContext context, LNURLPageResult result) {
  if (result.successAction != null) {
    _handleSuccessAction(context, result.successAction!);
  } else if (result.hasError) {
    _log.info("Handle LNURL payment page result with error '${result.error}'");
    throw Exception(result.errorMessage);
  }
}

Future _handleSuccessAction(BuildContext context, SuccessActionProcessed successAction) {
  String message = '';
  String? url;
  if (successAction is SuccessActionProcessed_Message) {
    message = successAction.data.message;
    _log.info("Handle LNURL payment page result with message action '$message'");
  } else if (successAction is SuccessActionProcessed_Url) {
    message = successAction.data.description;
    url = successAction.data.url;
    _log.info("Handle LNURL payment page result with url action '$message', '$url'");
  } else if (successAction is SuccessActionProcessed_Aes) {
    final result = successAction.result;
    if (result is AesSuccessActionDataResult_Decrypted) {
      message = "${result.data.description} ${result.data.plaintext}";
      _log.info("Handle LNURL payment page result with aes action '$message'");
    } else if (result is AesSuccessActionDataResult_ErrorStatus) {
      throw Exception(result.reason);
    }
  }
  return showDialog(
    useRootNavigator: false,
    context: context,
    builder: (_) => SuccessActionDialog(
      message: message,
      url: url,
    ),
  );
}
