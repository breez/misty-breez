import 'package:misty_breez/app/app.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/main/main.dart';
import 'package:service_injector/service_injector.dart';

export 'bootstrap.dart';
export 'bootstrap_error_page.dart';
export 'hydrated_bloc_storage.dart';

void main() {
  bootstrap(
    (ServiceInjector injector, SdkConnectivityCubit sdkConnectivityCubit) =>
        App(injector: injector, sdkConnectivityCubit: sdkConnectivityCubit),
  );
}
