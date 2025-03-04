import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class RefundItemCardOriginalTx extends StatelessWidget {
  final String swapAddress;
  final AutoSizeGroup? labelAutoSizeGroup;

  const RefundItemCardOriginalTx({
    required this.swapAddress,
    this.labelAutoSizeGroup,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AutoSizeText(
            // TODO(erdemyerebasmaz): Add message to Breez-Translations
            'Transaction:',
            style: themeData.primaryTextTheme.headlineMedium?.copyWith(
              fontSize: 18.0,
              color: Colors.white,
            ),
            textAlign: TextAlign.left,
            maxLines: 1,
            group: labelAutoSizeGroup,
          ),
        ),
        Expanded(
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
