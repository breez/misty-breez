import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/bloc/security/security_bloc.dart';
import 'package:l_breez/bloc/security/security_state.dart' as security;
import 'package:l_breez/routes/security/lock_screen.dart';
import 'package:l_breez/widgets/route.dart';

mixin AutoLockMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    final securityBloc = context.read<SecurityBloc>();
    securityBloc.stream.distinct().where((state) => state.lockState == security.LockState.locked).listen((_) {
      Navigator.of(context, rootNavigator: true).push(FadeInRoute(
        builder: (_) => const LockScreen(
          authorizedAction: AuthorizedAction.popPage,
        ),
      ));
    });
  }
}
