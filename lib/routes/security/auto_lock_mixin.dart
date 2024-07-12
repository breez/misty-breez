import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart' as cubit;
import 'package:l_breez/routes/security/lock_screen.dart';
import 'package:l_breez/widgets/route.dart';

mixin AutoLockMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    final securityCubit = context.read<cubit.SecurityCubit>();
    securityCubit.stream.distinct().where((state) => state.lockState == cubit.LockState.locked).listen(
      (_) {
        Navigator.of(context, rootNavigator: true).push(
          FadeInRoute(
            builder: (_) => const LockScreen(
              authorizedAction: AuthorizedAction.popPage,
            ),
          ),
        );
      },
    );
  }
}
