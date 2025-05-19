import 'package:misty_breez/utils/utils.dart';

extension PaymentTitleExtension on String {
  // TODO(erdemyerebasmaz): Remove once default descriptions from the SDK is removed
  bool get isDefaultDescription {
    return this == 'Send to L-BTC address' ||
        this == 'Liquid transfer' ||
        this == 'Lightning payment' ||
        this == PaymentConstants.bolt12OfferDescription;
  }
}
