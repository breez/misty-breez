import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/routes/nwc/widgets/connections_list/connection_item.dart';

class ConnectionsList extends StatelessWidget {
  final double _kBottomPadding = 8.0;
  final double itemHeight;
  final Map<String, NwcConnection> connectionsList;

  const ConnectionsList({
    required this.connectionsList,
    required this.itemHeight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, NwcConnection>> entries = connectionsList
        .entries
        .toList();
    return SliverFixedExtentList(
      itemExtent: itemHeight + _kBottomPadding,
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) =>
            ConnectionItem(entries[index].key, entries[index].value),
        childCount: entries.length,
      ),
    );
  }
}
