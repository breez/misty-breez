import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/utils.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';
import 'package:service_injector/service_injector.dart';

/// Logger for the EnterPaymentInfoPage.
final Logger _logger = Logger('EnterPaymentInfoPage');

/// AutoSizeGroup to ensure consistent text size across multiple widgets.
final AutoSizeGroup _textGroup = AutoSizeGroup();

/// A page that allows users to enter payment information via text input, paste, or QR scan.
class EnterPaymentInfoPage extends StatefulWidget {
  /// The route name for navigation.
  static const String routeName = '/enter_payment_info';

  /// Creates an EnterPaymentInfoPage.
  const EnterPaymentInfoPage({super.key});

  @override
  State<StatefulWidget> createState() => _EnterPaymentInfoPageState();
}

class _EnterPaymentInfoPageState extends State<EnterPaymentInfoPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _paymentInfoController = TextEditingController();

  String _errorMessage = '';
  TransparentPageRoute<void>? _loaderRoute;

  @override
  void initState() {
    super.initState();
    _paymentInfoController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _paymentInfoController.removeListener(_onTextChanged);
    _paymentInfoController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.enter_payment_info_page_title),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SingleChildScrollView(
          child: _buildContentContainer(texts, themeData),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(texts),
    );
  }

  /// Builds the main content container with form and action buttons.
  Widget _buildContentContainer(BreezTranslations texts, ThemeData themeData) {
    return Container(
      decoration: const ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(12),
          ),
        ),
        color: Color.fromRGBO(10, 20, 40, 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: <Widget>[
          _buildForm(texts, themeData),
          _buildActionButtons(texts),
        ],
      ),
    );
  }

  /// Builds the form with the payment info input field.
  Widget _buildForm(BreezTranslations texts, ThemeData themeData) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            controller: _paymentInfoController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              prefixIconConstraints: BoxConstraints.tight(
                const Size(16, 56),
              ),
              prefixIcon: const SizedBox.shrink(),
              contentPadding: EdgeInsets.zero,
              labelText: texts.enter_payment_info_page_label,
            ),
            style: FieldTextStyle.textStyle,
            validator: (String? value) => _errorMessage.isNotEmpty ? _errorMessage : null,
            onFieldSubmitted: _validateAndPasteValue,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              texts.enter_payment_info_page_label_expanded,
              style: FieldTextStyle.labelStyle.copyWith(
                fontSize: 13.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the row with paste and scan buttons.
  Widget _buildActionButtons(BreezTranslations texts) {
    return Padding(
      padding: const EdgeInsets.only(top: 36.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: PaymentInfoPasteButton(
              onPressed: _onPastePressed,
              textGroup: _textGroup,
            ),
          ),
          const SizedBox(width: 32.0),
          Expanded(
            child: PaymentInfoScanButton(
              onPressed: _scanBarcode,
              textGroup: _textGroup,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the bottom action bar.
  Widget _buildBottomBar(BreezTranslations texts) {
    return SingleButtonBottomBar(
      stickToBottom: true,
      enabled: _paymentInfoController.text.isNotEmpty,
      text: texts.enter_payment_info_page_action_next,
      onPressed: _onApprovePressed,
    );
  }

  /// Handles the paste button press.
  Future<void> _onPastePressed(String? value) async {
    if (value != null && value.isNotEmpty) {
      _validateAndPasteValue(value);
    }
  }

  /// Validates and pastes the input value.
  void _validateAndPasteValue(String input) async {
    if (input.isNotEmpty) {
      setState(() {
        _paymentInfoController.text = input;
      });
      await _validateInput();
    }
  }

  /// Opens the QR scanner and processes the result.
  void _scanBarcode() async {
    final BreezTranslations texts = context.texts();

    if (!mounted) {
      return;
    }

    // Unfocus any active text field
    Focus.maybeOf(context)?.unfocus();

    // Navigate to QR scan page
    final String? barcode = await Navigator.pushNamed<String>(
      context,
      QRScanView.routeName,
    );

    // Handle the scan result
    if (!mounted) {
      return;
    }

    if (barcode == null || barcode.isEmpty) {
      showFlushbar(
        context,
        message: texts.qr_code_not_detected_error,
      );
      return;
    }

    setState(() {
      _paymentInfoController.text = barcode;
    });

    await _validateInput();
  }

  /// Validates the current input and updates error message if needed.
  Future<void> _validateInput() async {
    if (!mounted) {
      return;
    }

    final BreezTranslations texts = context.texts();
    final InputCubit inputCubit = context.read<InputCubit>();
    String errMsg = '';

    try {
      final InputType inputType = await inputCubit.parseInput(
        input: _paymentInfoController.text,
      );

      // Check for unsupported input types
      if (unsupportedInputTypeChecks.any((TypeCheck check) => check(inputType))) {
        errMsg = texts.payment_info_dialog_error_unsupported_input;
      }

      // Check for zero amount Bolt11 invoices
      if (inputType is InputType_Bolt11 && inputType.invoice.amountMsat == BigInt.zero) {
        errMsg = texts.payment_request_zero_amount_not_supported;
      }
    } catch (error) {
      final String errStr = error.toString();
      errMsg = errStr.contains('Unrecognized') ? texts.payment_info_dialog_error_unsupported_input : errStr;

      _logger.warning('Input validation error: $errStr', error);
    } finally {
      if (mounted) {
        setState(() {
          _errorMessage = errMsg;
        });
        _formKey.currentState?.validate();
      }
    }
  }

  /// Handles the approval button press.
  Future<void> _onApprovePressed() async {
    if (!mounted) {
      return;
    }

    final InputCubit inputCubit = context.read<InputCubit>();

    try {
      // Show loading indicator
      _setLoading(true);

      // Validate input before proceeding
      await _validateInput();

      if (_formKey.currentState!.validate()) {
        _setLoading(false);

        if (!mounted) {
          return;
        }

        // Close this page
        Navigator.pop(context);

        // Process the input
        inputCubit.addIncomingInput(
          _paymentInfoController.text.trim(),
          InputSource.inputField,
        );
      }
    } catch (error) {
      _logger.warning('Error processing payment info: ${error.toString()}', error);

      if (mounted) {
        setState(() {
          _errorMessage = context.texts().payment_info_dialog_error;
        });
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Shows or hides the loading indicator.
  void _setLoading(bool visible) {
    if (!mounted) {
      return;
    }

    if (visible && _loaderRoute == null) {
      _loaderRoute = createLoaderRoute(context);
      Navigator.of(context).push(_loaderRoute!);
    } else if (!visible && _loaderRoute?.isActive == true) {
      _loaderRoute?.navigator?.removeRoute(_loaderRoute!);
      _loaderRoute = null;
    }
  }
}

/// A button that allows pasting from clipboard.
class PaymentInfoPasteButton extends StatelessWidget {
  /// Called when the button is pressed with the clipboard content.
  final Function(String? value) onPressed;

  /// Optional group for text size coordination.
  final AutoSizeGroup? textGroup;

  /// Creates a PaymentInfoPasteButton.
  const PaymentInfoPasteButton({
    required this.onPressed,
    this.textGroup,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final MinFontSize minFont = MinFontSize(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 48.0,
        minWidth: 138.0,
      ),
      child: Tooltip(
        message: texts.bottom_action_bar_enter_payment_info,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(
            IconData(0xe90b, fontFamily: 'icomoon'),
            size: 20.0,
          ),
          label: AutoSizeText(
            // TODO(erdemyerebasmaz): Add message to Breez-Translations
            'PASTE',
            style: balanceFiatConversionTextStyle,
            maxLines: 1,
            group: textGroup,
            minFontSize: minFont.minFontSize,
            stepGranularity: 0.1,
          ),
          onPressed: () async {
            try {
              final String? clipboardText = await ServiceInjector().deviceClient.fetchClipboardData();
              onPressed(clipboardText);
            } catch (e) {
              _logger.severe('Failed to fetch clipboard data', e);
              // Still call onPressed with null to handle the error case
              onPressed(null);
            }
          },
        ),
      ),
    );
  }
}

/// A button that allows scanning QR codes.
class PaymentInfoScanButton extends StatelessWidget {
  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// Optional group for text size coordination.
  final AutoSizeGroup? textGroup;

  /// Creates a PaymentInfoScanButton.
  const PaymentInfoScanButton({
    required this.onPressed,
    this.textGroup,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);
    final MinFontSize minFont = MinFontSize(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 48.0,
        minWidth: 138.0,
      ),
      child: Tooltip(
        message: texts.enter_payment_info_page_scan_tooltip,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: Image(
            image: const AssetImage('assets/icons/qr_scan.png'),
            color: themeData.iconTheme.color,
            width: 24.0,
            height: 24.0,
          ),
          label: AutoSizeText(
            // TODO(erdemyerebasmaz): Add message to Breez-Translations
            'SCAN',
            style: balanceFiatConversionTextStyle,
            maxLines: 1,
            group: textGroup,
            minFontSize: minFont.minFontSize,
            stepGranularity: 0.1,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
