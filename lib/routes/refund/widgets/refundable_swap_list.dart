import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/routes.dart';

class RefundableSwapList extends StatelessWidget {
  final List<RefundableSwap> refundables;

  const RefundableSwapList({required this.refundables, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: refundables.length,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: <Widget>[
              RefundItem(refundables[index]),
              if (index != refundables.length) ...<Widget>[
                const Divider(
                  height: 0.0,
                  color: Color.fromRGBO(255, 255, 255, 0.52),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
