import 'package:flutter/material.dart';

/// Handle at the top of the bottom sheet
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        margin: const EdgeInsets.only(top: 8.0),
        width: 40.0,
        height: 6.5,
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(50)),
      ),
    );
  }
}

/// Title display for the bottom sheet
class BottomSheetTitle extends StatelessWidget {
  final String title;

  const BottomSheetTitle({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: themeData.primaryTextTheme.headlineMedium!.copyWith(fontSize: 18.0, color: Colors.white),
        textAlign: TextAlign.left,
      ),
    );
  }
}
