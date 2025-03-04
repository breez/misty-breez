import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/sdk_formatted_string_extensions.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/utils/utils.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';

export 'widgets/widgets.dart';

final Logger _logger = Logger('RefundPage');

class RefundPage extends StatefulWidget {
  final RefundableSwap swapInfo;

  static const String routeName = '/refund_page';

  const RefundPage({required this.swapInfo, super.key});

  @override
  State<StatefulWidget> createState() => RefundPageState();
}

class RefundPageState extends State<RefundPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _logger.info('Opened refund details for ${widget.swapInfo.toFormattedString()}');
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.get_refund_title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
          child: Column(
            children: <Widget>[
              Container(
                decoration: const ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(12),
                    ),
                  ),
                  color: Color.fromRGBO(10, 20, 40, 1),
                ),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: RefundForm(
                  formKey: _formKey,
                  addressController: _addressController,
                  swapInfo: widget.swapInfo,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SingleButtonBottomBar(
        text: texts.withdraw_funds_action_next,
        onPressed: _prepareRefund,
      ),
    );
  }

  void _prepareRefund() async {
    final BreezTranslations texts = context.texts();
    final NavigatorState navigator = Navigator.of(context);
    if (_formKey.currentState?.validate() ?? false) {
      final TransparentPageRoute<void> loaderRoute = createLoaderRoute(context);
      navigator.push(loaderRoute);
      try {
        if (loaderRoute.isActive) {
          navigator.removeRoute(loaderRoute);
        }
        final RefundParams refundParams = RefundParams(
          swapAddress: widget.swapInfo.swapAddress,
          toAddress: _addressController.text,
        );
        navigator.push(
          FadeInRoute<void>(
            builder: (_) => RefundConfirmationPage(
              refundAmountSat: widget.swapInfo.amountSat.toInt(),
              refundParams: refundParams,
            ),
          ),
        );
      } catch (error) {
        if (loaderRoute.isActive) {
          navigator.removeRoute(loaderRoute);
        }
        _logger.severe('Received error: $error');
        if (!context.mounted) {
          return;
        }
        showFlushbar(
          context,
          message: texts.reverse_swap_upstream_generic_error_message(
            ExceptionHandler.extractMessage(error, texts),
          ),
        );
      } finally {
        if (loaderRoute.isActive) {
          navigator.removeRoute(loaderRoute);
        }
      }
    }
  }
}
