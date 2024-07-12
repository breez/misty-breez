import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/cubit/account/account_state.dart';
import 'package:l_breez/theme/theme_provider.dart';
import 'package:l_breez/utils/min_font_size.dart';
import 'package:l_breez/widgets/loading_animated_text.dart';

class StatusText extends StatelessWidget {
  final AccountState accountState;

  const StatusText({super.key, required this.accountState});

  @override
  Widget build(BuildContext context) {
    switch (accountState.connectionStatus) {
      case ConnectionStatus.connecting:
        return const LoadingAnimatedText();
      case ConnectionStatus.connected:
        final texts = context.texts();
        final themeData = Theme.of(context);

        return AutoSizeText(
          texts.status_text_ready,
          style: themeData.textTheme.bodyMedium?.copyWith(
            color: themeData.isLightTheme ? BreezColors.grey[600] : themeData.colorScheme.onSecondary,
          ),
          textAlign: TextAlign.center,
          minFontSize: MinFontSize(context).minFontSize,
          stepGranularity: 0.1,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
