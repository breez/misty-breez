import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class StatusItem extends StatelessWidget {
  final AutoSizeGroup labelAutoSizeGroup = AutoSizeGroup();

  final String label;
  final String value;
  final void Function()? onLongPressed;

  StatusItem({required this.label, required this.value, this.onLongPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AutoSizeText(
              label,
              style: themeData.primaryTextTheme.headlineMedium?.copyWith(fontSize: 18.0, color: Colors.white),
              maxLines: 1,
              group: labelAutoSizeGroup,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: AutoSizeText(
                value,
                style: themeData.primaryTextTheme.displaySmall!.copyWith(fontSize: 18.0, color: Colors.white),
                textAlign: TextAlign.left,
                maxLines: 1,
                group: labelAutoSizeGroup,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
