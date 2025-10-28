import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/utils/exceptions/exception_handler.dart';
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
    arguments: LnUrlPaymentArguments(requestData: requestData, bip353Address: bip353Address),
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
        pageResult = LNURLPageResult(protocol: LnUrlProtocol.pay, successAction: result.data.successAction);
      } else if (result is LnUrlPayResult_PayError) {
        _logger.info('LNURL payment for ${result.data.paymentHash} failed: ${result.data.reason}');
        pageResult = LNURLPageResult(protocol: LnUrlProtocol.pay, error: result.data.reason);
      } else if (result is LnUrlPayResult_EndpointError) {
        _logger.info('LNURL payment failed: ${result.data.reason}');
        pageResult = LNURLPageResult(protocol: LnUrlProtocol.pay, error: result.data.reason);
      }
    }

    if (result is PaymentError_PaymentTimeout) {
      pageResult = null;
    } else {
      _logger.warning('Error sending LNURL payment', result);
      pageResult = LNURLPageResult(error: result);
    }

    // Navigate to home after handling the result
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(Home.routeName, (Route<dynamic> route) => false);

      // Payment timeout doesn't necessarily mean the payment failed.
      // We're popping to Home page to avoid user retries and duplicate payments.
      if (result is PaymentError_PaymentTimeout) {
        final ThemeData themeData = Theme.of(context);
        promptError(
          context,
          title: context.texts().unexpected_error_title,
          body: Text(
            ExceptionHandler.extractMessage(result, context.texts()),
            style: themeData.dialogTheme.contentTextStyle,
          ),
        );
      } else if (pageResult != null && pageResult.hasError) {
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
