import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/receive_payment/widgets/address_header_widget.dart';
import 'package:l_breez/routes/receive_payment/widgets/address_qr_widget.dart';

enum AddressWidgetType { lightning, bitcoin }

class AddressWidget extends StatelessWidget {
  final String? address;
  final AsyncSnapshot<ReceivePaymentResponse>? snapshot;
  final String? footer;
  final String? title;
  final void Function()? onLongPress;
  final AddressWidgetType type;
  final Widget? feeWidget;

  const AddressWidget({
    this.snapshot,
    super.key,
    this.footer,
    this.title,
    this.onLongPress,
    this.type = AddressWidgetType.lightning,
    this.feeWidget,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: AddressHeaderWidget(
            snapshot: snapshot,
            address: address,
            title: title,
            type: type,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: AddressQRWidget(
            address: address,
            snapshot: snapshot,
            feeWidget: feeWidget,
            footer: footer,
            onLongPress: onLongPress,
            type: type,
          ),
        ),
      ],
    );
  }
}
