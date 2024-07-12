import 'package:flutter/material.dart';

class Command extends StatelessWidget {
  final String command;
  final Function(String command) onTap;

  const Command(this.command, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(command),
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: Text(
          command,
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}
