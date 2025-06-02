import 'dart:ui';

class BreezColors {
  BreezColors._(); // this basically makes it so you can instantiate this class

  static const Map<int, Color> blue = <int, Color>{
    200: Color.fromRGBO(0, 117, 255, 1.0),
    300: Color.fromRGBO(51, 69, 96, 1.0),
    500: Color.fromRGBO(5, 93, 235, 1.0),
    900: Color.fromRGBO(19, 85, 191, 1.0),
  };

  static const Map<int, Color> white = <int, Color>{
    200: Color(0x99ffffff),
    300: Color(0xccffffff),
    400: Color(0xdeffffff),
    500: Color(0xFFffffff),
  };

  static const Map<int, Color> grey = <int, Color>{500: Color(0xFF4d5d75), 600: Color(0xFF334560)};

  static const Map<int, Color> red = <int, Color>{600: Color(0xFFff1d24)};
}
