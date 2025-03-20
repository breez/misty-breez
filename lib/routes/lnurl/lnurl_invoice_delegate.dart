import 'package:flutter/material.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:logging/logging.dart';

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
      break;
  }
}
