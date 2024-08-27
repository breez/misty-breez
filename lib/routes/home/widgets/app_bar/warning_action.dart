import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class WarningAction extends StatefulWidget {
  final void Function() onTap;
  final Widget? iconWidget;

  const WarningAction({super.key, required this.onTap, this.iconWidget});

  @override
  State<StatefulWidget> createState() => WarningActionState();
}

class WarningActionState extends State<WarningAction> with SingleTickerProviderStateMixin {
  Animation<double>? _animation;
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController!);
    _animation!.addListener(() {
      setState(() {});
    });
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final texts = context.texts();

    return IconButton(
      iconSize: 45.0,
      padding: EdgeInsets.zero,
      icon: SizedBox(
        width: 45 * _animation!.value,
        child: widget.iconWidget ??
            SvgPicture.asset(
              "assets/icons/warning.svg",
              colorFilter: ColorFilter.mode(
                themeData.appBarTheme.actionsIconTheme!.color!,
                BlendMode.srcATop,
              ),
            ),
      ),
      tooltip: texts.account_required_actions_backup,
      onPressed: widget.onTap,
    );
  }
}
