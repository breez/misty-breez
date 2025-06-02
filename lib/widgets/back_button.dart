import 'package:flutter/material.dart';

class BackButton extends StatelessWidget {
  final void Function()? onPressed;
  final IconData? iconData;

  const BackButton({super.key, this.onPressed, this.iconData});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(iconData ?? const IconData(0xe906, fontFamily: 'icomoon')),
      onPressed:
          onPressed ??
          () {
            Navigator.pop(context);
          },
    );
  }
}
