import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/receive_payment/widgets/widgets.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/utils.dart';
import 'package:l_breez/widgets/widgets.dart';

/// Page that displays the user's Lightning Address for receiving payments.
class ReceiveLightningAddressPage extends StatefulWidget {
  /// Route name for navigation
  static const String routeName = '/lightning_address';

  /// Index in tab navigation
  static const int pageIndex = 1;

  const ReceiveLightningAddressPage({super.key});

  @override
  State<StatefulWidget> createState() => ReceiveLightningAddressPageState();
}

class ReceiveLightningAddressPageState extends State<ReceiveLightningAddressPage> {
  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return BlocBuilder<LnAddressCubit, LnAddressState>(
      builder: (BuildContext context, LnAddressState lnAddressState) {
        return Scaffold(
          body: _getLnAddressContent(lnAddressState, texts),
          bottomNavigationBar: BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
            builder: (BuildContext context, PaymentLimitsState limitsState) {
              final bool hasError = lnAddressState.hasError || limitsState.hasError;

              return SingleButtonBottomBar(
                stickToBottom: true,
                text: hasError ? texts.invoice_ln_address_action_retry : texts.qr_code_dialog_action_close,
                onPressed: hasError
                    ? () => _onRetryPressed(lnAddressState, limitsState)
                    : () => Navigator.of(context).pop(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _getLnAddressContent(LnAddressState lnAddressState, BreezTranslations texts) {
    if (lnAddressState.isLoading) {
      return const LnAddressLoadingView();
    }

    if (lnAddressState.hasError) {
      return LnAddressErrorView(
        title: texts.lightning_address_service_error_title,
        error: lnAddressState.error!,
      );
    }

    if (lnAddressState.isSuccess && lnAddressState.hasValidLnUrl) {
      return LnAddressSuccessView(lnAddressState: lnAddressState);
    }

    return const SizedBox.shrink();
  }

  void _onRetryPressed(LnAddressState lnAddressState, PaymentLimitsState limitsState) {
    if (lnAddressState.hasError) {
      final LnAddressCubit lnAddressCubit = context.read<LnAddressCubit>();
      lnAddressCubit.setupLightningAddress(isRecover: true);
    } else if (limitsState.hasError) {
      final PaymentLimitsCubit paymentLimitsCubit = context.read<PaymentLimitsCubit>();
      paymentLimitsCubit.fetchLightningLimits();
    }
  }
}

/// Widget to display loading indicator for Lightning Address
class LnAddressLoadingView extends StatelessWidget {
  const LnAddressLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return Center(
      child: Loader(
        color: themeData.primaryColor.withValues(alpha: .5),
      ),
    );
  }
}

/// Widget to display error state for Lightning Address
class LnAddressErrorView extends StatelessWidget {
  final String title;
  final Object error;

  const LnAddressErrorView({
    required this.title,
    required this.error,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    return ScrollableErrorMessageWidget(
      showIcon: true,
      title: title,
      message: ExceptionHandler.extractMessage(error, texts),
    );
  }
}

/// Widget to display successful Lightning Address state
class LnAddressSuccessView extends StatelessWidget {
  final LnAddressState lnAddressState;

  const LnAddressSuccessView({
    required this.lnAddressState,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 32.0, bottom: 40.0),
      child: SingleChildScrollView(
        child: Container(
          decoration: ShapeDecoration(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(12),
              ),
            ),
            color: themeData.customData.surfaceBgColor,
          ),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
          child: SingleChildScrollView(
            child: DestinationWidget(
              destination: lnAddressState.lnurl,
              lnAddress: lnAddressState.lnAddress,
              paymentMethod: texts.receive_payment_method_lightning_address,
              infoWidget: const PaymentLimitsMessageBox(),
            ),
          ),
        ),
      ),
    );
  }
}
