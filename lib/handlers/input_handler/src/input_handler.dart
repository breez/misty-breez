import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/handlers/handlers.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

final Logger _logger = Logger('InputHandler');

class InputHandler extends Handler {
  final GlobalKey firstPaymentItemKey;
  final GlobalKey<ScaffoldState> scaffoldController;

  StreamSubscription<InputState>? _subscription;
  TransparentPageRoute<dynamic>? _loaderRoute;
  bool _handlingRequest = false;

  InputHandler(this.firstPaymentItemKey, this.scaffoldController);

  @override
  void init(HandlerContextProvider<StatefulWidget> contextProvider) {
    super.init(contextProvider);
    _subscription = contextProvider.getBuildContext()!.read<InputCubit>().stream.listen(
      _listen,
      onError: (Object error) {
        _handlingRequest = false;
        _setLoading(false);
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
    _subscription = null;
  }

  void _listen(InputState inputState) {
    _logger.info('Input state changed: $inputState');
    if (_handlingRequest) {
      _logger.info('Already handling request, skipping state change');
      return;
    }

    final bool isLoading = inputState is LoadingInputState;
    _handlingRequest = isLoading;
    _setLoading(isLoading);

    handleInputData(inputState)
        .then((dynamic result) => handleResult(result))
        .whenComplete(() => _handlingRequest = false)
        .onError((Object? error, _) {
          _logger.severe('Input state error', error);
          _handlingRequest = false;
          _setLoading(false);
          if (error != null) {
            final BuildContext? context = contextProvider?.getBuildContext();
            if (context != null && context.mounted) {
              showFlushbar(context, message: ExceptionHandler.extractMessage(error, context.texts()));
            } else {
              _logger.info('Skipping handling of error: $error because context is null');
            }
          }
        });
  }

  Future<dynamic> handleInputData(InputState inputState) async {
    _logger.info('handle input $inputState');
    final BuildContext? context = contextProvider?.getBuildContext();
    if (context == null) {
      _logger.info('Not handling input $inputState because context is null');
      return;
    }

    if (inputState is LnInvoiceInputState) {
      return handleLnInvoice(context, inputState.lnInvoice);
    } else if (inputState is LnOfferInputState) {
      return handleLnOffer(context, inputState.lnOffer, bip353Address: inputState.bip353Address);
    } else if (inputState is LnUrlPayInputState) {
      return handlePayRequest(
        context,
        firstPaymentItemKey,
        inputState.data,
        bip353Address: inputState.bip353Address,
      );
    } else if (inputState is LnUrlWithdrawInputState) {
      return handleWithdrawRequest(context, inputState.data);
    } else if (inputState is LnUrlAuthInputState) {
      return handleAuthRequest(context, inputState.data);
    } else if (inputState is LnUrlErrorInputState) {
      throw inputState.data.reason;
    } else if (inputState is BitcoinAddressInputState) {
      return handleBitcoinAddress(context, inputState);
    } else if (unsupportedInputStates.contains(inputState.runtimeType)) {
      throw context.texts().payment_info_dialog_error_unsupported_input;
    } else if (inputState is EmptyInputState) {
      throw 'Failed to parse input.';
    }
  }

  Future<dynamic> handleLnInvoice(BuildContext context, LNInvoice lnInvoice) async {
    _logger.info('handle LnInvoice ${lnInvoice.toFormattedString()}');
    final NavigatorState navigator = Navigator.of(context);
    final SendPaymentRequest? sendPaymentRequest = await navigator.pushNamed<SendPaymentRequest?>(
      LnPaymentPage.routeName,
      arguments: lnInvoice,
    );
    if (sendPaymentRequest == null || !context.mounted) {
      return Future<dynamic>.value();
    }

    // Show Processing Payment Sheet
    return await showProcessingPaymentSheet(
      context,
      isLnPayment: true,
      paymentFunc: () async {
        final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();
        return await paymentsCubit.sendPayment(prepareResponse: sendPaymentRequest.prepareResponse);
      },
    ).then((dynamic result) {
      // TODO(erdemyerebasmaz): Handle SendPaymentResponse results, return a SendPaymentResult to be handled by handleResult()
      if (result is SendPaymentResponse) {
        _logger.info('SendPaymentResponse result - payment status: ${result.payment.status}');
      }

      // Navigate to home after handling the result
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(Home.routeName, (Route<dynamic> route) => false);

        // Payment timeout doesn't necessarily mean the payment failed.
        // We're popping to Home page to avoid user retries and duplicate payments.
        if (result is PaymentError_PaymentTimeout) {
          final ThemeData themeData = Theme.of(context);
          promptError(
            context,
            title: context.texts().unexpected_error_title,
            body: Text(
              ExceptionHandler.extractMessage(result, context.texts()),
              style: themeData.dialogTheme.contentTextStyle,
            ),
          );
        } else if (result is String) {
          showFlushbar(context, message: result);
        }
      }
    });
  }

  Future<dynamic> handleLnOffer(BuildContext context, LNOffer lnOffer, {String? bip353Address}) async {
    _logger.info('handle LNOffer ${lnOffer.toFormattedString()}');
    final NavigatorState navigator = Navigator.of(context);
    final LnOfferPaymentArguments arguments = LnOfferPaymentArguments(
      lnOffer: lnOffer,
      bip353Address: bip353Address,
    );
    final SendPaymentRequest? sendPaymentRequest = await navigator.pushNamed<SendPaymentRequest?>(
      LnOfferPaymentPage.routeName,
      arguments: arguments,
    );
    if (sendPaymentRequest == null || !context.mounted) {
      return Future<dynamic>.value();
    }

    // Show Processing Payment Sheet
    return await showProcessingPaymentSheet(
      context,
      isLnPayment: true,
      paymentFunc: () async {
        final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();
        return await paymentsCubit.sendPayment(
          prepareResponse: sendPaymentRequest.prepareResponse,
          payerNote: sendPaymentRequest.payerNote,
        );
      },
    ).then((dynamic result) {
      // TODO(erdemyerebasmaz): Handle SendPaymentResponse results, return a SendPaymentResult to be handled by handleResult()
      if (result is SendPaymentResponse) {
        _logger.info('SendPaymentResponse result - payment status: ${result.payment.status}');
      }

      // Navigate to home after handling the result
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(Home.routeName, (Route<dynamic> route) => false);

        // Payment timeout doesn't necessarily mean the payment failed.
        // We're popping to Home page to avoid user retries and duplicate payments.
        if (result is PaymentError_PaymentTimeout) {
          final ThemeData themeData = Theme.of(context);
          promptError(
            context,
            title: context.texts().unexpected_error_title,
            body: Text(
              ExceptionHandler.extractMessage(result, context.texts()),
              style: themeData.dialogTheme.contentTextStyle,
            ),
          );
        } else if (result is String) {
          showFlushbar(context, message: result);
        }
      }
    });
  }

  Future<dynamic> handleBitcoinAddress(BuildContext context, BitcoinAddressInputState inputState) async {
    _logger.fine('Handle Bitcoin Address $inputState');
    return await Navigator.of(context).pushNamed(SendChainSwapPage.routeName, arguments: inputState.data);
  }

  void handleResult(dynamic result) {
    _logger.info('Input state handled: $result');
    if (result is LNURLPageResult && result.protocol != null) {
      final BuildContext? context = contextProvider?.getBuildContext();
      if (context != null) {
        handleLNURLPageResult(context, result);
      } else {
        _logger.info('Skipping handling of result: $result because context is null');
      }
    }
  }

  void _setLoading(bool visible) {
    if (visible && _loaderRoute == null) {
      final BuildContext? context = contextProvider?.getBuildContext();
      if (context != null) {
        _loaderRoute = createLoaderRoute(context);
        Navigator.of(context).push(_loaderRoute!);
      }
      return;
    }

    if (!visible && _loaderRoute != null) {
      _loaderRoute?.navigator?.removeRoute(_loaderRoute!);
      _loaderRoute = null;
    }
  }
}
