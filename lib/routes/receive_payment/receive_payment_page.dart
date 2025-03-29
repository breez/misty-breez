import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';

class ReceivePaymentPage extends StatefulWidget {
  static const String routeName = '/receive_payment';
  final int initialPageIndex;

  const ReceivePaymentPage({required this.initialPageIndex, super.key});

  @override
  State<ReceivePaymentPage> createState() => _ReceivePaymentPageState();
}

class _ReceivePaymentPageState extends State<ReceivePaymentPage> {
  static const List<StatefulWidget> pages = <StatefulWidget>[
    ReceiveLightningPaymentPage(),
    ReceiveLightningAddressPage(),
    ReceiveBitcoinAddressPaymentPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    final PermissionStatus notificationStatus = context.select<PermissionsCubit, PermissionStatus>(
      (PermissionsCubit cubit) => cubit.state.notificationStatus,
    );
    final int currentPageIndex = _getEffectivePageIndex(notificationStatus);

    final bool isLightningPage = <int>[
      ReceiveLightningPaymentPage.pageIndex,
      ReceiveLightningAddressPage.pageIndex,
    ].contains(currentPageIndex);

    return Scaffold(
      appBar: AppBar(
        leading: back_button.BackButton(
          onPressed: () {
            if (currentPageIndex == ReceiveLightningPaymentPage.pageIndex &&
                notificationStatus != PermissionStatus.granted) {
              // Pop to Home page, bypassing LN Address page if notification permissions are disabled
              Navigator.of(context).pushReplacementNamed(Home.routeName);
              return;
            }
            Navigator.of(context).pop();
          },
        ),
        title: Text(_getTitle(currentPageIndex)),
        actions: isLightningPage
            ? <Widget>[
                IconButton(
                  alignment: Alignment.center,
                  icon: Image(
                    image: const AssetImage('assets/icons/qr_scan.png'),
                    color: themeData.iconTheme.color,
                    fit: BoxFit.contain,
                    width: 24.0,
                    height: 24.0,
                  ),
                  tooltip: texts.lnurl_withdraw_scan_toolip,
                  onPressed: () => _scanBarcode(),
                ),
              ]
            : <Widget>[],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: pages.elementAt(currentPageIndex),
      ),
    );
  }

  String _getTitle(int pageIndex) {
    final BreezTranslations texts = context.texts();
    switch (pageIndex) {
      case ReceiveLightningPaymentPage.pageIndex:
      case ReceiveLightningAddressPage.pageIndex:
        // TODO(erdemyerebasmaz): Add message to Breez-Translations
        return 'Receive with Lightning';
      case ReceiveBitcoinAddressPaymentPage.pageIndex:
        return texts.invoice_btc_address_title;
      default:
        return texts.invoice_lightning_title;
    }
  }

  int _getEffectivePageIndex(PermissionStatus notificationStatus) {
    // Redirect to Invoice page if LN Address page is opened without notification permissions
    if (widget.initialPageIndex == ReceiveLightningAddressPage.pageIndex &&
        notificationStatus != PermissionStatus.granted) {
      return ReceiveLightningPaymentPage.pageIndex;
    }

    return widget.initialPageIndex;
  }

  void _scanBarcode() {
    final BreezTranslations texts = context.texts();
    final BuildContext currentContext = context;

    Focus.maybeOf(currentContext)?.unfocus();
    Navigator.pushNamed<String>(currentContext, QRScanView.routeName).then((String? barcode) async {
      if (barcode == null || barcode.isEmpty) {
        if (currentContext.mounted) {
          showFlushbar(
            currentContext,
            message: texts.payment_info_dialog_error_qrcode,
          );
        }
        return;
      }

      await _validateAndProcessInput(barcode);
    });
  }

  Future<void> _validateAndProcessInput(String barcode) async {
    final BreezTranslations texts = context.texts();
    final InputCubit inputCubit = context.read<InputCubit>();

    try {
      final InputType inputType = await inputCubit.parseInput(input: barcode);
      if (mounted) {
        if (inputType is InputType_LnUrlWithdraw) {
          handleWithdrawRequest(context, inputType.data);
        } else {
          showFlushbar(
            context,
            message: texts.payment_info_dialog_error_unsupported_input,
          );
        }
      }
    } catch (error) {
      final String errorMessage = error.toString().contains('Unrecognized')
          ? texts.payment_info_dialog_error_unsupported_input
          : error.toString();
      if (mounted) {
        showFlushbar(context, message: errorMessage);
      }
    }
  }
}
