import 'package:flutter/material.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';

class RecoveryPhraseGrid extends StatelessWidget {
  final String mnemonic;
  final bool showCopyButton;

  const RecoveryPhraseGrid({required this.mnemonic, super.key, this.showCopyButton = true});

  List<String> get _words => mnemonic.split(' ');

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text('Recovery Phrase', style: Theme.of(context).textTheme.titleMedium)),
                if (showCopyButton)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      ServiceInjector().deviceClient.setClipboardText(mnemonic);
                      showFlushbar(
                        context,
                        message: 'Recovery phrase copied to clipboard.',
                        duration: const Duration(seconds: 3),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (_, int i) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    Text('${i + 1}.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text(_words[i], style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
