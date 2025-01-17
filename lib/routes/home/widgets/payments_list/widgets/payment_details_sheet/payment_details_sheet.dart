import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/payment_details_extension.dart';
import 'package:l_breez/routes/home/widgets/payments_list/widgets/payment_details_sheet/widgets/payment_details_sheet_header.dart';
import 'package:l_breez/routes/home/widgets/widgets.dart';
import 'package:logging/logging.dart';

export 'widgets/widgets.dart';

final AutoSizeGroup _labelGroup = AutoSizeGroup();

final Logger _logger = Logger('PaymentDetailsSheet');

Future<dynamic> showPaymentDetailsSheet(
  BuildContext context, {
  required PaymentData paymentData,
}) async {
  return await showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24.0)),
    ),
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.9,
        snap: true,
        snapSizes: <double>[1.0],
        builder: (BuildContext context, ScrollController scrollController) {
          return PaymentDetailsSheet(
            paymentData: paymentData,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class PaymentDetailsSheet extends StatelessWidget {
  final PaymentData paymentData;
  final ScrollController scrollController;

  PaymentDetailsSheet({
    required this.paymentData,
    required this.scrollController,
    super.key,
  }) {
    _logger.info('PaymentDetailsSheet for payment: $paymentData');
  }

  @override
  Widget build(BuildContext context) {
    final AccountCubit accountCubit = context.read<AccountCubit>();
    final AccountState accountState = accountCubit.state;
    final ThemeData themeData = Theme.of(context);

    final String? invoice = paymentData.details.map(
      lightning: (PaymentDetails_Lightning details) => details.invoice,
      orElse: () => null,
    );

    final String destinationPubkey = paymentData.details.map(
      lightning: (PaymentDetails_Lightning details) => details.destinationPubkey ?? '',
      orElse: () => '',
    );

    final String paymentPreimage = paymentData.details.map(
      lightning: (PaymentDetails_Lightning details) => details.preimage ?? '',
      orElse: () => '',
    );

    final String swapId = paymentData.details.map(
      bitcoin: (PaymentDetails_Bitcoin details) => details.swapId,
      lightning: (PaymentDetails_Lightning details) => details.swapId,
      orElse: () => '',
    );

    final LnUrlInfo? lnurlInfo = paymentData.details.map(
      lightning: (PaymentDetails_Lightning details) => details.lnurlInfo,
      orElse: () => null,
    );

    final String lnAddress = lnurlInfo?.lnAddress ?? '';
    final String lnurlPayComment = lnurlInfo?.lnurlPayComment ?? '';
    final String lnurlPayDomain = lnurlInfo?.lnurlPayDomain ?? '';
    final (
      String lnurlPaySuccessActionDescription,
      String lnurlPaySuccessActionMessage,
      String lnurlPaySuccessActionUrl
    ) = switch (lnurlInfo?.lnurlPaySuccessAction) {
      SuccessActionProcessed_Aes(result: final AesSuccessActionDataResult result) => switch (result) {
          AesSuccessActionDataResult_Decrypted(data: final AesSuccessActionDataDecrypted data) => (
              data.description,
              data.plaintext,
              ''
            ),
          AesSuccessActionDataResult_ErrorStatus() => ('', '', ''),
        },
      SuccessActionProcessed_Message(data: final MessageSuccessActionData data) => ('', data.message, ''),
      SuccessActionProcessed_Url(data: final UrlSuccessActionData data) => (data.description, '', data.url),
      null => ('', '', ''),
    };

    final DateTime? expiryDate = paymentData.details.getExpiryDate(
      blockchainInfo: accountState.blockchainInfo,
    );

    return Container(
      height: MediaQuery.of(context).size.height - kToolbarHeight,
      width: MediaQuery.of(context).size.width,
      decoration: ShapeDecoration(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        color: themeData.canvasColor,
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            child: Column(
              children: <Widget>[
                Align(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8.0),
                    width: 40.0,
                    height: 6.5,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(50)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 32 + 24, bottom: 32.0),
                  child: PaymentDetailsSheetHeader(paymentData: paymentData),
                ),
                Container(
                  decoration: const ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(12),
                      ),
                    ),
                    color: Color.fromRGBO(40, 59, 74, 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: Column(
                    children: <Widget>[
                      PaymentDetailsSheetAmount(
                        paymentData: paymentData,
                        labelAutoSizeGroup: _labelGroup,
                      ),
                      PaymentDetailsSheetFee(
                        paymentData: paymentData,
                        labelAutoSizeGroup: _labelGroup,
                      ),
                      if (paymentData.isRefunded) ...<Widget>[
                        PaymentDetailsSheetRefundTxAmount(
                          paymentData: paymentData,
                          labelAutoSizeGroup: _labelGroup,
                        ),
                      ],
                      PaymentDetailsSheetDate(
                        paymentData: paymentData,
                        labelAutoSizeGroup: _labelGroup,
                      ),
                      if (paymentData.status == PaymentState.pending && expiryDate != null) ...<Widget>[
                        PaymentDetailsSheetExpiry(
                          expiryDate: expiryDate,
                          labelAutoSizeGroup: _labelGroup,
                        ),
                      ],
                      if (lnAddress.isNotEmpty) ...<Widget>[
                        PaymentDetailsSheetLnUrlLnAddress(lnAddress: lnAddress),
                      ],
                      if (lnurlPayComment.isNotEmpty) ...<Widget>[
                        PaymentDetailsSheetLnUrlPayComment(payComment: lnurlPayComment),
                      ],
                      if (paymentData.status == PaymentState.complete) ...<Widget>[
                        if (lnurlPaySuccessActionDescription.isNotEmpty) ...<Widget>[
                          PaymentDetailsSheetLnUrlPaySuccessDescription(
                            paySuccessDescription: lnurlPaySuccessActionDescription,
                          ),
                        ],
                        if (lnurlPaySuccessActionMessage.isNotEmpty) ...<Widget>[
                          PaymentDetailsSheetLnUrlPaySuccessMessage(
                            paySuccessMessage: lnurlPaySuccessActionMessage,
                          ),
                        ],
                        if (lnurlPaySuccessActionUrl.isNotEmpty) ...<Widget>[
                          PaymentDetailsSheetLnUrlPaySuccessUrl(paySuccessUrl: lnurlPaySuccessActionUrl),
                        ],
                      ],
                      if (lnurlPayDomain.isNotEmpty) ...<Widget>[
                        PaymentDetailsSheetLnUrlPayDomain(payDomain: lnurlPayDomain),
                      ],
                      if (invoice != null && invoice.isNotEmpty) ...<Widget>[
                        PaymentDetailsSheetInvoice(invoice: invoice),
                      ],
                      if (paymentPreimage.isNotEmpty) ...<Widget>[
                        PaymentDetailsSheetPreimage(
                          invoice: invoice,
                          paymentPreimage: paymentPreimage,
                        ),
                      ],
                      if (destinationPubkey.isNotEmpty) ...<Widget>[
                        PaymentDetailsSheetDestinationPubkey(destinationPubkey: destinationPubkey),
                      ],
                      if (paymentData.txId.isNotEmpty) ...<Widget>[
                        PaymentDetailsSheetTxId(
                          txId: paymentData.txId,
                          unblindingData: paymentData.unblindingData,
                        ),
                      ],
                      if (swapId.isNotEmpty) ...<Widget>[
                        PaymentDetailsSheetSwapId(swapId: swapId),
                      ],
                    ].expand((Widget widget) sync* {
                      yield widget;
                      yield const Divider(
                        height: 32.0,
                        color: Color.fromRGBO(40, 59, 74, 1),
                        indent: 0.0,
                        endIndent: 0.0,
                      );
                    }).toList()
                      ..removeLast(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
