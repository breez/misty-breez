import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/nwc/widgets/nwc_add_connection_view.dart';
import 'package:misty_breez/routes/nwc/widgets/nwc_edit_connection_view.dart';
import 'package:misty_breez/theme/theme.dart';

Future<dynamic> showNwcConnectBottomSheet(
  BuildContext context, {
  NwcCubit? nwcCubit,
  NwcConnectionModel? existingConnection,
}) async {
  final ThemeData themeData = Theme.of(context);
  final NwcCubit activeCubit = nwcCubit ?? context.read<NwcCubit>();

  return await showModalBottomSheet(
    context: context,
    backgroundColor: themeData.customData.paymentListBgColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
    isScrollControlled: true,
    builder: (BuildContext context) => BlocProvider<NwcCubit>.value(
      value: activeCubit,
      child: NwcConnectBottomSheet(existingConnection: existingConnection),
    ),
  );
}

class NwcConnectBottomSheet extends StatelessWidget {
  final NwcConnectionModel? existingConnection;

  const NwcConnectBottomSheet({this.existingConnection, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: existingConnection != null
            ? NwcEditConnectionView(existingConnection: existingConnection!)
            : const NwcAddConnectionView(),
      ),
    );
  }
}
