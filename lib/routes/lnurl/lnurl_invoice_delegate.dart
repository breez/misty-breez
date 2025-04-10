import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/routes/routes.dart';

final Logger _logger = Logger('HandleLNURL');

void handleLNURLPageResult(BuildContext context, LNURLPageResult result) {
  _logger.info('handle $result');
  switch (result.protocol) {
    case LnUrlProtocol.pay:
      handleLNURLPaymentPageResult(context, result);
      break;
    case LnUrlProtocol.withdraw:
      handleLNURLWithdrawPageResult(context, result);
      break;
    case LnUrlProtocol.auth:
      handleLNURLAuthPageResult(context, result);
      break;
    default:
      // Pop to Home page for unrecognized LNURLPageResult protocols
      Navigator.of(context).pushNamedAndRemoveUntil(Home.routeName, (Route<dynamic> route) => false);
      break;
  }
}
