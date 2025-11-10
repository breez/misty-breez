import 'package:flutter/material.dart';

class WarningCard extends StatelessWidget {
  final String? title;
  final String message;
  final IconData? icon;
  final Color? color;

  const WarningCard({required this.message, super.key, this.title, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final Color warningColor = color ?? Colors.orange;

    return Card(
      color: warningColor.withValues(alpha: .1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(icon ?? Icons.warning_amber_rounded, color: warningColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (title != null) ...<Widget>[
                    Text(title!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                  ],
                  Text(message, style: TextStyle(fontSize: title != null ? 14 : 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
