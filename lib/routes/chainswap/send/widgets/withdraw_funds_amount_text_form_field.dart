import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/chainswap/send/withdraw_funds_model.dart';
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/amount_form_field/amount_form_field.dart';
import 'package:logging/logging.dart';

final _logger = Logger("WithdrawFundsAmountTextFormField");

class WithdrawFundsAmountTextFormField extends AmountFormField {
  WithdrawFundsAmountTextFormField({
    super.key,
    required super.bitcoinCurrency,
    required super.context,
    required TextEditingController super.controller,
    required bool withdrawMaxValue,
    required WithdrawFundsPolicy policy,
    required BigInt balance,
  }) : super(
          texts: context.texts(),
          readOnly: policy.withdrawKind == WithdrawKind.unexpectedFunds || withdrawMaxValue,
          validatorFn: (amount) {
            _logger.info("Validator called for $amount");
            return PaymentValidator(
              currency: bitcoinCurrency,
              texts: context.texts(),
              validatePayment: (amount, outgoing) {
                _logger.info("Validating $amount $policy");
                if (outgoing && amount > balance.toInt()) {
                  throw const InsufficientLocalBalanceError();
                }
                if (amount < policy.minValue.toInt()) {
                  throw PaymentBelowLimitError(policy.minValue.toInt());
                }
                if (amount > policy.maxValue.toInt()) {
                  throw PaymentExceededLimitError(policy.maxValue.toInt());
                }
              },
            ).validateOutgoing(amount);
          },
        );
}
