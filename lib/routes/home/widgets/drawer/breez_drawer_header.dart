import 'package:flutter/material.dart';

const double _kBreezDrawerHeaderHeight = 160.0 + 1.0; // bottom edge

class BreezDrawerHeader extends DrawerHeader {
  const BreezDrawerHeader({
    super.key,
    super.decoration,
    super.margin = const EdgeInsets.only(bottom: 16.0),
    super.padding = const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
    super.duration = const Duration(milliseconds: 250),
    super.curve = Curves.fastOutSlowIn,
    required super.child,
  });

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMediaQuery(context));
    final ThemeData theme = Theme.of(context);
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      height: statusBarHeight + _kBreezDrawerHeaderHeight,
      margin: margin,
      child: AnimatedContainer(
        padding: padding.add(EdgeInsets.only(top: statusBarHeight)),
        decoration: decoration,
        duration: duration,
        curve: curve,
        child: DefaultTextStyle(
          style: theme.textTheme.headlineMedium!,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child!,
          ),
        ),
      ),
    );
  }
}
