import 'package:logging/logging.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

final Logger _logger = Logger('NWCState');

class NwcConnectionModel {
  final String name;
  final String connectionString;
  final PeriodicBudget? periodicBudget;
  final int? expiresAt;
  final int createdAt;

  const NwcConnectionModel({
    required this.name,
    required this.connectionString,
    required this.createdAt,
    this.periodicBudget,
    this.expiresAt,
  });

  Map<String, dynamic> _encodeBudget(PeriodicBudget budget) => <String, dynamic>{
    'usedBudgetSat': budget.usedBudgetSat.toString(),
    'maxBudgetSat': budget.maxBudgetSat.toString(),
    'renewsAt': budget.renewsAt,
    'updatedAt': budget.updatedAt,
  };

  static PeriodicBudget _decodeBudget(Map<String, dynamic> json) => PeriodicBudget(
    usedBudgetSat: BigInt.parse(json['usedBudgetSat']),
    maxBudgetSat: BigInt.parse(json['maxBudgetSat']),
    renewsAt: json['renewsAt'],
    updatedAt: json['updatedAt'],
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'connectionString': connectionString,
    'periodicBudget': periodicBudget != null ? _encodeBudget(periodicBudget!) : null,
    'expiresAt': expiresAt,
    'createdAt': createdAt,
  };

  factory NwcConnectionModel.fromJson(Map<String, dynamic> json) {
    final String name = json['name'];
    final String connectionString = json['connectionString'];
    final PeriodicBudget? periodicBudget = json['periodicBudget'] != null
        ? _decodeBudget(json['periodicBudget'])
        : null;
    final int? expiresAt = json['expiresAt'];
    final int createdAt = json['createdAt'];
    return NwcConnectionModel(
      name: name,
      connectionString: connectionString,
      periodicBudget: periodicBudget,
      expiresAt: expiresAt,
      createdAt: createdAt,
    );
  }
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

  Map<String, dynamic> toJson() => <String, dynamic>{
    'error': error,
    'isLoading': isLoading,
    'connections': connections.map((NwcConnectionModel connection) => connection.toJson()).toList(),
  };

  factory NwcState.fromJson(Map<String, dynamic> json) {
    try {
      final String? error = json['error'];
      final bool isLoading = json['isLoading'];

      final List<NwcConnectionModel> connections = (json['connections'] as List<dynamic>)
          .map((dynamic connection) => NwcConnectionModel.fromJson(connection as Map<String, dynamic>))
          .toList();

      return NwcState(connections: connections, isLoading: isLoading, error: error);
    } catch (e, stack) {
      _logger.severe('Error parsing NwcState from JSON: $e\n$stack');
      return NwcState.initial();
    }
  }
}
