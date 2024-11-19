import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/lnurl/payment/lnurl_payment_page.dart';
import 'package:l_breez/routes/lnurl/payment/success_action/success_action_dialog.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_page_result.dart';
import 'package:l_breez/widgets/payment_dialogs/processing_payment_dialog.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('HandleLNURLPayRequest');

Future<LNURLPageResult?> handlePayRequest(
  BuildContext context,
  GlobalKey firstPaymentItemKey,
  LnUrlPayRequestData data,
) async {
  final NavigatorState navigator = Navigator.of(context);
  final PrepareLnUrlPayResponse? prepareResponse = await navigator.pushNamed<PrepareLnUrlPayResponse?>(
    LnUrlPaymentPage.routeName,
    arguments: data,
  );
  if (prepareResponse == null || !context.mounted) {
    return Future<LNURLPageResult?>.value();
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
        final LnUrlCubit lnurlCubit = context.read<LnUrlCubit>();
        final LnUrlPayRequest req = LnUrlPayRequest(prepareResponse: prepareResponse);
        return await lnurlCubit.lnurlPay(req: req);
      },
    ),
  ).then((dynamic result) {
    if (result is LnUrlPayResult) {
      if (result is LnUrlPayResult_EndpointSuccess) {
        _logger.info('LNURL payment success, action: ${result.data}');
        return LNURLPageResult(
          protocol: LnUrlProtocol.pay,
          successAction: result.data.successAction,
        );
      } else if (result is LnUrlPayResult_PayError) {
        _logger.info('LNURL payment for ${result.data.paymentHash} failed: ${result.data.reason}');
        return LNURLPageResult(
          protocol: LnUrlProtocol.pay,
          error: result.data.reason,
        );
      } else if (result is LnUrlPayResult_EndpointError) {
        _logger.info('LNURL payment failed: ${result.data.reason}');
        return LNURLPageResult(
          protocol: LnUrlProtocol.pay,
          error: result.data.reason,
        );
      }
    }
    _logger.warning('Error sending LNURL payment', result);
    throw LNURLPageResult(error: result).errorMessage;
  });
}

void handleLNURLPaymentPageResult(BuildContext context, LNURLPageResult result) {
  if (result.successAction != null) {
    _handleSuccessAction(context, result.successAction!);
  } else if (result.hasError) {
    _logger.info("Handle LNURL payment page result with error '${result.error}'");
    throw Exception(result.errorMessage);
  }
}

Future<void> _handleSuccessAction(BuildContext context, SuccessActionProcessed successAction) {
  String message = '';
  String? url;
  if (successAction is SuccessActionProcessed_Message) {
    message = successAction.data.message;
    _logger.info("Handle LNURL payment page result with message action '$message'");
  } else if (successAction is SuccessActionProcessed_Url) {
    message = successAction.data.description;
    url = successAction.data.url;
    _logger.info("Handle LNURL payment page result with url action '$message', '$url'");
  } else if (successAction is SuccessActionProcessed_Aes) {
    final AesSuccessActionDataResult result = successAction.result;
    if (result is AesSuccessActionDataResult_Decrypted) {
      message = '${result.data.description} ${result.data.plaintext}';
      _logger.info("Handle LNURL payment page result with aes action '$message'");
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
