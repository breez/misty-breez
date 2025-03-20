import 'package:breez_liquid/breez_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;

export 'widgets/widgets.dart';

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: SingleChildScrollView(
          child: BlocBuilder<RefundCubit, RefundState>(
            builder: (BuildContext context, RefundState refundState) {
              return RefundableSwapList(
                refundables: refundState.refundables ?? <RefundableSwap>[],
              );
            },
          ),
        ),
      ),
    );
  }
}
