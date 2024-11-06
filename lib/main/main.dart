import 'package:l_breez/app/view/app.dart';
import 'package:l_breez/main/bootstrap.dart';

void main() {
  bootstrap(
    (injector, accountCubit, sdkConnectivityCubit) => App(
      injector: injector,
      accountCubit: accountCubit,
      sdkConnectivityCubit: sdkConnectivityCubit,
    ),
  );
}
