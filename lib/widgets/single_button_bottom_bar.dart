import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class SingleButtonBottomBar extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool stickToBottom;

  const SingleButtonBottomBar({super.key,
    required this.text,
    this.onPressed,
    this.stickToBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: stickToBottom ? MediaQuery.of(context).viewInsets.bottom + 40.0 : 40.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 48.0,
              minWidth: 168.0,
            ),
            child: SubmitButton(
              text,
              onPressed,
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

  const SubmitButton(
    this.text,
    this.onPressed, {super.key,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 48.0,
        minWidth: 168.0,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? themeData.primaryColor : themeData.disabledColor,
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: onPressed,
        child: AutoSizeText(
          text,
          maxLines: 1,
          style: themeData.textTheme.labelLarge,
        ),
      ),
    );
  }
}
