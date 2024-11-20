import 'package:flutter/material.dart';
import 'package:l_breez/routes/lnurl/auth/lnurl_auth_handler.dart';
import 'package:l_breez/routes/lnurl/payment/lnurl_payment_handler.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_page_result.dart';
import 'package:l_breez/routes/lnurl/withdraw/lnurl_withdraw_handler.dart';
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
