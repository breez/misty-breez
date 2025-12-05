import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

export 'factories/factories.dart';
export 'models/models.dart';
export 'nwc_state.dart';
export 'services/services.dart';

final Logger _logger = Logger('NwcCubit');

class NwcCubit extends Cubit<NwcState> {
  final BreezSDKLiquid breezSdkLiquid;
  final NwcRegistrationManager nwcRegistrationManager;
  StreamSubscription<NwcEvent>? _nwcEventSubscription;

  NwcCubit({required this.breezSdkLiquid, required this.nwcRegistrationManager}) : super(NwcState.initial()) {
    loadConnections();
    _setupEventListener();
  }

  void _setupEventListener() {
    final BreezNwcService? nwcService = breezSdkLiquid.nwc;
    if (nwcService == null) {
      _logger.warning('NWC service is not available, cannot set up event listener');
      return;
    }

    _nwcEventSubscription?.cancel();
    _nwcEventSubscription = nwcService.addEventListener().listen(
      (NwcEvent event) {
        _handleNwcEvent(event);
      },
      onError: (Object error) {
        _logger.severe('Error in NWC event stream', error);
      },
    );
  }

  void _handleNwcEvent(NwcEvent event) {
    _logger.info('Received NWC event: ${event.details} for connection: ${event.connectionName}');

    if (event.details is NwcEventDetails_ConnectionExpired || event.details is NwcEventDetails_Disconnected) {
      final String? connectionName = event.connectionName;
      if (connectionName != null) {
        _removeConnectionFromState(connectionName);
      }
    }
  }

  void _removeConnectionFromState(String connectionName) {
    final bool connectionExists = state.connections.any(
      (NwcConnectionModel connection) => connection.name == connectionName,
    );

    if (!connectionExists) {
      _logger.fine('Connection "$connectionName" already removed from state');
      return;
    }

    final List<NwcConnectionModel> updatedConnections = state.connections
        .where((NwcConnectionModel connection) => connection.name != connectionName)
        .toList();
    emit(state.copyWith(connections: updatedConnections));
    _logger.info('Removed connection "$connectionName" from state');
  }

  @override
  Future<void> close() {
    _nwcEventSubscription?.cancel();
    return super.close();
  }

  /// Loads all NWC connections from the service
  Future<void> loadConnections() async {
    emit(state.copyWith(isLoading: true));

    try {
      final BreezNwcService? nwcService = breezSdkLiquid.nwc;

      if (nwcService == null) {
        emit(
          state.copyWith(
            connections: <NwcConnectionModel>[],
            isLoading: false,
            error: 'NWC service is not available',
          ),
        );
        return;
      }

      final Map<String, NwcConnection> connectionsMap = await nwcService.listConnections();

      final List<NwcConnectionModel> connections =
          connectionsMap.entries
              .map(
                (MapEntry<String, NwcConnection> entry) => NwcConnectionModel(
                  name: entry.key,
                  connectionString: entry.value.connectionString,
                  periodicBudget: entry.value.periodicBudget,
                  expiresAt: entry.value.expiresAt,
                  createdAt: entry.value.createdAt,
                ),
              )
              .toList()
            ..sort(
              (NwcConnectionModel a, NwcConnectionModel b) =>
                  a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      emit(NwcState(connections: connections));
    } catch (e) {
      _logger.severe('Failed to load NWC connections', e);
      emit(state.copyWith(isLoading: false, error: 'Failed to load connections: ${e.toString()}'));
    }
  }

  /// Creates a new NWC connection with the given name
  Future<String?> createConnection({
    required String name,
    int? expirationTimeMins,
    PeriodicBudgetRequest? periodicBudgetReq,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      final BreezNwcService? nwcService = breezSdkLiquid.nwc;

      if (nwcService == null) {
        emit(state.copyWith(isLoading: false, error: 'NWC service is not available'));
        return null;
      }

      final AddConnectionRequest request = AddConnectionRequest(
        name: name,
        expiryTimeMins: expirationTimeMins,
        periodicBudgetReq: periodicBudgetReq,
      );

      final AddConnectionResponse response = await nwcService.addConnection(req: request);
      final String connectionString = response.connection.connectionString;

      emit(state.copyWith(isLoading: false));

      await loadConnections();

      return connectionString;
    } catch (e) {
      _logger.severe('Failed to create NWC connection', e);
      emit(state.copyWith(isLoading: false, error: 'Failed to create connection: ${e.toString()}'));
      return null;
    }
  }

  /// Deletes an NWC connection by name
  Future<void> deleteConnection(String name) async {
    emit(state.copyWith(isLoading: true));

    try {
      final BreezNwcService? nwcService = breezSdkLiquid.nwc;

      if (nwcService == null) {
        emit(state.copyWith(isLoading: false, error: 'NWC service is not available'));
        return;
      }

      _removeConnectionFromState(name);

      await nwcService.removeConnection(name: name);

      await loadConnections();
    } catch (e) {
      _logger.severe('Failed to delete NWC connection', e);
      await loadConnections();
      emit(state.copyWith(isLoading: false, error: 'Failed to delete connection: ${e.toString()}'));
    }
  }

  /// Edits an NWC connection
  Future<bool> editConnection({
    required String name,
    int? expirationTimeMins,
    bool? removeExpiry,
    PeriodicBudgetRequest? periodicBudgetReq,
    bool? removePeriodicBudget,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      final BreezNwcService? nwcService = breezSdkLiquid.nwc;

      if (nwcService == null) {
        emit(state.copyWith(isLoading: false, error: 'NWC service is not available'));
        return false;
      }

      final EditConnectionRequest request = EditConnectionRequest(
        name: name,
        expiryTimeMins: expirationTimeMins,
        removeExpiry: removeExpiry,
        periodicBudgetReq: periodicBudgetReq,
        removePeriodicBudget: removePeriodicBudget,
      );

      await nwcService.editConnection(req: request);

      emit(state.copyWith(isLoading: false));

      await loadConnections();

      return true;
    } catch (e) {
      _logger.severe('Failed to edit NWC connection', e);
      emit(state.copyWith(isLoading: false, error: 'Failed to edit connection: ${e.toString()}'));
      return false;
    }
  }
}
