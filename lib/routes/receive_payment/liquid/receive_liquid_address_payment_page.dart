import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

/// Page that displays the user's Liquid address for receiving payments.
///
/// Liquid receives do not go through the Boltz swapper, so this page has no
/// fee message box and no payment limits bottom bar.
class ReceiveLiquidAddressPage extends StatefulWidget {
  static const String routeName = '/liquid_address';
  static const int pageIndex = 4;

  const ReceiveLiquidAddressPage({super.key});

  @override
  State<StatefulWidget> createState() => ReceiveLiquidAddressPageState();
}

class ReceiveLiquidAddressPageState extends State<ReceiveLiquidAddressPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiquidAddressCubit>().generateLiquidAddress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return BlocBuilder<LiquidAddressCubit, LiquidAddressState>(
      builder: (BuildContext context, LiquidAddressState state) {
        return Scaffold(
          body: _buildContent(state),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: SingleButtonBottomBar(
              stickToBottom: true,
              text: state.hasError
                  ? texts.invoice_btc_address_action_retry
                  : texts.qr_code_dialog_action_close,
              onPressed: state.hasError
                  ? () => context.read<LiquidAddressCubit>().generateLiquidAddress()
                  : () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(LiquidAddressState state) {
    if (state.isLoading) {
      return const CenteredLoader();
    }

    if (state.hasError) {
      return _LiquidAddressErrorView(error: state.error!);
    }

    if (state.hasValidAddress) {
      return _LiquidAddressSuccessView(address: state.address!);
    }

    return const SizedBox.shrink();
  }
}

class _LiquidAddressSuccessView extends StatelessWidget {
  final String address;

  const _LiquidAddressSuccessView({required this.address});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SingleChildScrollView(
        child: Container(
          decoration: ShapeDecoration(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            color: themeData.customData.surfaceBgColor,
          ),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
          // TODO(erdemyerebasmaz): Add message to Breez-Translations
          child: DestinationWidget(destination: address, paymentLabel: 'Liquid Address'),
        ),
      ),
    );
  }
}

class _LiquidAddressErrorView extends StatelessWidget {
  final Object error;

  const _LiquidAddressErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => context.read<LiquidAddressCubit>().generateLiquidAddress(),
        child: WarningBox(
          boxPadding: EdgeInsets.zero,
          backgroundColor: themeData.colorScheme.error.withValues(alpha: .1),
          contentPadding: const EdgeInsets.all(16.0),
          child: RichText(
            text: TextSpan(
              text: ExceptionHandler.extractMessage(error, texts),
              style: themeData.textTheme.bodyLarge?.copyWith(color: themeData.colorScheme.error),
              children: <InlineSpan>[
                TextSpan(
                  // TODO(erdemyerebasmaz): Add message to Breez-Translations
                  text: '\n\nTap here to retry',
                  style: themeData.textTheme.titleLarge?.copyWith(
                    color: themeData.colorScheme.error.withValues(alpha: .7),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
