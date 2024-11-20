import 'package:flutter/material.dart';

class LoadingOrError extends StatelessWidget {
  final Object? error;
  final String displayErrorMessage;

  const LoadingOrError({required this.displayErrorMessage, super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    if (error == null) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 310.0,
        child: Align(
          alignment: const Alignment(0, -0.33),
          child: SizedBox(
            height: 80.0,
            width: 80.0,
            child: CircularProgressIndicator(color: themeData.colorScheme.onSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        displayErrorMessage,
        style: themeData.primaryTextTheme.displaySmall!.copyWith(
          fontSize: 16,
        ),
      ),
    );
  }
}
