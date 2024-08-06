import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/cubit/payments/payments_cubit.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/date.dart';

import 'fixed_sliver_delegate.dart';

class HeaderFilterChip extends SliverPadding {
  HeaderFilterChip(
    double maxHeight,
    DateTime startDate,
    DateTime endDate, {
    super.key,
  }) : super(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          sliver: SliverPersistentHeader(
            pinned: true,
            delegate: FixedSliverDelegate(
              maxHeight / 1.2,
              builder: (context, height, overlap) {
                final customData = Theme.of(context).customData;
                return Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  height: maxHeight / 1.2,
                  color: customData.dashboardBgColor,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      color: customData.paymentListBgColor,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
                            child: Chip(
                              label: Text(
                                BreezDateUtils.formatFilterDateRange(
                                  startDate,
                                  endDate,
                                ),
                              ),
                              onDeleted: () {
                                var paymentsCubit = context.read<PaymentsCubit>();
                                return paymentsCubit.changePaymentFilter(
                                  toTimestamp: null,
                                  fromTimestamp: null,
                                );
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
