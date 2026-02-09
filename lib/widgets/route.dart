import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FadeInRoute<T> extends CupertinoPageRoute<T> {
  FadeInRoute({required super.builder, super.settings});

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fades between routes. (If you don't want any animation,
    // just return child.)
    return FadeTransition(opacity: animation, child: child);
  }
}

/// A [FadeInRoute] that reuses an existing [C] cubit from context if available,
/// otherwise wraps the child in a [BlocProvider] to create one.
class OptionalBlocFadeInRoute<C extends Cubit<Object?>> extends FadeInRoute<void> {
  OptionalBlocFadeInRoute({
    required C Function(BuildContext context) create,
    required Widget Function(BuildContext context) childBuilder,
    super.settings,
  }) : super(
          builder: (BuildContext context) {
            final C? existing = context.read<C?>();
            return existing != null
                ? childBuilder(context)
                : BlocProvider<C>(
                    create: (_) => create(context),
                    child: childBuilder(context),
                  );
          },
        );
}

class NoTransitionRoute<T> extends CupertinoPageRoute<T> {
  NoTransitionRoute({required super.builder, super.settings});

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
