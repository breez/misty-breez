import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/home/widgets/bubble_painter.dart';
import 'package:l_breez/routes/home/widgets/dashboard/wallet_dashboard_header_delegate.dart';
import 'package:l_breez/routes/home/widgets/payments_filter/fixed_sliver_delegate.dart';
import 'package:l_breez/routes/home/widgets/payments_filter/header_filter_chip.dart';
import 'package:l_breez/routes/home/widgets/payments_filter/payments_filter_sliver.dart';
import 'package:l_breez/routes/home/widgets/payments_list/payments_list.dart';
import 'package:l_breez/routes/home/widgets/payments_list/placeholder_payment_item.dart';
import 'package:l_breez/routes/home/widgets/status_text.dart';
import 'package:l_breez/theme/theme.dart';

const double _kFilterMaxSize = 64.0;
const double _kPaymentListItemHeight = 72.0;
const int _kPlaceholderListItemCount = 8;

class AccountPage extends StatelessWidget {
  final GlobalKey firstPaymentItemKey;
  final ScrollController scrollController;

  const AccountPage(
    this.firstPaymentItemKey,
    this.scrollController, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (BuildContext context, AccountState accountState) {
        return BlocBuilder<PaymentsCubit, PaymentsState>(
          builder: (BuildContext context, PaymentsState paymentsState) {
            final List<PaymentData> nonFilteredPayments = paymentsState.payments;
            final PaymentFilters paymentFilters = paymentsState.paymentFilters;
            final List<PaymentData> filteredPayments = paymentsState.filteredPayments;

            final List<Widget> slivers = <Widget>[];

            slivers.add(
              const SliverPersistentHeader(
                delegate: WalletDashboardHeaderDelegate(),
                pinned: true,
              ),
            );

            final bool showPaymentsList = filteredPayments.isNotEmpty;
            final bool hasTypeFilter = paymentFilters.filters != PaymentType.values;
            final int? startDate = paymentFilters.fromTimestamp;
            final int? endDate = paymentFilters.toTimestamp;
            final bool hasDateFilter = startDate != null && endDate != null;
            if (showPaymentsList || hasTypeFilter) {
              slivers.add(
                PaymentsFilterSliver(
                  maxSize: _kFilterMaxSize,
                  scrollController: scrollController,
                  hasFilter: hasTypeFilter || hasDateFilter,
                ),
              );
            }

            if (hasDateFilter) {
              slivers.add(
                HeaderFilterChip(
                  _kFilterMaxSize,
                  DateTime.fromMillisecondsSinceEpoch(startDate),
                  DateTime.fromMillisecondsSinceEpoch(endDate),
                ),
              );
            }

            if (showPaymentsList) {
              slivers.add(
                PaymentsList(
                  paymentsList: filteredPayments,
                  paymentItemHeight: _kPaymentListItemHeight,
                  firstPaymentItemKey: firstPaymentItemKey,
                ),
              );
              slivers.add(
                SliverPersistentHeader(
                  pinned: true,
                  delegate: FixedSliverDelegate(
                    _bottomPlaceholderSpace(
                      context,
                      paymentFilters.hasDateFilters,
                      nonFilteredPayments.isEmpty ? _kPlaceholderListItemCount : filteredPayments.length,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            } else if (accountState.isRestoring && nonFilteredPayments.isEmpty) {
              slivers.add(
                SliverFixedExtentList(
                  itemExtent: _kPaymentListItemHeight + 8.0,
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => const PlaceholderPaymentItem(),
                    childCount: _kPlaceholderListItemCount,
                  ),
                ),
              );
              slivers.add(
                SliverPersistentHeader(
                  pinned: true,
                  delegate: FixedSliverDelegate(
                    _bottomPlaceholderSpace(
                      context,
                      paymentFilters.hasDateFilters,
                      nonFilteredPayments.isEmpty ? _kPlaceholderListItemCount : filteredPayments.length,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            } else {
              slivers.add(
                SliverPersistentHeader(
                  delegate: FixedSliverDelegate(
                    250.0,
                    builder: (BuildContext context, double shrinkedHeight, bool overlapContent) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(40.0, 120.0, 40.0, 0.0),
                        child: StatusText(),
                      );
                    },
                  ),
                ),
              );
            }

            return Container(
              color: Theme.of(context).customData.dashboardBgColor,
              child: Stack(
                key: const Key('account_sliver'),
                fit: StackFit.expand,
                children: <Widget>[
                  if (!showPaymentsList &&
                      !(accountState.isRestoring && nonFilteredPayments.isEmpty)) ...<Widget>[
                    CustomPaint(painter: BubblePainter(context)),
                  ],
                  CustomScrollView(
                    controller: scrollController,
                    slivers: slivers,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  double _bottomPlaceholderSpace(
    BuildContext context,
    bool hasDateFilters,
    int paymentsSize,
  ) {
    if (paymentsSize == 0) {
      return 0.0;
    }

    final Size screenSize = MediaQuery.of(context).size;
    final double listHeightSpace = screenSize.height - kMinExtent - kToolbarHeight - _kFilterMaxSize - 25.0;
    final double dateFilterSpace = hasDateFilters ? 0.65 : 0.0;
    final double requiredSpace = (_kPaymentListItemHeight + 8) * (paymentsSize + 1 + dateFilterSpace);
    return (listHeightSpace - requiredSpace).clamp(0.0, listHeightSpace);
  }
}
