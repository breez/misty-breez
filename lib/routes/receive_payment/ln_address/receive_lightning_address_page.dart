import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

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

              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SingleButtonBottomBar(
                  stickToBottom: true,
                  text: hasError ? texts.invoice_ln_address_action_retry : texts.qr_code_dialog_action_close,
                  onPressed: hasError
                      ? () => _onRetryPressed(lnAddressState, limitsState)
                      : () => Navigator.of(context).pop(),
                ),
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
        error: lnAddressState.error ?? '',
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

    return Column(
      children: <Widget>[
        Expanded(
          child: ScrollableErrorMessageWidget(
            showIcon: true,
            title: title,
            message: ExceptionHandler.extractMessage(error, texts),
          ),
        ),
        const SpecifyAmountButton(),
      ],
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
      padding: const EdgeInsets.only(top: 16.0),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              decoration: ShapeDecoration(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(12),
                  ),
                ),
                color: themeData.customData.surfaceBgColor,
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
              child: Column(
                children: <Widget>[
                  DestinationWidget(
                    destination: lnAddressState.lnurl,
                    lnAddress: lnAddressState.lnAddress,
                    paymentMethod: texts.receive_payment_method_lightning_address,
                    infoWidget: const PaymentLimitsMessageBox(),
                  ),
                ],
              ),
            ),
            const SpecifyAmountButton(),
          ],
        ),
      ),
    );
  }
}

/// Button to navigate to the Lightning payment page for specifying an amount
class SpecifyAmountButton extends StatelessWidget {
  const SpecifyAmountButton({super.key});

  @override
  Widget build(BuildContext context) {
    //final BreezTranslations texts = context.texts();
    final MinFontSize minFont = MinFontSize(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 48.0,
          minWidth: 138.0,
        ),
        child: Tooltip(
          // TODO(erdemyerebasmaz): Add message to Breez-Translations
          message: 'Specify amount for invoice',
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(
              Icons.edit_note,
              size: 20.0,
            ),
            label: AutoSizeText(
              // TODO(erdemyerebasmaz): Add message to Breez-Translations
              'Specify Amount',
              style: balanceFiatConversionTextStyle,
              maxLines: 1,
              minFontSize: minFont.minFontSize,
              stepGranularity: 0.1,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed(
                ReceivePaymentPage.routeName,
                arguments: ReceiveLightningPaymentPage.pageIndex,
              );
            },
          ),
        ),
      ),
    );
  }
}
