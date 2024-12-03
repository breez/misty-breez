import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';

class ScrollableErrorMessageWidget extends StatefulWidget {
  final EdgeInsets padding;
  final EdgeInsets contentPadding;
  final String? title;
  final String message;
  final TextStyle? titleStyle;
  final TextStyle? errorTextStyle;
  final bool showIcon;

  const ScrollableErrorMessageWidget({
    required this.message,
    super.key,
    this.padding = const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
    this.contentPadding = EdgeInsets.zero,
    this.title,
    this.titleStyle,
    this.errorTextStyle,
    this.showIcon = false,
  });

  @override
  State<ScrollableErrorMessageWidget> createState() => _ScrollableErrorMessageWidgetState();
}

class _ScrollableErrorMessageWidgetState extends State<ScrollableErrorMessageWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.showIcon)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Icon(
                  Icons.warning,
                  size: 100.0,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
          if (widget.title != null && widget.title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: AutoSizeText(
                widget.title!,
                style: widget.titleStyle ??
                    themeData.textTheme.labelMedium!.copyWith(
                      fontSize: 18.0,
                    ),
                textAlign: TextAlign.left,
                maxLines: 1,
              ),
            ),
          Padding(
            padding: widget.contentPadding,
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 200,
                minWidth: double.infinity,
              ),
              child: Scrollbar(
                controller: _scrollController,
                radius: const Radius.circular(16.0),
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: AutoSizeText(
                    widget.message,
                    style: widget.errorTextStyle ??
                        themeData.errorTextStyle.copyWith(
                          fontSize: 16.0,
                        ),
                    textAlign: widget.message.length > 40 && !widget.message.contains('\n')
                        ? TextAlign.start
                        : TextAlign.left,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
