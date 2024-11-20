import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';

class BackupInProgressDialog extends StatefulWidget {
  const BackupInProgressDialog({super.key});

  @override
  BackupInProgressDialogState createState() => BackupInProgressDialogState();
}

class BackupInProgressDialogState extends State<BackupInProgressDialog> {
  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    return BlocListener<BackupCubit, BackupState?>(
      listener: (BuildContext context, BackupState? state) {
        if (state?.status != BackupStatus.inProgress) {
          Navigator.of(context).pop();
        }
      },
      child: createAnimatedLoaderDialog(context, texts.backup_in_progress),
    );
  }
}
