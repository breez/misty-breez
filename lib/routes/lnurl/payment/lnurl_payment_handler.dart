import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:provider/provider.dart';

final Logger _logger = Logger('HandleLNURLPayRequest');

Future<LNURLPageResult?> handlePayRequest(
  BuildContext context,
  GlobalKey firstPaymentItemKey,
  LnUrlPayRequestData requestData, {
  String? bip353Address,
}) async {
  final NavigatorState navigator = Navigator.of(context);
  final PrepareLnUrlPayResponse? prepareResponse = await navigator.pushNamed<PrepareLnUrlPayResponse?>(
    LnUrlPaymentPage.routeName,
    arguments: LnUrlPaymentArguments(
      requestData: requestData,
      bip353Address: bip353Address,
    ),
  );
  if (prepareResponse == null || !context.mounted) {
    return Future<LNURLPageResult?>.value();
  }

  // Show Processing Payment Sheet
  return await showProcessingPaymentSheet(
    context,
    isLnUrlPayment: true,
    popToHomeOnCompletion: false,
    paymentFunc: () async {
      final LnUrlService lnUrlService = Provider.of<LnUrlService>(context, listen: false);
      final LnUrlPayRequest req = LnUrlPayRequest(prepareResponse: prepareResponse);
      return await lnUrlService.lnurlPay(req: req);
    },
  ).then((dynamic result) {
    LNURLPageResult? pageResult;

    if (result is LnUrlPayResult) {
      if (result is LnUrlPayResult_EndpointSuccess) {
        _logger.info('LNURL payment success, action: ${result.data}');
        pageResult = LNURLPageResult(
          protocol: LnUrlProtocol.pay,
          successAction: result.data.successAction,
        );
      } else if (result is LnUrlPayResult_PayError) {
        _logger.info('LNURL payment for ${result.data.paymentHash} failed: ${result.data.reason}');
        pageResult = LNURLPageResult(
          protocol: LnUrlProtocol.pay,
          error: result.data.reason,
        );
      } else if (result is LnUrlPayResult_EndpointError) {
        _logger.info('LNURL payment failed: ${result.data.reason}');
        pageResult = LNURLPageResult(
          protocol: LnUrlProtocol.pay,
          error: result.data.reason,
        );
      }
    }

    if (pageResult == null) {
      _logger.warning('Error sending LNURL payment', result);
      pageResult = LNURLPageResult(error: result);
    }

    // Navigate to home after handling the result
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(Home.routeName, (Route<dynamic> route) => false);
      if (pageResult.hasError) {
        showFlushbar(context, message: pageResult.errorMessage);
      }
    }

    return pageResult;
  });
}

void handleLNURLPaymentPageResult(BuildContext context, LNURLPageResult result) {
  if (result.successAction != null) {
    _logger.info('LNURL payment completed with success action');
    _logSuccessAction(result.successAction!);
  } else if (result.hasError) {
    _logger.info("LNURL payment completed with error '${result.error}'");
  }
}

void _logSuccessAction(SuccessActionProcessed successAction) {
  if (successAction is SuccessActionProcessed_Message) {
    _logger.info("Success action message: '${successAction.data.message}'");
  } else if (successAction is SuccessActionProcessed_Url) {
    _logger.info("Success action URL: '${successAction.data.description}', '${successAction.data.url}'");
  } else if (successAction is SuccessActionProcessed_Aes) {
    final AesSuccessActionDataResult result = successAction.result;
    if (result is AesSuccessActionDataResult_Decrypted) {
      _logger.info("Success action AES: '${result.data.description} ${result.data.plaintext}'");
    } else if (result is AesSuccessActionDataResult_ErrorStatus) {
      _logger.warning("Success action AES error: '${result.reason}'");
    }
  }
}
