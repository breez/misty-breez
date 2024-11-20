import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;

class GetRefundPage extends StatelessWidget {
  static const String routeName = '/get_refund';

  const GetRefundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Scaffold(
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.get_refund_title),
      ),
      body: BlocBuilder<RefundCubit, RefundState>(
        builder: (BuildContext context, RefundState refundState) {
          final List<RefundableSwap>? refundables = refundState.refundables;
          if (refundables == null || refundables.isEmpty) {
            return Center(
              child: Text(texts.get_refund_no_refundable_items),
            );
          }

          return RefundableSwapList(refundables: refundables);
        },
      ),
    );
  }
}
