import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/refund/widgets/widgets.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;

class GetRefundPage extends StatelessWidget {
  static const routeName = "/get_refund";

  const GetRefundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Scaffold(
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.get_refund_title),
      ),
      body: BlocBuilder<RefundCubit, RefundState>(
        builder: (context, refundState) {
          final refundables = refundState.refundables;
          if (refundables == null || refundables.isEmpty) {
            return Center(child: Text(texts.get_refund_no_refundable_items));
          }

          return RefundableSwapList(refundables: refundables);
        },
      ),
    );
  }
}
