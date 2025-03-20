import 'package:misty_breez/app/view/app.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/main/bootstrap.dart';
import 'package:service_injector/service_injector.dart';

void main() {
  bootstrap(
    (
      ServiceInjector injector,
      SdkConnectivityCubit sdkConnectivityCubit,
    ) =>
        App(
      injector: injector,
      sdkConnectivityCubit: sdkConnectivityCubit,
    ),
  );
}
