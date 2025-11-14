import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:service_injector/service_injector.dart';

final Logger _logger = Logger('NwcView');

/// A view that provides control over NWC-related methods
class NwcView extends StatefulWidget {
  static const String routeName = '/nwc';

  const NwcView({super.key});

  @override
  State<NwcView> createState() => _NwcViewState();
}

class _NwcViewState extends State<NwcView> {
  final Map<String, NwcConnection> _connections = <String, NwcConnection>{};

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    final BreezNwcService? nwcService =
        ServiceInjector().breezSdkLiquid.plugins?.nwc;
    if (nwcService != null) {
      final Map<String, NwcConnection> connections = await nwcService
          .listConnections();
      setState(() {
        _connections.addAll(connections);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nostr Wallet Connect')),
      body: throw UnimplementedError(), // TODO(yse): Add widget rendering
    );
  }
}
