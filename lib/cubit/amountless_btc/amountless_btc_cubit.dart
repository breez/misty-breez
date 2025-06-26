import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

export 'amountless_btc_state.dart';

final Logger _logger = Logger('AmountlessBtcCubit');

class AmountlessBtcCubit extends Cubit<AmountlessBtcState> {
  final BreezSDKLiquid _breezSdkLiquid;

  AmountlessBtcCubit(this._breezSdkLiquid) : super(AmountlessBtcState.initial());

  /// Generates a new amountless Bitcoin address
  Future<void> generateAmountlessAddress() async {
    try {
      _logger.info('Generating amountless BTC address');

      emit(state.copyWith(isLoading: true));

      final PrepareReceiveRequest prepareReq = const PrepareReceiveRequest(
        paymentMethod: PaymentMethod.bitcoinAddress,
      );
      final PrepareReceiveResponse prepareResp = await _breezSdkLiquid.instance!.prepareReceivePayment(
        req: prepareReq,
      );
      final ReceivePaymentRequest req = ReceivePaymentRequest(prepareResponse: prepareResp);
      final ReceivePaymentResponse resp = await _breezSdkLiquid.instance!.receivePayment(req: req);

      final String address = resp.destination;
      final int estimateBaseFeeSat = prepareResp.feesSat.toInt();
      final double? estimateProportionalFee = prepareResp.swapperFeerate;

      _logger.info(
        'Successfully generated amountless BTC address: $address, '
        'estimated base fees: $estimateBaseFeeSat sats, '
        'estimate proportional fees: $estimateProportionalFee%',
      );

      emit(
        AmountlessBtcState(
          address: address,
          estimateBaseFeeSat: estimateBaseFeeSat,
          estimateProportionalFee: estimateProportionalFee,
        ),
      );
    } catch (e) {
      _logger.severe('Failed to generate amountless BTC address', e);
      emit(AmountlessBtcState(error: e));
    }
  }
}
