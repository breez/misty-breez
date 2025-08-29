import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';

class PaymentFilterExporter extends StatelessWidget {
  final List<PaymentType>? filter;

  const PaymentFilterExporter(this.filter, {super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return PopupMenuButton<VoidCallback>(
      color: themeData.customData.paymentListBgColorLight,
      icon: Icon(Icons.more_vert, color: themeData.paymentItemTitleTextStyle.color),
      padding: EdgeInsets.zero,
      offset: const Offset(12, 24),
      onSelected: (VoidCallback action) => action(),
      itemBuilder: (BuildContext context) => <PopupMenuItem<VoidCallback>>[
        PopupMenuItem<VoidCallback>(
          height: 36,
          value: () async => await exportPayments(context),
          child: Text(texts.payments_filter_action_export, style: themeData.textTheme.labelLarge),
        ),
      ],
    );
  }
}
