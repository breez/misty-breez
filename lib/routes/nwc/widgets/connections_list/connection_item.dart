import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';

class ConnectionItem extends StatefulWidget {
  final String connectionName;
  final NwcConnection connectionData;

  const ConnectionItem(this.connectionName, this.connectionData, {super.key});

  @override
  State<ConnectionItem> createState() => _ConnectionItemState();
}

class _ConnectionItemState extends State<ConnectionItem> {
  @override
  Widget build(BuildContext context) {
    // TODO(yse): Add widget rendering
    throw UnimplementedError();
  }
}
