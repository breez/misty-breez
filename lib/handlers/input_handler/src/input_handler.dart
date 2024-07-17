import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/handlers/handler/handler.dart';
import 'package:l_breez/models/invoice.dart';
import 'package:l_breez/routes/chainswap/send/send_chainswap_page.dart';
import 'package:l_breez/routes/lnurl/auth/lnurl_auth_handler.dart';
import 'package:l_breez/routes/lnurl/payment/lnurl_payment_handler.dart';
import 'package:l_breez/routes/lnurl/withdraw/lnurl_withdraw_handler.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/payment_dialogs/payment_request_dialog.dart';
import 'package:logging/logging.dart';

final _log = Logger("InputHandler");

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
    _log.info("Input state changed: $inputState");
    if (_handlingRequest) {
      _log.info("Already handling request, skipping state change");
      return;
    }

    final isLoading = inputState is LoadingInputState;
    _handlingRequest = isLoading;
    _setLoading(isLoading);

    handleInputData(inputState).whenComplete(() => _handlingRequest = false).onError((error, _) {
      _log.severe("Input state error", error);
      _handlingRequest = false;
      _setLoading(false);
      if (error != null) {
        final context = contextProvider?.getBuildContext();
        if (context != null) {
          showFlushbar(context, message: extractExceptionMessage(error, context.texts()));
        } else {
          _log.info("Skipping handling of error: $error because context is null");
        }
      }
    });
  }

  Future handleInputData(InputState inputState) async {
    _log.info("handle input $inputState");
    final context = contextProvider?.getBuildContext();
    if (context == null) {
      _log.info("Not handling input $inputState because context is null");
      return;
    }

    if (inputState is InvoiceInputState) {
      return handleInvoice(context, inputState.invoice);
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
    }
  }

  Future handleInvoice(BuildContext context, Invoice invoice) async {
    _log.info("handle invoice $invoice");
    return await showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentRequestDialog(
        invoice,
        firstPaymentItemKey,
      ),
    );
  }

  Future handleBitcoinAddress(BuildContext context, BitcoinAddressInputState inputState) async {
    _log.fine("handle bitcoin address $inputState");
    if (inputState.source == InputSource.qrcodeReader) {
      return await Navigator.of(context).pushNamed(SendChainSwapPage.routeName, arguments: inputState.data);
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
