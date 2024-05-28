import 'dart:math';

import 'package:l_breez/widgets/preview/preview.dart';
import 'package:flutter/material.dart';

class DigitMaskedWidget extends StatelessWidget {
  final double size;
  final bool filled;
  final Color filledColor;
  final Color unfilledColor;

  const DigitMaskedWidget({
    super.key,
    this.size = 32,
    this.filled = false,
    this.filledColor = Colors.white,
    this.unfilledColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(top: 24.0),
          margin: const EdgeInsets.only(bottom: 0),
          curve: filled ? Curves.decelerate : Curves.easeIn,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: unfilledColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: filledColor,
              width: 2.0,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(top: 24.0),
          margin: const EdgeInsets.only(bottom: 0),
          curve: filled ? Curves.decelerate : Curves.easeIn,
          alignment: Alignment.center,
          width: filled ? size : 0,
          height: filled ? size : 0,
          decoration: BoxDecoration(
            color: filledColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: filled ? filledColor : unfilledColor,
              width: 2.0,
            ),
          ),
        ),
      ],
    );
  }
}

// Preview

class DigitMaskedWidgetPreview extends StatefulWidget {
  const DigitMaskedWidgetPreview({
    super.key,
  });

  @override
  State<DigitMaskedWidgetPreview> createState() => _DigitMaskedWidgetPreviewState();
}

class _DigitMaskedWidgetPreviewState extends State<DigitMaskedWidgetPreview> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Preview(
      [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            6,
            (index) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: DigitMaskedWidget(
                filled: count > index,
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            6,
            (index) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: DigitMaskedWidget(
                filled: count > index,
                filledColor: Colors.red,
                unfilledColor: Colors.blue,
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  count = min(count + 1, 6);
                });
              },
              child: const Text("Fill"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  count = max(0, count - 1);
                });
              },
              child: const Text("Clear"),
            ),
          ],
        ),
      ],
    );
  }
}

void main() {
  runApp(const DigitMaskedWidgetPreview());
}
