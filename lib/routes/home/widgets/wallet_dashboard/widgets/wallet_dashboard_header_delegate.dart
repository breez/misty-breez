import 'package:flutter/material.dart';
import 'package:l_breez/routes/routes.dart';

const double kMaxExtent = 200.0;
const double kMinExtent = 70.0;

class WalletDashboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  const WalletDashboardHeaderDelegate();

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return WalletDashboard(
      height: (kMaxExtent - shrinkOffset).clamp(kMinExtent, kMaxExtent),
      offsetFactor: (shrinkOffset / (kMaxExtent - kMinExtent)).clamp(0.0, 1.0),
    );
  }

  @override
  double get maxExtent => kMaxExtent;

  @override
  double get minExtent => kMinExtent;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return snapConfiguration != oldDelegate.snapConfiguration;
  }
}
