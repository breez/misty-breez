import 'package:flutter/material.dart';

class AddressWidgetPlaceholder extends StatelessWidget {
  const AddressWidgetPlaceholder({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            height: 188,
            width: 188,
            margin: const EdgeInsets.only(top: 112.0),
            padding: const EdgeInsets.all(8),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }
}
