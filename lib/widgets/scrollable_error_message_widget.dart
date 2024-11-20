import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';

class ScrollableErrorMessageWidget extends StatefulWidget {
  final EdgeInsets? padding;
  final String? title;
  final String message;

  const ScrollableErrorMessageWidget({
    required this.message,
    super.key,
    this.padding,
    this.title,
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
      padding: widget.padding ?? const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.title != null && widget.title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: AutoSizeText(
                widget.title!,
                style: themeData.textTheme.labelMedium,
                textAlign: TextAlign.left,
                maxLines: 1,
              ),
            ),
          Container(
            constraints: const BoxConstraints(
              maxHeight: 100,
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
                  style: themeData.errorTextStyle,
                  textAlign: widget.message.length > 40 && !widget.message.contains('\n')
                      ? TextAlign.start
                      : TextAlign.left,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
