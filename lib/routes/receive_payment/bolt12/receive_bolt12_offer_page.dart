import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

final Logger _logger = Logger('ReceiveBolt12OfferPage');

class ReceiveBolt12OfferPage extends StatefulWidget {
  static const String routeName = '/receive_bolt12_offer';

  const ReceiveBolt12OfferPage({super.key});

  @override
  State<StatefulWidget> createState() => _ReceiveBolt12OfferPageState();
}

class _ReceiveBolt12OfferPageState extends State<ReceiveBolt12OfferPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();
  KeyboardDoneAction _doneAction = KeyboardDoneAction();

  Future<PrepareReceiveResponse>? prepareResponseFuture;
  Future<ReceivePaymentResponse>? receivePaymentResponseFuture;

  @override
  void initState() {
    super.initState();
    _doneAction = KeyboardDoneAction(focusNodes: <FocusNode>[_descriptionFocusNode]);
    _descriptionFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _doneAction.dispose();
    _descriptionFocusNode.removeListener(_onFocusChanged);
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Scaffold(
      body: prepareResponseFuture == null
          ? Padding(
              padding: const EdgeInsets.only(top: 32, bottom: 40.0),
              child: SingleChildScrollView(
                child: _buildForm(),
              ),
            )
          : _buildOfferQRCode(),
      bottomNavigationBar: prepareResponseFuture == null && receivePaymentResponseFuture == null
          ? SingleButtonBottomBar(
              stickToBottom: true,
              text: texts.invoice_action_create,
              onPressed: _createOffer,
            )
          : FutureBuilder<PrepareReceiveResponse>(
              future: prepareResponseFuture,
              builder: (BuildContext context, AsyncSnapshot<PrepareReceiveResponse> prepareSnapshot) {
                if (prepareSnapshot.hasError) {
                  return SingleButtonBottomBar(
                    stickToBottom: true,
                    text: texts.invoice_btc_address_action_retry,
                    onPressed: _resetForm,
                  );
                }
                if (prepareSnapshot.hasData) {
                  return FutureBuilder<ReceivePaymentResponse>(
                    future: receivePaymentResponseFuture,
                    builder:
                        (BuildContext context, AsyncSnapshot<ReceivePaymentResponse> receiveSnapshot) {
                          if (receiveSnapshot.hasError) {
                            return SingleButtonBottomBar(
                              stickToBottom: true,
                              text: texts.invoice_btc_address_action_retry,
                              onPressed: _resetForm,
                            );
                          }
                          if (receiveSnapshot.hasData) {
                            return SingleButtonBottomBar(
                              stickToBottom: true,
                              text: texts.qr_code_dialog_action_close,
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }

  Widget _buildForm() {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Container(
      decoration: ShapeDecoration(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        color: themeData.customData.surfaceBgColor,
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            focusNode: _descriptionFocusNode,
            controller: _descriptionController,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.done,
            maxLines: null,
            maxLength: 90,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            decoration: InputDecoration(
              prefixIconConstraints: BoxConstraints.tight(const Size(16, 56)),
              prefixIcon: const SizedBox.shrink(),
              contentPadding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
              border: const OutlineInputBorder(),
              labelText: texts.invoice_description_label,
              counterStyle: _descriptionFocusNode.hasFocus ? focusedCounterTextStyle : counterTextStyle,
            ),
            style: FieldTextStyle.textStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildOfferQRCode() {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return FutureBuilder<PrepareReceiveResponse>(
      future: prepareResponseFuture,
      builder: (BuildContext context, AsyncSnapshot<PrepareReceiveResponse> prepareSnapshot) {
        if (prepareSnapshot.hasError) {
          return ScrollableErrorMessageWidget(
            showIcon: true,
            title: '${texts.qr_code_dialog_warning_message_error}:',
            message: ExceptionHandler.extractMessage(prepareSnapshot.error!, texts),
            padding: EdgeInsets.zero,
          );
        }

        if (prepareSnapshot.hasData) {
          return FutureBuilder<ReceivePaymentResponse>(
            future: receivePaymentResponseFuture,
            builder: (BuildContext context, AsyncSnapshot<ReceivePaymentResponse> receiveSnapshot) {
              if (receiveSnapshot.hasError) {
                return ScrollableErrorMessageWidget(
                  showIcon: true,
                  title: '${texts.qr_code_dialog_warning_message_error}:',
                  message: ExceptionHandler.extractMessage(receiveSnapshot.error!, texts),
                  padding: EdgeInsets.zero,
                );
              }

              if (receiveSnapshot.hasData) {
                return Container(
                  decoration: ShapeDecoration(
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    color: themeData.customData.surfaceBgColor,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
                  child: SingleChildScrollView(
                    child: DestinationWidget(
                      snapshot: receiveSnapshot,
                      destination: receiveSnapshot.data?.destination,
                      paymentLabel: PaymentMethod.bolt12Offer.displayName,
                      infoWidget: PaymentFeesMessageBox(feesSat: prepareSnapshot.data!.feesSat.toInt()),
                    ),
                  ),
                );
              }

              return const CenteredLoader();
            },
          );
        }

        return const CenteredLoader();
      },
    );
  }

  void _resetForm() {
    setState(() {
      prepareResponseFuture = null;
      receivePaymentResponseFuture = null;
      _descriptionController.clear();
    });
  }

  void _createOffer() {
    _logger.info('Create BOLT12 offer: description=${_descriptionController.text}');
    final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();

    final Future<PrepareReceiveResponse> prepareReceiveResponse = paymentsCubit.prepareReceivePayment(
      paymentMethod: PaymentMethod.bolt12Offer,
    );

    setState(() {
      prepareResponseFuture = prepareReceiveResponse;
    });
    prepareReceiveResponse.then((PrepareReceiveResponse prepareReceiveResponse) {
      setState(() {
        receivePaymentResponseFuture = paymentsCubit.receivePayment(
          prepareResponse: prepareReceiveResponse,
          description: _descriptionController.text,
        );
      });
    });
  }
}
