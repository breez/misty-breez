import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class SingleButtonBottomBar extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool stickToBottom;
  final bool enabled;
  final bool expand;

  const SingleButtonBottomBar({
    required this.text,
    super.key,
    this.onPressed,
    this.stickToBottom = false,
    this.enabled = true,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: stickToBottom ? MediaQuery.of(context).viewInsets.bottom + 40.0 : 40.0,
      ),
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 48.0,
              minWidth: 168.0,
            ),
            child: SubmitButton(
              text,
              onPressed,
              enabled: enabled,
              expand: expand,
            ),
          ),
        ],
      ),
    );
  }
}

class SubmitButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool enabled;
  final bool expand;

  const SubmitButton(
    this.text,
    this.onPressed, {
    super.key,
    this.enabled = true,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 48.0,
        minWidth: 168.0,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeData.primaryColor,
          elevation: 0.0,
          disabledBackgroundColor: themeData.disabledColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          minimumSize: expand ? Size(screenWidth, 48) : null,
        ),
        onPressed: enabled ? onPressed : null,
        child: AutoSizeText(
          text,
          maxLines: 1,
          style: themeData.textTheme.labelLarge,
        ),
      ),
    );
  }
}
