import 'package:l_breez/app/view/app.dart';
import 'package:l_breez/main/bootstrap.dart';

void main() {
  bootstrap(
    (injector, sdkConnectivityCubit) => App(
      injector: injector,
      sdkConnectivityCubit: sdkConnectivityCubit,
    ),
  );
}
