import 'package:flutter/material.dart';
import 'package:l_breez/cubit/payments/models/models.dart';
import 'package:l_breez/routes/home/widgets/payments_list/flip_transition.dart';
import 'package:l_breez/routes/home/widgets/payments_list/payment_details_dialog.dart';
import 'package:l_breez/routes/home/widgets/payments_list/payment_item_amount.dart';
import 'package:l_breez/routes/home/widgets/payments_list/payment_item_avatar.dart';
import 'package:l_breez/routes/home/widgets/payments_list/payment_item_subtitle.dart';
import 'package:l_breez/routes/home/widgets/payments_list/payment_item_title.dart';
import 'package:l_breez/routes/home/widgets/payments_list/success_avatar.dart';
import 'package:l_breez/theme/theme.dart';

class PaymentItem extends StatefulWidget {
  final PaymentData paymentData;
  final bool _firstItem;
  final GlobalKey firstPaymentItemKey;

  const PaymentItem(
    this.paymentData,
    this._firstItem,
    this.firstPaymentItemKey, {
    super.key,
  });

  @override
  State<PaymentItem> createState() => _PaymentItemState();
}

class _PaymentItemState extends State<PaymentItem> {
  late bool isPaymentItemNew;

  @override
  void initState() {
    super.initState();
    setState(() {
      isPaymentItemNew = _createdWithin(const Duration(seconds: 15));
    });
  }

  @override
  void didUpdateWidget(PaymentItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paymentData != oldWidget.paymentData) {
      setState(() {
        isPaymentItemNew = _createdWithin(const Duration(seconds: 15));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          color: Theme.of(context).customData.paymentListBgColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ListTile(
                leading: Container(
                  height: 72.0,
                  decoration: isPaymentItemNew
                      ? null
                      : BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0.5, 0.5),
                              blurRadius: 5.0,
                            ),
                          ],
                        ),
                  child: isPaymentItemNew
                      ? FlipTransition(
                          PaymentItemAvatar(
                            widget.paymentData,
                            radius: 16,
                          ),
                          const SuccessAvatar(radius: 16),
                          radius: 16,
                          onComplete: () {
                            setState(() {
                              isPaymentItemNew = false;
                            });
                          },
                        )
                      : PaymentItemAvatar(widget.paymentData, radius: 16),
                ),
                key: widget._firstItem ? widget.firstPaymentItemKey : null,
                title: Transform.translate(
                  offset: const Offset(-8, 0),
                  child: PaymentItemTitle(widget.paymentData),
                ),
                subtitle: Transform.translate(
                  offset: const Offset(-8, 0),
                  child: PaymentItemSubtitle(widget.paymentData),
                ),
                trailing: PaymentItemAmount(widget.paymentData),
                onTap: () {
                  showDialog<void>(
                    useRootNavigator: false,
                    context: context,
                    builder: (_) => PaymentDetailsDialog(
                      paymentData: widget.paymentData,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _createdWithin(Duration duration) {
    final diff = widget.paymentData.paymentTime.difference(DateTime.now());
    return diff > -duration;
  }
}
