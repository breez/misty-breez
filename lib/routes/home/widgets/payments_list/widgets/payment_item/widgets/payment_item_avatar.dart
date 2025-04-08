import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/widgets.dart';

class PaymentItemAvatar extends StatelessWidget {
  final PaymentData paymentData;
  final double radius;

  const PaymentItemAvatar(this.paymentData, {this.radius = 20.0, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    final String? base64String = paymentData.lnurlMetadataImage;
    Widget avatarChild;

    if (base64String?.isNotEmpty ?? false) {
      avatarChild = LNURLMetadataImage(
        base64String: base64String!,
        imageSize: radius,
      );
    } else {
      final String title = paymentData.title;
      if (title == texts.payment_info_title_unknown) {
        final UserProfileCubit userProfileCubit = context.read<UserProfileCubit>();
        final UserProfileState userProfileState = userProfileCubit.state;
        final UserProfileSettings user = userProfileState.profileSettings;
        String? avatarURL = '';

        if (paymentData.paymentType == PaymentType.receive) {
          avatarURL = user.avatarURL;
        }
        avatarChild = BreezAvatar(avatarURL, radius: radius);
      } else {
        avatarChild = Icon(
          paymentData.status == PaymentState.refundPending
              ? Icons.sync_alt
              : paymentData.isRefunded || paymentData.status == PaymentState.refundable
                  ? Icons.close_rounded
                  : paymentData.paymentType == PaymentType.receive
                      ? Icons.add_rounded
                      : Icons.remove_rounded,
          size: radius,
          color: const Color(0xb3303234),
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: avatarChild,
    );
  }
}
