import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/payment_status_sheets/processing_payment_sheet.dart';
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

  // Show Processing Payment Sheet
  return await showProcessingPaymentSheet(
    context,
    isLnUrlPayment: true,
    paymentFunc: () async {
      final LnUrlCubit lnurlCubit = context.read<LnUrlCubit>();
      final LnUrlPayRequest req = LnUrlPayRequest(prepareResponse: prepareResponse);
      return await lnurlCubit.lnurlPay(req: req);
    },
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
    // TODO(erdemyerebasmaz): Remove _handleSuccessAction or refactor it to only log success action message contents
    _handleSuccessAction(context, result.successAction!);
  } else if (result.hasError) {
    _logger.info("Handle LNURL payment page result with error '${result.error}'");
    throw Exception(result.errorMessage);
  }
}

void _handleSuccessAction(BuildContext context, SuccessActionProcessed successAction) {
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
}
