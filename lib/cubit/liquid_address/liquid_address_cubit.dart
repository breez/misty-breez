import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

export 'liquid_address_state.dart';

final Logger _logger = Logger('LiquidAddressCubit');

class LiquidAddressCubit extends Cubit<LiquidAddressState> {
  final BreezSDKLiquid _breezSdkLiquid;

  LiquidAddressCubit(this._breezSdkLiquid) : super(LiquidAddressState.initial());

  /// Generates a new Liquid address
  ///
  /// Unlike every other receive method, this one does not go through the Boltz swapper,
  /// so there are no swapper fees and no payment limits.
  Future<void> generateLiquidAddress() async {
    try {
      _logger.info('Generating Liquid address');

      emit(state.copyWith(isLoading: true));

      final PrepareReceiveRequest prepareReq = const PrepareReceiveRequest(
        paymentMethod: PaymentMethod.liquidAddress,
      );
      final PrepareReceiveResponse prepareResp = await _breezSdkLiquid.instance!.prepareReceivePayment(
        req: prepareReq,
      );
      final ReceivePaymentRequest req = ReceivePaymentRequest(prepareResponse: prepareResp);
      final ReceivePaymentResponse resp = await _breezSdkLiquid.instance!.receivePayment(req: req);

      final String address = resp.destination;

      _logger.info('Successfully generated Liquid address: $address');

      emit(LiquidAddressState(address: address));
    } catch (e) {
      _logger.severe('Failed to generate Liquid address', e);
      emit(LiquidAddressState(error: e));
    }
  }

  /// Resets the entire state to initial
  void reset() {
    _logger.info('Resetting LiquidAddressCubit state');
    emit(LiquidAddressState.initial());
  }
}
