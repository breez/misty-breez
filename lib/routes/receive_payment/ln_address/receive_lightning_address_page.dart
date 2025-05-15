import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/widgets.dart';

/// Page that displays the user's Lightning Address for receiving payments.
class ReceiveLightningAddressPage extends StatefulWidget {
  static const String routeName = '/lightning_address';
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
          body: _getLnAddressContent(lnAddressState),
          bottomNavigationBar: BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
            builder: (BuildContext context, PaymentLimitsState limitsState) {
              final bool hasError = limitsState.hasError;

              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SingleButtonBottomBar(
                  stickToBottom: true,
                  text: hasError ? texts.invoice_ln_address_action_retry : texts.qr_code_dialog_action_close,
                  onPressed: hasError ? () => _fetchLightningLimits() : () => Navigator.of(context).pop(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _getLnAddressContent(LnAddressState lnAddressState) {
    if (lnAddressState.isLoading) {
      return const CenteredLoader();
    }

    if (lnAddressState.isSuccess && lnAddressState.hasValidLnUrl) {
      return LnAddressSuccessView(lnAddressState: lnAddressState);
    }

    return const SizedBox.shrink();
  }

  void _fetchLightningLimits() {
    final PaymentLimitsCubit paymentLimitsCubit = context.read<PaymentLimitsCubit>();
    paymentLimitsCubit.fetchLightningLimits();
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
          ],
        ),
      ),
    );
  }
}
