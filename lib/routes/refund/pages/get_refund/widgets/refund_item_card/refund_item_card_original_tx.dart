import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';

class RefundItemCardOriginalTx extends StatelessWidget {
  final String swapAddress;

  const RefundItemCardOriginalTx({required this.swapAddress, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            '${texts.send_on_chain_original_transaction}:',
            style: themeData.primaryTextTheme.headlineMedium?.copyWith(
              fontSize: 18.0,
              color: Colors.white,
            ),
          ),
          Flexible(
            child: Text(
              _formatAddress(swapAddress),
              style: themeData.primaryTextTheme.displaySmall!.copyWith(
                fontSize: 18.0,
                color: Colors.white,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format address for display
  String _formatAddress(String address) {
    if (address.length < 16) {
      return address;
    }
    return '${address.substring(0, 8)}...${address.substring(address.length - 8)}';
  }
}
