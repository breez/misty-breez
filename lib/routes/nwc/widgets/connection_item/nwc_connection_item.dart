import 'package:flutter/material.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/src/theme.dart';

class NwcConnectionItem extends StatefulWidget {
  final NwcConnectionModel connection;

  const NwcConnectionItem({required this.connection, super.key});

  @override
  State<NwcConnectionItem> createState() => _NwcConnectionItemState();
}

class _NwcConnectionItemState extends State<NwcConnectionItem> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _iconRotation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final bool hasContent = widget.connection.periodicBudget != null;

    return Card(
      color: themeData.customData.surfaceBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: () {
              Navigator.of(
                context,
              ).pushNamed(NwcConnectionDetailPage.routeName, arguments: widget.connection);
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12.0),
              bottom: Radius.circular(hasContent && _isExpanded ? 0.0 : 12.0),
            ),
            child: NwcConnectionItemHeader(
              connectionName: widget.connection.name,
              hasContent: hasContent && _isExpanded,
              showDropdownArrow: hasContent,
              iconRotation: _iconRotation,
              onDropdownTap: hasContent ? _toggleExpanded : null,
            ),
          ),
          if (hasContent)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? InkWell(
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(NwcConnectionDetailPage.routeName, arguments: widget.connection);
                      },
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12.0)),
                      child: NwcConnectionItemContent(connection: widget.connection),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
