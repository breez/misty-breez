import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/fiat_conversion.dart';
import 'package:l_breez/utils/min_font_size.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/loader.dart';

class CurrencyConverterDialog extends StatefulWidget {
  final Function(String string) _onConvert;
  final String? Function(int amount) validatorFn;
  final CurrencyCubit _currencyCubit;

  const CurrencyConverterDialog(this._currencyCubit, this._onConvert, this.validatorFn, {super.key});

  @override
  CurrencyConverterDialogState createState() {
    return CurrencyConverterDialogState();
  }
}

class CurrencyConverterDialogState extends State<CurrencyConverterDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fiatAmountController = TextEditingController();
  final FocusNode _fiatAmountFocusNode = FocusNode();

  AnimationController? _controller;

  double? _exchangeRate;

  final AutoSizeGroup _autoSizeGroup = AutoSizeGroup();

  @override
  void initState() {
    super.initState();
    _fiatAmountController.addListener(() => setState(() {}));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Loop back to start and stop
    _controller!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller!.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller!.stop();
      }
    });

    widget._currencyCubit.fetchExchangeRates().catchError((value) {
      if (mounted) {
        final texts = context.texts();
        setState(() {
          Navigator.pop(context);
          showFlushbar(
            context,
            message: texts.currency_converter_dialog_error_exchange_rate,
          );
        });
      }
      return <String, Rate>{};
    });
  }

  @override
  void dispose() {
    _fiatAmountController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrencyCubit, CurrencyState>(
      builder: (context, currencyState) {
        if (currencyState.preferredCurrencies.isEmpty || !currencyState.fiatEnabled) {
          return const Loader();
        }

        double exchangeRate = currencyState.fiatExchangeRate!;
        _updateExchangeLabel(exchangeRate);

        return AlertDialog(
          title: _dialogBody(currencyState),
          titlePadding: const EdgeInsets.fromLTRB(24.0, 16.0, 16.0, 8.0),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
          content: _dialogContent(currencyState),
          actions: _buildActions(currencyState),
        );
      },
    );
  }

  Widget _dialogBody(CurrencyState currencyState) {
    final themeData = Theme.of(context);
    final texts = context.texts();

    final items = currencyState.preferredCurrencies.map((value) {
      var fiatCurrencyData = currencyState.fiatCurrenciesData.firstWhere((c) => c.id == value);
      return DropdownMenuItem<String>(
        value: fiatCurrencyData.id,
        child: Material(
          child: SizedBox(
            width: 36,
            child: AutoSizeText(
              fiatCurrencyData.id,
              textAlign: TextAlign.left,
              style: themeData.dialogTheme.titleTextStyle,
              maxLines: 1,
              minFontSize: MinFontSize(context).minFontSize,
              stepGranularity: 0.1,
              group: _autoSizeGroup,
            ),
          ),
        ),
      );
    });

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 50.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 0.0, bottom: 2.0),
              child: AutoSizeText(
                texts.currency_converter_dialog_title,
                maxLines: 1,
                minFontSize: MinFontSize(context).minFontSize,
                stepGranularity: 0.1,
                group: _autoSizeGroup,
              ),
            ),
          ),
          Theme(
            data: themeData.copyWith(
              canvasColor: themeData.colorScheme.surface,
            ),
            child: DropdownButtonHideUnderline(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton(
                  onChanged: (value) => _selectFiatCurrency(value.toString()),
                  value: currencyState.fiatId,
                  iconEnabledColor: themeData.dialogTheme.titleTextStyle!.color!,
                  style: themeData.dialogTheme.titleTextStyle!,
                  items: items.toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogContent(CurrencyState currencyState) {
    final themeData = Theme.of(context);
    final fiatCurrency = currencyState.fiatCurrency;
    final fiatExchangeRate = currencyState.fiatExchangeRate;
    if (fiatCurrency == null || fiatExchangeRate == null) {
      return const Loader();
    }

    final fiatConversion = FiatConversion(fiatCurrency, fiatExchangeRate);
    final borderColor = themeData.isLightTheme ? Colors.red : themeData.colorScheme.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: greyBorderSide,
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: greyBorderSide,
              ),
              errorBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: borderColor,
                ),
              ),
              focusedErrorBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: borderColor,
                ),
              ),
              errorMaxLines: 2,
              errorStyle: themeData.primaryTextTheme.bodySmall!.copyWith(
                color: borderColor,
              ),
              prefix: Text(
                fiatCurrency.info.symbol?.grapheme ?? "",
                style: themeData.dialogTheme.contentTextStyle,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                fiatConversion.whitelistedPattern,
              ),
              TextInputFormatter.withFunction(
                (_, newValue) => newValue.copyWith(
                  text: newValue.text.replaceAll(',', '.'),
                ),
              ),
            ],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            focusNode: _fiatAmountFocusNode,
            autofocus: true,
            onEditingComplete: () => _fiatAmountFocusNode.unfocus(),
            controller: _fiatAmountController,
            validator: (_) {
              return widget.validatorFn(_convertedSatoshies(currencyState));
            },
            style: themeData.dialogTheme.contentTextStyle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: Column(
            children: [
              Text(
                _contentMessage(currencyState),
                style: themeData.textTheme.headlineSmall!.copyWith(
                  fontSize: 16.0,
                ),
              ),
              _buildExchangeRateLabel(fiatConversion),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(CurrencyState currencyState) {
    final themeData = Theme.of(context);
    final texts = context.texts();

    List<Widget> actions = [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          texts.currency_converter_dialog_action_cancel,
          style: themeData.primaryTextTheme.labelLarge,
        ),
      ),
    ];

    // Show done button only when the converted amount is bigger than 0
    if (_fiatAmountController.text.isNotEmpty && _convertedSatoshies(currencyState) > 0) {
      actions.add(
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget._onConvert(
                currencyState.bitcoinCurrency.format(
                  _convertedSatoshies(currencyState),
                  includeDisplayName: false,
                  userInput: true,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: Text(
            texts.currency_converter_dialog_action_done,
            style: themeData.primaryTextTheme.labelLarge,
          ),
        ),
      );
    }
    return actions;
  }

  String _contentMessage(CurrencyState currencyState) {
    final amount = _fiatAmountController.text.isNotEmpty
        ? currencyState.bitcoinCurrency.format(
            _convertedSatoshies(currencyState),
            includeDisplayName: false,
          )
        : 0;
    final symbol = currencyState.bitcoinCurrency.tickerSymbol;
    return "$amount $symbol";
  }

  void _updateExchangeLabel(double exchangeRate) {
    if (_exchangeRate != exchangeRate) {
      // Blink exchange rate label when exchange rate changes (also switches between fiat currencies)
      if (!_controller!.isAnimating) {
        _controller!.forward();
      }
      _exchangeRate = exchangeRate;
    }
  }

  int _convertedSatoshies(CurrencyState currencyState) {
    var fiatConversion = FiatConversion(currencyState.fiatCurrency!, currencyState.fiatExchangeRate!);
    return _fiatAmountController.text.isNotEmpty
        ? fiatConversion.fiatToSat(
            double.parse(_fiatAmountController.text),
          )
        : 0;
  }

  Widget _buildExchangeRateLabel(
    FiatConversion fiatConversion,
  ) {
    final themeData = Theme.of(context);
    final texts = context.texts();

    // Empty string widget is returned so that the dialogs height is not changed when the exchange rate is shown
    return _exchangeRate == null
        ? Text(
            "",
            style: themeData.primaryTextTheme.titleSmall,
          )
        : Text(
            texts.currency_converter_dialog_rate(
              fiatConversion.formatFiat(
                _exchangeRate!,
                removeTrailingZeros: true,
              ),
              fiatConversion.currencyData.id,
            ),
            style: themeData.primaryTextTheme.titleSmall!,
          );
  }

  void _selectFiatCurrency(String fiatId) {
    widget._currencyCubit.setFiatId(fiatId);
  }
}
