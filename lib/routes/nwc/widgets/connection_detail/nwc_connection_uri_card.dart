import 'package:flutter/material.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/widgets.dart';

class NwcConnectionUriCard extends StatelessWidget {
  final String connectionString;
  final VoidCallback onShowQr;

  const NwcConnectionUriCard({required this.connectionString, required this.onShowQr, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: themeData.customData.surfaceBgColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ShareablePaymentRow(
            title: 'Connection URI',
            sharedValue: connectionString,
            tilePadding: EdgeInsets.zero,
            dividerColor: Colors.transparent,
            shouldPop: false,
            titleTextStyle: themeData.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            childrenTextStyle: themeData.primaryTextTheme.displaySmall!.copyWith(
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.156,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            ),
            icon: const Padding(padding: EdgeInsets.only(right: 8.0), child: Icon(Icons.qr_code, size: 20.0)),
            label: const Text('SHOW QR'),
            onPressed: onShowQr,
          ),
        ],
      ),
    );
  }
}
