import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

class NwcConnectionModel {
  final String name;
  final String connectionString;
  final PeriodicBudget? periodicBudget;
  final int? expiryTimeSec;
  final int createdAt;

  const NwcConnectionModel({
    required this.name,
    required this.connectionString,
    required this.createdAt, this.periodicBudget,
    this.expiryTimeSec,
  });
}

class NwcState {
  final List<NwcConnectionModel> connections;
  final bool isLoading;
  final String? error;

  const NwcState({this.connections = const <NwcConnectionModel>[], this.isLoading = false, this.error});

  NwcState.initial() : this();

  NwcState copyWith({List<NwcConnectionModel>? connections, bool? isLoading, String? error}) {
    return NwcState(
      connections: connections ?? this.connections,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
