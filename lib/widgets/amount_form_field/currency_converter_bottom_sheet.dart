import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/widgets/widgets.dart';

class CurrencyConverterBottomSheet extends StatefulWidget {
  final Function(String string) onConvert;
  final String? Function(int amount) validatorFn;

  const CurrencyConverterBottomSheet({
    required this.onConvert,
    required this.validatorFn,
    super.key,
  });

  @override
  State<CurrencyConverterBottomSheet> createState() => _CurrencyConverterBottomSheetState();
}

class _CurrencyConverterBottomSheetState extends State<CurrencyConverterBottomSheet>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fiatAmountController = TextEditingController();
  final FocusNode _fiatAmountFocusNode = FocusNode();
  KeyboardDoneAction _doneAction = KeyboardDoneAction();

  Timer? _exchangeRateRefreshTimer;
  AnimationController? _animationController;
  Animation<Color?>? _colorAnimation;
  final ValueNotifier<double?> _exchangeRateNotifier = ValueNotifier<double?>(null);

  String? _selectedFiatCurrency;

  @override
  void initState() {
    super.initState();
    _fiatAmountController.addListener(() => setState(() {}));
    _doneAction = KeyboardDoneAction(focusNodes: <FocusNode>[_fiatAmountFocusNode]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAnimation();
      _fetchExchangeRates();
      _startExchangeRateRefreshTimer();
    });
  }

  void _setupAnimation() {
    final ThemeData themeData = Theme.of(context);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Loop back to start and stop
    _animationController?.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _animationController?.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController?.stop();
      }
    });

    _colorAnimation = ColorTween(
      begin: themeData.primaryTextTheme.titleSmall!.color!.withValues(alpha: .7),
      end: themeData.textTheme.headlineMedium!.color,
    ).animate(_animationController!)
      ..addListener(() {
        setState(() {});
      });
  }

  void _fetchExchangeRates() {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    currencyCubit.fetchExchangeRates().catchError(
      (Object value) {
        if (mounted) {
          final BreezTranslations texts = context.texts();
          setState(() {
            Navigator.pop(context);
            showFlushbar(
              context,
              message: texts.currency_converter_dialog_error_exchange_rate,
            );
          });
        }
        return <String, Rate>{};
      },
    );
  }

  void _startExchangeRateRefreshTimer() {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    // Refresh exchange rates every 30 seconds
    _exchangeRateRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => currencyCubit.fetchExchangeRates(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _doneAction.dispose();
    _animationController?.dispose();
    _exchangeRateNotifier.dispose();
    _exchangeRateRefreshTimer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: BlocBuilder<CurrencyCubit, CurrencyState>(
          builder: (BuildContext context, CurrencyState state) {
            if (state.preferredCurrencies.isEmpty || !state.fiatEnabled) {
              return const Center(child: CircularProgressIndicator());
            }

            _updateExchangeRateIfNeeded(state.fiatExchangeRate);

            _selectedFiatCurrency ??= state.fiatId;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Align(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8.0),
                    width: 40.0,
                    height: 6.5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    // TODO(erdemyerebasmaz): Add these messages to Breez-Translations
                    'Select Fiat Currency:',
                    style: themeData.primaryTextTheme.headlineMedium!.copyWith(
                      fontSize: 18.0,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                FiatCurrencyChips(
                  selectedCurrency: _selectedFiatCurrency,
                  onCurrencySelected: (String currency) {
                    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
                    setState(() {
                      _selectedFiatCurrency = currency;
                      currencyCubit.setFiatId(currency);
                    });
                  },
                ),
                const Divider(
                  height: 32.0,
                  color: Colors.white24,
                  indent: 16.0,
                  endIndent: 16.0,
                ),
                FiatInputField(
                  formKey: _formKey,
                  controller: _fiatAmountController,
                  focusNode: _fiatAmountFocusNode,
                  fiatConversion: state.fiatConversion(),
                  validatorFn: widget.validatorFn,
                ),
                const SizedBox(height: 8.0),
                SatEquivalentLabel(
                  controller: _fiatAmountController,
                ),
                ExchangeRateLabel(
                  exchangeRateNotifier: _exchangeRateNotifier,
                  colorAnimation: _colorAnimation,
                ),
                const SizedBox(height: 8.0),
                Align(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: SingleButtonBottomBar(
                      text: texts.currency_converter_dialog_action_done,
                      expand: true,
                      onPressed: () {
                        if (_fiatAmountController.text.isEmpty) {
                          Navigator.pop(context);
                          return;
                        }
                        if (_formKey.currentState?.validate() ?? false) {
                          final double inputAmount = double.tryParse(_fiatAmountController.text) ?? 0;
                          final int convertedAmount = state.fiatConversion()?.fiatToSat(inputAmount) ?? 0;

                          widget.onConvert(
                            state.bitcoinCurrency.format(
                              convertedAmount,
                              includeDisplayName: false,
                              userInput: true,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _updateExchangeRateIfNeeded(double? newRate) {
    if (newRate != null && newRate != _exchangeRateNotifier.value) {
      _exchangeRateNotifier.value = newRate;

      // Blink exchange rate label when exchange rate changes or a different fiat currency is selected.
      if (!(_animationController?.isAnimating ?? true)) {
        _animationController?.forward();
      }
    }
  }
}
