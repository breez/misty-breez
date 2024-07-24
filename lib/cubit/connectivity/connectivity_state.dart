import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityState {
  final List<ConnectivityResult>? connectivityResult;

  const ConnectivityState({this.connectivityResult});

  const ConnectivityState.initial() : connectivityResult = null;

  bool get hasNetworkConnection =>
      connectivityResult != null && !connectivityResult!.contains(ConnectivityResult.none);

  ConnectivityState copyWith({
    List<ConnectivityResult>? connectivityResult,
  }) {
    return ConnectivityState(
      connectivityResult: connectivityResult ?? this.connectivityResult,
    );
  }

  @override
  String toString() {
    return 'ConnectivityState(connectivityResult: $connectivityResult)';
  }
}
