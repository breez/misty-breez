import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

class StatusText extends StatelessWidget {
  const StatusText({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SdkConnectivityCubit, SdkConnectivityState>(
      builder: (BuildContext context, SdkConnectivityState sdkConnectivityState) {
        switch (sdkConnectivityState) {
          case SdkConnectivityState.connecting:
            return const LoadingAnimatedText();
          case SdkConnectivityState.connected:
            final BreezTranslations texts = context.texts();
            final ThemeData themeData = Theme.of(context);

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
