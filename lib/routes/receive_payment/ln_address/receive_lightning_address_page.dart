import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/receive_payment/widgets/widgets.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/widgets.dart';

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
    final ThemeData themeData = Theme.of(context);

    return BlocBuilder<LnAddressCubit, LnAddressState>(
      builder: (BuildContext context, LnAddressState lnAddressState) {
        return Scaffold(
          body: lnAddressState.status == LnAddressStatus.loading
              ? Center(
                  child: Loader(
                    color: themeData.primaryColor.withValues(alpha: .5),
                  ),
                )
              : lnAddressState.status == LnAddressStatus.error
                  ? ScrollableErrorMessageWidget(
                      showIcon: true,
                      title: texts.lightning_address_service_error_title,
                      message: extractExceptionMessage(lnAddressState.error!, texts),
                    )
                  : lnAddressState.status == LnAddressStatus.success && lnAddressState.lnurl != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 32.0, bottom: 40.0),
                          child: SingleChildScrollView(
                            child: Container(
                              decoration: const ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                color: Color.fromRGBO(10, 20, 40, 1),
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
                        )
                      : const SizedBox.shrink(),
          bottomNavigationBar: BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
            builder: (BuildContext context, PaymentLimitsState limitsState) {
              final bool hasError = lnAddressState.status == LnAddressStatus.error || limitsState.hasError;

              return SingleButtonBottomBar(
                stickToBottom: true,
                text: hasError ? texts.invoice_ln_address_action_retry : texts.qr_code_dialog_action_close,
                onPressed:
                    hasError ? _handleRetry(lnAddressState, limitsState) : () => Navigator.of(context).pop(),
              );
            },
          ),
        );
      },
    );
  }

  VoidCallback _handleRetry(LnAddressState state, PaymentLimitsState limitsState) {
    return () {
      if (state.status == LnAddressStatus.error) {
        final LnAddressCubit lnAddressCubit = context.read<LnAddressCubit>();
        lnAddressCubit.setupLightningAddress(isRecover: true);
      } else if (limitsState.hasError) {
        final PaymentLimitsCubit paymentLimitsCubit = context.read<PaymentLimitsCubit>();
        paymentLimitsCubit.fetchLightningLimits();
      }
    };
  }
}
