import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/src/theme.dart';

class RefundItemAmount extends StatelessWidget {
  final int confirmedSats;

  const RefundItemAmount(this.confirmedSats, {super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final currencyState = context.read<CurrencyCubit>().state;

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Text(
            texts.get_refund_amount(currencyState.bitcoinCurrency.format(confirmedSats)),
            style: FieldTextStyle.textStyle,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}
