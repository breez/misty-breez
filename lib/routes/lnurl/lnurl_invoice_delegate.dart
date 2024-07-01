import 'package:l_breez/routes/lnurl/payment/lnurl_payment_handler.dart';
import 'package:l_breez/routes/lnurl/withdraw/lnurl_withdraw_handler.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'widgets/lnurl_page_result.dart';

final _log = Logger("HandleLNURL");

void handleLNURLPageResult(BuildContext context, LNURLPageResult result) {
  _log.info("handle $result");
  switch (result.protocol) {
    case LnUrlProtocol.Pay:
      handleLNURLPaymentPageResult(context, result);
      break;
    case LnUrlProtocol.Withdraw:
      handleLNURLWithdrawPageResult(context, result);
      break;
    default:
      break;
  }
}
