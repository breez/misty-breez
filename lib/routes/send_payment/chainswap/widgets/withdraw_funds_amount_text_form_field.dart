import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/payments/payment_validator.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('WithdrawFundsAmountTextFormField');

class WithdrawFundsAmountTextFormField extends AmountFormField {
  WithdrawFundsAmountTextFormField({
    required super.bitcoinCurrency,
    required super.context,
    required TextEditingController super.controller,
    required FocusNode focusNode,
    required bool isDrain,
    required WithdrawFundsPolicy policy,
    required BigInt balance,
    super.key,
  }) : super(
          texts: context.texts(),
          enableInteractiveSelection: !isDrain,
          readOnly: policy.withdrawKind == WithdrawKind.unexpectedFunds || isDrain,
          focusNode: isDrain ? null : focusNode,
          validatorFn: (int amount) {
            _logger.info('Validator called for $amount');
            return PaymentValidator(
              currency: bitcoinCurrency,
              texts: context.texts(),
              validatePayment: (int amount, bool outgoing) {
                _logger.info('Validating $amount $policy');
                if (outgoing && amount > balance.toInt()) {
                  throw const InsufficientLocalBalanceError();
                }
                if (amount < policy.minValue.toInt()) {
                  throw PaymentBelowLimitError(policy.minValue.toInt());
                }
                if (amount > policy.maxValue.toInt()) {
                  throw PaymentExceedsLimitError(policy.maxValue.toInt());
                }
              },
            ).validateOutgoing(amount);
          },
        );
}
