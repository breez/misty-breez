import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/handlers/handler/handler.dart';
import 'package:l_breez/routes/chainswap/send/send_chainswap_page.dart';
import 'package:l_breez/routes/lightning/ln_payment_page.dart';
import 'package:l_breez/routes/lnurl/auth/lnurl_auth_handler.dart';
import 'package:l_breez/routes/lnurl/lnurl_invoice_delegate.dart';
import 'package:l_breez/routes/lnurl/payment/lnurl_payment_handler.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_page_result.dart';
import 'package:l_breez/routes/lnurl/withdraw/lnurl_withdraw_handler.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/payment_dialogs/processing_payment_dialog.dart';
import 'package:logging/logging.dart';

final _logger = Logger("InputHandler");

class InputHandler extends Handler {
  final GlobalKey firstPaymentItemKey;
  final GlobalKey<ScaffoldState> scaffoldController;

  StreamSubscription<InputState>? _subscription;
  ModalRoute? _loaderRoute;
  bool _handlingRequest = false;

  InputHandler(
    this.firstPaymentItemKey,
    this.scaffoldController,
  );

  @override
  void init(HandlerContextProvider<StatefulWidget> contextProvider) {
    super.init(contextProvider);
    _subscription = contextProvider.getBuildContext()!.read<InputCubit>().stream.listen(
      _listen,
      onError: (error) {
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
    _logger.info("Input state changed: $inputState");
    if (_handlingRequest) {
      _logger.info("Already handling request, skipping state change");
      return;
    }

    final isLoading = inputState is LoadingInputState;
    _handlingRequest = isLoading;
    _setLoading(isLoading);

    handleInputData(inputState)
        .then((result) => handleResult(result))
        .whenComplete(() => _handlingRequest = false)
        .onError((error, _) {
      _logger.severe("Input state error", error);
      _handlingRequest = false;
      _setLoading(false);
      if (error != null) {
        final context = contextProvider?.getBuildContext();
        if (context != null && context.mounted) {
          showFlushbar(context, message: extractExceptionMessage(error, context.texts()));
        } else {
          _logger.info("Skipping handling of error: $error because context is null");
        }
      }
    });
  }

  Future handleInputData(InputState inputState) async {
    _logger.info("handle input $inputState");
    final context = contextProvider?.getBuildContext();
    if (context == null) {
      _logger.info("Not handling input $inputState because context is null");
      return;
    }

    if (inputState is LnInvoiceInputState) {
      return handleLnInvoice(context, inputState.lnInvoice);
    } else if (inputState is LnUrlPayInputState) {
      return handlePayRequest(context, firstPaymentItemKey, inputState.data);
    } else if (inputState is LnUrlWithdrawInputState) {
      return handleWithdrawRequest(context, inputState.data);
    } else if (inputState is LnUrlAuthInputState) {
      return handleAuthRequest(context, inputState.data);
    } else if (inputState is LnUrlErrorInputState) {
      throw inputState.data.reason;
    } else if (inputState is BitcoinAddressInputState) {
      return handleBitcoinAddress(context, inputState);
    } else if (inputState is UrlInputState) {
      throw context.texts().payment_info_dialog_error_unsupported_input;
    } else if (inputState is EmptyInputState) {
      throw "Failed to parse input.";
    }
  }

  Future handleLnInvoice(BuildContext context, LNInvoice lnInvoice) async {
    _logger.info("handle LnInvoice $lnInvoice");
    final navigator = Navigator.of(context);
    PrepareSendResponse? prepareResponse = await navigator.pushNamed<PrepareSendResponse?>(
      LnPaymentPage.routeName,
      arguments: lnInvoice,
    );
    if (prepareResponse == null || !context.mounted) {
      return Future.value();
    }

    // Show Processing Payment Dialog
    return await showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (_) => ProcessingPaymentDialog(
        isLnUrlPayment: true,
        firstPaymentItemKey: firstPaymentItemKey,
        paymentFunc: () async {
          final paymentsCubit = context.read<PaymentsCubit>();
          return await paymentsCubit.sendPayment(prepareResponse);
        },
      ),
    ).then((result) {
      if (result is String && context.mounted) {
        showFlushbar(context, message: result);
      }
      // TODO: Handle SendPaymentResponse results, return a SendPaymentResult to be handled by handleResult()
      if (result is SendPaymentResponse) {
        _logger.info("SendPaymentResponse result - payment status: ${result.payment.status}");
      }
    });
  }

  Future handleBitcoinAddress(BuildContext context, BitcoinAddressInputState inputState) async {
    _logger.fine("handle bitcoin address $inputState");
    if (inputState.source == InputSource.qrcodeReader) {
      return await Navigator.of(context).pushNamed(
        SendChainSwapPage.routeName,
        arguments: inputState.data,
      );
    }
  }

  void handleResult(result) {
    _logger.info("Input state handled: $result");
    if (result is LNURLPageResult && result.protocol != null) {
      final context = contextProvider?.getBuildContext();
      if (context != null) {
        handleLNURLPageResult(context, result);
      } else {
        _logger.info("Skipping handling of result: $result because context is null");
      }
    }
  }

  void _setLoading(bool visible) {
    if (visible && _loaderRoute == null) {
      final context = contextProvider?.getBuildContext();
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
