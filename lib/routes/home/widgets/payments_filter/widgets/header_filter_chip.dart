import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';

class HeaderFilterChip extends SliverPadding {
  HeaderFilterChip(double maxHeight, DateTime startDate, DateTime endDate, {super.key})
    : super(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        sliver: SliverPersistentHeader(
          pinned: true,
          delegate: FixedSliverDelegate(
            maxHeight / 1.2,
            builder: (BuildContext context, double height, bool overlap) {
              final CustomData customData = Theme.of(context).customData;
              return Container(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                height: maxHeight / 1.2,
                color: customData.dashboardBgColor,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    color: customData.paymentListBgColor,
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
                          child: Chip(
                            label: Text(BreezDateUtils.formatFilterDateRange(startDate, endDate)),
                            onDeleted: () {
                              final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();
                              return paymentsCubit.changePaymentFilter();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
}
