import 'package:flutter/material.dart';

class NwcConnectionItemHeader extends StatelessWidget {
  final String connectionName;
  final bool hasContent;
  final VoidCallback? onEdit;
  final VoidCallback? onShowQr;
  final bool centerTitle;
  final List<Widget>? actions;
  final bool showDropdownArrow;
  final Animation<double>? iconRotation;
  final VoidCallback? onDropdownTap;

  const NwcConnectionItemHeader({
    required this.connectionName,
    required this.hasContent,
    this.onEdit,
    this.onShowQr,
    this.centerTitle = false,
    this.actions,
    this.showDropdownArrow = false,
    this.iconRotation,
    this.onDropdownTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(12.0),
            bottom: Radius.circular(hasContent ? 0.0 : 12.0),
          ),
        ),
        color: const Color(0xFF142340),
      ),
      child: centerTitle
          ? Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if (onShowQr != null)
                  Positioned(
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.qr_code, size: 20.0, color: Colors.white),
                      onPressed: onShowQr,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Show QR',
                    ),
                  ),
                Center(
                  child: Text(
                    connectionName,
                    style: themeData.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (actions != null && actions!.isNotEmpty)
                  Positioned(
                    right: 0,
                    child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
                  ),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    connectionName,
                    style: themeData.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: showDropdownArrow ? onDropdownTap : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Opacity(
                      opacity: showDropdownArrow ? 1.0 : 0.0,
                      child: RotationTransition(
                        turns: iconRotation ?? const AlwaysStoppedAnimation<double>(0),
                        child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 24.0),
                      ),
                    ),
                  ),
                ),
                if (onShowQr != null)
                  IconButton(
                    icon: const Icon(Icons.qr_code, size: 20.0, color: Colors.white),
                    onPressed: onShowQr,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Show QR',
                  ),
                if (onEdit != null) ...<Widget>[
                  if (onShowQr != null || (showDropdownArrow && onDropdownTap != null))
                    const SizedBox(width: 8.0),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, size: 24.0, color: Colors.white),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit',
                  ),
                ],
              ],
            ),
    );
  }
}
