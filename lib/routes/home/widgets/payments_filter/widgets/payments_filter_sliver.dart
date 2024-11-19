import 'package:flutter/material.dart';
import 'package:l_breez/routes/home/home.dart';
import 'package:l_breez/theme/theme.dart';

class PaymentsFilterSliver extends StatefulWidget {
  final double maxSize;
  final bool hasFilter;
  final ScrollController scrollController;

  const PaymentsFilterSliver({
    required this.maxSize,
    required this.hasFilter,
    required this.scrollController,
    super.key,
  });

  @override
  State<PaymentsFilterSliver> createState() => _PaymentsFilterSliverState();
}

class _PaymentsFilterSliverState extends State<PaymentsFilterSliver> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(onScroll);
    super.dispose();
  }

  void onScroll() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final double scrollOffset = widget.scrollController.position.pixels;

    return SliverPersistentHeader(
      pinned: true,
      delegate: FixedSliverDelegate(
        widget.hasFilter
            ? widget.maxSize
            : scrollOffset.clamp(
                0,
                widget.maxSize,
              ),
        builder: (BuildContext context, double height, bool overlapContent) {
          return Container(
            color: themeData.isLightTheme ? themeData.colorScheme.surface : themeData.canvasColor,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  color: themeData.customData.paymentListBgColor,
                  height: widget.maxSize,
                  child: const PaymentsFilters(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
