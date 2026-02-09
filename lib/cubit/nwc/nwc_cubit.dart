import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:collection/collection.dart';

export 'factories/factories.dart';
export 'models/models.dart';
export 'nwc_state.dart';
export 'services/services.dart';

final Logger _logger = Logger('NwcCubit');

class NwcCubit extends Cubit<NwcState> with HydratedMixin<NwcState> {
  final BreezSDKLiquid breezSdkLiquid;
  final NwcRegistrationManager nwcRegistrationManager;
  StreamSubscription<NwcEvent>? _nwcEventSubscription;

  NwcCubit({required this.breezSdkLiquid, required this.nwcRegistrationManager}) : super(NwcState.initial()) {
    hydrate();
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

  NwcConnectionModel? _removeConnectionFromState(String connectionName) {
    final NwcConnectionModel? connection = state.connections.firstWhereOrNull(
      (NwcConnectionModel connection) => connection.name == connectionName,
    );

    if (connection == null) {
      _logger.fine('Connection "$connectionName" already removed from state');
      return null;
    }
    final List<NwcConnectionModel> updatedConnections = state.connections
        .where((NwcConnectionModel connection) => connection.name != connectionName)
        .toList();
    emit(state.copyWith(connections: updatedConnections));
    _logger.info('Removed connection "$connectionName" from state');
    return connection;
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

      final InputType parsedNwcUri = await breezSdkLiquid.instance!.parse(
        input: response.connection.connectionString,
      );
      switch (parsedNwcUri) {
        case InputType_NostrWalletConnectUri(data: final NostrWalletConnectUri uri):
          // According to NIP-47:
          // - walletServicePublicKey = wallet service pubkey (Breez)
          // - appPublicKey = client app pubkey (derived from secret)
          await nwcRegistrationManager.setupWebhook(
            (await breezSdkLiquid.instance!.getInfo()).walletInfo.pubkey,
            uri.walletServicePublicKey,
            uri.appPublicKey,
            uri.relays,
          );
        default:
          throw Exception('Invalid response type returned from the SDK.');
      }

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

      final NwcConnectionModel? connection = _removeConnectionFromState(name);
      if (connection == null) {
        return;
      }

      await nwcService.removeConnection(name: name);

      final InputType parsedNwcUri = await breezSdkLiquid.instance!.parse(input: connection.connectionString);
      switch (parsedNwcUri) {
        case InputType_NostrWalletConnectUri(data: final NostrWalletConnectUri uri):
          await nwcRegistrationManager.removeWebhook(
            (await breezSdkLiquid.instance!.getInfo()).walletInfo.pubkey,
            uri.walletServicePublicKey,
            uri.appPublicKey,
          );
        default:
          throw Exception('Invalid response type returned from the SDK.');
      }

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

  @override
  NwcState? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      _logger.severe('No stored data found.');
      return null;
    }

    try {
      final NwcState result = NwcState.fromJson(json);
      _logger.fine('Successfully hydrated with $result');
      return result;
    } catch (e, stackTrace) {
      _logger.severe('Error hydrating: $e');
      _logger.fine('Stack trace: $stackTrace');
      return NwcState.initial();
    }
  }

  @override
  Map<String, dynamic>? toJson(NwcState state) {
    try {
      final Map<String, dynamic> result = state.toJson();
      _logger.fine('Serialized: $result');
      return result;
    } catch (e) {
      _logger.severe('Error serializing: $e');
      return null;
    }
  }

  @override
  String get storagePrefix => 'NwcCubit';
}
