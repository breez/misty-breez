import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/payments/models/payment/payment_data.dart';
import 'package:l_breez/models/payment_details_extension.dart';
import 'package:l_breez/widgets/shareable_payment_row.dart';

class PaymentDetailsSwapId extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsSwapId({required this.paymentData, super.key});

  @override
  Widget build(BuildContext context) {
    final String swapId = paymentData.details.map(
      bitcoin: (PaymentDetails_Bitcoin details) => details.swapId,
      lightning: (PaymentDetails_Lightning details) => details.swapId,
      orElse: () => '',
    );

    if (swapId.isEmpty) {
      return const SizedBox.shrink();
    }

    final BreezTranslations texts = context.texts();

    return ShareablePaymentRow(
      title: texts.payment_details_dialog_single_info_swap_id,
      sharedValue: swapId,
    );
  }
}
