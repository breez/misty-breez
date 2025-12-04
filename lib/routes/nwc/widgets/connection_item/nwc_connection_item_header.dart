import 'package:flutter/material.dart';
import 'package:misty_breez/theme/src/theme.dart';

class NwcConnectionItemHeader extends StatelessWidget {
  final String connectionName;
  final bool hasPeriodicBudget;
  final bool isExpiringWithinWeek;
  final VoidCallback? onEdit;
  final VoidCallback? onShowQr;
  final bool centerTitle;
  final List<Widget>? actions;

  const NwcConnectionItemHeader({
    required this.connectionName,
    required this.hasPeriodicBudget,
    required this.isExpiringWithinWeek,
    this.onEdit,
    this.onShowQr,
    this.centerTitle = false,
    this.actions,
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
            bottom: Radius.circular(hasPeriodicBudget ? 0.0 : 12.0),
          ),
        ),
        color: const Color(0xFF142340),
      ),
      child: centerTitle
          ? Stack(
              alignment: Alignment.center,
              children: <Widget>[
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
                if (isExpiringWithinWeek)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: warningBoxColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      'Expires soon',
                      style: themeData.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).errorTextStyle.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
                  if (onShowQr != null || isExpiringWithinWeek) const SizedBox(width: 8.0),
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
