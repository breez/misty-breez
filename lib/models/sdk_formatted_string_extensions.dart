import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/models/payment_details_extension.dart';

extension RefundableSwapFormatter on RefundableSwap {
  String toFormattedString() => 'RefundableSwap('
      'swapAddress: $swapAddress, '
      'timestamp: $timestamp, '
      'amountSat: $amountSat, '
      'lastRefundTxId: ${lastRefundTxId ?? "N/A"}'
      ')';
}

extension RecommendedFeesFormatter on RecommendedFees {
  String toFormattedString() => 'RecommendedFees('
      'fastestFee: $fastestFee, '
      'halfHourFee: $halfHourFee, '
      'hourFee: $hourFee, '
      'economyFee: $economyFee, '
      'minimumFee: $minimumFee'
      ')';
}

extension PaymentEventFormatter on PaymentEvent {
  String toFormattedString() {
    final String sdkEventStr = sdkEvent.toFormattedString();
    final String paymentStr = payment.toFormattedString();

    if (sdkEventStr.contains(paymentStr)) {
      return 'PaymentEvent(sdkEvent: $sdkEventStr)';
    }

    return 'PaymentEvent(sdkEvent: $sdkEventStr, payment: $paymentStr)';
  }
}

extension SdkEventFormatter on SdkEvent {
  String toFormattedString() {
    if (this is SdkEvent_PaymentFailed) {
      return 'PaymentFailed(details: ${(this as SdkEvent_PaymentFailed).details.toFormattedString()})';
    } else if (this is SdkEvent_PaymentPending) {
      return 'PaymentPending(details: ${(this as SdkEvent_PaymentPending).details.toFormattedString()})';
    } else if (this is SdkEvent_PaymentRefundable) {
      return 'PaymentRefundable(details: ${(this as SdkEvent_PaymentRefundable).details.toFormattedString()})';
    } else if (this is SdkEvent_PaymentRefunded) {
      return 'PaymentRefunded(details: ${(this as SdkEvent_PaymentRefunded).details.toFormattedString()})';
    } else if (this is SdkEvent_PaymentRefundPending) {
      return 'PaymentRefundPending(details: ${(this as SdkEvent_PaymentRefundPending).details.toFormattedString()})';
    } else if (this is SdkEvent_PaymentSucceeded) {
      return 'PaymentSucceeded(details: ${(this as SdkEvent_PaymentSucceeded).details.toFormattedString()})';
    } else if (this is SdkEvent_PaymentWaitingConfirmation) {
      return 'PaymentWaitingConfirmation(details: ${(this as SdkEvent_PaymentWaitingConfirmation).details.toFormattedString()})';
    } else if (this is SdkEvent_PaymentWaitingFeeAcceptance) {
      return 'PaymentWaitingFeeAcceptance(details: ${(this as SdkEvent_PaymentWaitingFeeAcceptance).details.toFormattedString()})';
    } else if (this is SdkEvent_Synced) {
      return 'Synced';
    } else {
      return 'Unknown SdkEvent';
    }
  }
}

extension PaymentFormatter on Payment {
  String toFormattedString() => 'Payment('
      'destination: ${destination ?? "N/A"}, '
      'txId: ${txId ?? "N/A"}, '
      'amountSat: $amountSat, '
      'feesSat: $feesSat, '
      'swapperFeesSat: ${swapperFeesSat ?? "N/A"}, '
      'paymentType: $paymentType, '
      'status: $status, '
      'details: ${details.toFormattedString()}'
      ')';
}

extension PreparePayOnchainResponseFormatted on PreparePayOnchainResponse {
  String toFormattedString() => 'PreparePayOnchainResponse('
      'receiverAmountSat: $receiverAmountSat, '
      'claimFeesSat: $claimFeesSat, '
      'totalFeesSat: $totalFeesSat'
      ')';
}

extension PrepareRefundResponseFormatted on PrepareRefundResponse {
  String toFormattedString() => 'PrepareRefundResponse('
      'txVsize: $txVsize, '
      'txFeeSat: $txFeeSat, '
      'lastRefundTxId: ${lastRefundTxId ?? 'N/A'} '
      ')';
}

extension RefundRequestFormatted on RefundRequest {
  String toFormattedString() => 'RefundRequest('
      'swapAddress: $swapAddress, '
      'refundAddress: $refundAddress, '
      'feeRateSatPerVbyte: $feeRateSatPerVbyte'
      ')';
}
