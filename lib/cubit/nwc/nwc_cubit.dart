import 'dart:async';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/nwc/nwc_state.dart';
import 'package:misty_breez/cubit/nwc/services/services.dart';

export 'factories/factories.dart';
export 'models/models.dart';
export 'nwc_state.dart';
export 'services/services.dart';

final Logger _logger = Logger('NwcCubit');

class NwcCubit extends Cubit<NwcState> {
  final BreezSDKLiquid breezSdkLiquid;
  final NwcRegistrationManager registrationManager;

  NwcCubit({required this.breezSdkLiquid, required this.registrationManager}) : super(NwcState.initial()) {
    loadConnections();
  }

  /// Loads all NWC connections from the service
  Future<void> loadConnections() async {
    emit(state.copyWith(isLoading: true));

    try {
      final BreezNwcService? nwcService = breezSdkLiquid.plugins?.nwc;

      if (nwcService == null) {
        emit(state.copyWith(connections: [], isLoading: false, error: 'NWC service is not available'));
        return;
      }

      final Map<String, NwcConnection> connectionsMap = await nwcService.listConnections();

      final List<NwcConnectionModel> connections = connectionsMap.entries
          .map(
            (MapEntry<String, NwcConnection> entry) =>
                NwcConnectionModel(name: entry.key, connectionString: entry.value.connectionString),
          )
          .toList();

      emit(state.copyWith(connections: connections, isLoading: false));
    } catch (e) {
      _logger.severe('Failed to load NWC connections', e);
      emit(state.copyWith(isLoading: false, error: 'Failed to load connections: ${e.toString()}'));
    }
  }

  /// Creates a new NWC connection with the given name
  Future<String?> createConnection(String name) async {
    emit(state.copyWith(isLoading: true));

    try {
      final BreezNwcService? nwcService = breezSdkLiquid.plugins?.nwc;

      if (nwcService == null) {
        emit(state.copyWith(isLoading: false, error: 'NWC service is not available'));
        return null;
      }

      final AddConnectionRequest request = AddConnectionRequest(
        name: name,
        // TODO(ayushsaksena30): Add field customization
        expiryTimeSec: null, // No expiry by default
        receiveOnly: null, // Default to false
        periodicBudgetReq: null, // No budget by default
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
      final BreezNwcService? nwcService = breezSdkLiquid.plugins?.nwc;

      if (nwcService == null) {
        emit(state.copyWith(isLoading: false, error: 'NWC service is not available'));
        return;
      }

      await nwcService.removeConnection(name: name);

      emit(state.copyWith(isLoading: false));

      await loadConnections();
    } catch (e) {
      _logger.severe('Failed to delete NWC connection', e);
      emit(state.copyWith(isLoading: false, error: 'Failed to delete connection: ${e.toString()}'));
    }
  }
}
