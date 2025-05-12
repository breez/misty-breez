import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/services/services.dart';

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.bolt12Offer:
        return 'BOLT 12 Offer';
      case PaymentMethod.bolt11Invoice:
      case PaymentMethod.lightning:
        return 'Lightning';
      case PaymentMethod.bitcoinAddress:
        return 'BTC Address';
      case PaymentMethod.liquidAddress:
        return 'Liquid Address';
    }
  }

  /// Returns the localized display name for the payment method
  String getLocalizedName(BuildContext context, {String? lnAddress}) {
    final BreezTranslations texts = context.texts();

    switch (this) {
      case PaymentMethod.bolt12Offer:
        // TODO(erdemyerebasmaz): Add message to Breez-Translations
        // return texts.receive_payment_method_bolt12_offer;
        return 'Bolt 12 Offer';
      case PaymentMethod.bolt11Invoice:
        return texts.receive_payment_method_lightning_invoice;
      case PaymentMethod.lightning:
        return lnAddress != null
            ? texts.receive_payment_method_lightning_address
            : texts.receive_payment_method_lightning_invoice;
      case PaymentMethod.bitcoinAddress:
        return texts.receive_payment_method_btc_address;
      case PaymentMethod.liquidAddress:
        return texts.receive_payment_method_liquid_address;
    }
  }

  /// Returns the tracking type associated with this payment method
  PaymentTrackingType getTrackingType({String? lnAddress}) {
    switch (this) {
      case PaymentMethod.bolt11Invoice:
      case PaymentMethod.bolt12Offer:
        return PaymentTrackingType.lightningInvoice;
      case PaymentMethod.lightning:
        return lnAddress != null
            ? PaymentTrackingType.lightningAddress
            : PaymentTrackingType.lightningInvoice;
      case PaymentMethod.liquidAddress:
      case PaymentMethod.bitcoinAddress:
        return PaymentTrackingType.bitcoinTransaction;
    }
  }
}
