import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/min_font_size.dart';
import 'package:l_breez/widgets/loading_animated_text.dart';

class StatusText extends StatelessWidget {
  const StatusText({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, accountState) {
        return (!accountState.didCompleteInitialSync)
            ? const LoadingAnimatedText()
            : const SdkConnectivityStatusText();
      },
    );
  }
}

class SdkConnectivityStatusText extends StatelessWidget {
  const SdkConnectivityStatusText({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SdkConnectivityCubit, SdkConnectivityState>(
      builder: (context, sdkConnectivityState) {
        switch (sdkConnectivityState) {
          case SdkConnectivityState.connecting:
            return const LoadingAnimatedText();
          case SdkConnectivityState.connected:
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
      },
    );
  }
}
