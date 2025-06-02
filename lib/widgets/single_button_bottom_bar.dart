import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

/// A widget that displays a single button at the bottom of the screen.
///
/// This widget handles padding, sizing, and button styling for a consistent
/// appearance across the app.
class SingleButtonBottomBar extends StatelessWidget {
  /// The text to display on the button.
  final String text;

  /// Whether to adjust the bottom padding for keyboard visibility.
  final bool stickToBottom;

  /// Whether the button is enabled.
  final bool enabled;

  /// Whether the button should expand to fill available width.
  final bool expand;

  /// Whether to show a loading indicator instead of text.
  final bool loading;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Creates a bottom bar with a single button.
  const SingleButtonBottomBar({
    required this.text,
    this.stickToBottom = false,
    this.enabled = true,
    this.expand = false,
    this.loading = false,
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(
        bottom: stickToBottom ? MediaQuery.of(context).viewInsets.bottom + 40.0 : 40.0,
      ),
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48.0, minWidth: 168.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.primaryColor,
                elevation: 0.0,
                disabledBackgroundColor: themeData.disabledColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                minimumSize: expand ? Size(screenWidth, 48) : null,
              ),
              onPressed: (enabled && !loading) ? onPressed : null,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : AutoSizeText(text, maxLines: 1, style: themeData.textTheme.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}
