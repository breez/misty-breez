import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/preview/fill_view_port_column_scroll_view.dart';

class Preview extends StatefulWidget {
  final List<Widget> children;

  const Preview(
    this.children, {
    super.key,
  });

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final int cols = constraints.maxWidth ~/ 8;
                  final int rows = constraints.maxHeight ~/ 8;
                  return GridView.builder(
                    itemCount: cols * rows + cols,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final bool oddRow = (index ~/ cols).isOdd;
                      final bool oddCol = (index % cols).isOdd;
                      return Container(
                        color: oddRow == oddCol ? Colors.grey.withAlpha(128) : Colors.blueGrey.withAlpha(128),
                      );
                    },
                  );
                },
              ),
              Container(
                height: 48.0,
                color: theme?.appBarTheme.backgroundColor ?? Colors.white60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    const Text('Theme:'),
                    TextButton(
                      onPressed: () => _changeTheme(null),
                      child: const Text('None'),
                    ),
                    TextButton(
                      onPressed: () => _changeTheme(breezLightTheme),
                      child: const Text('Light'),
                    ),
                    TextButton(
                      onPressed: () => _changeTheme(breezDarkTheme),
                      child: const Text('Dark'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 48.0),
                child: FillViewPortColumnScrollView(
                  children: widget.children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeTheme(ThemeData? theme) {
    setState(() {
      this.theme = theme;
    });
  }
}
