import 'package:flutter/material.dart';
import 'package:misty_breez/theme/theme.dart';

class FieldTextStyle {
  FieldTextStyle._();

  static TextStyle textStyle = TextStyle(
    color: BreezColors.white[500],
    fontSize: 18.0,
    letterSpacing: 0.15,
    height: 1.234,
  );
  static TextStyle labelStyle = TextStyle(color: BreezColors.white[200], letterSpacing: 0.4);
}

const TextStyle balanceAmountTextStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w600,
  height: 1.56,
  fontFamily: 'IBMPlexSans',
);
const TextStyle balanceCurrencyTextStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w600,
  height: 1.52,
  fontFamily: 'IBMPlexSans',
);
const TextStyle balanceFiatConversionTextStyle = TextStyle(
  fontSize: 16,
  letterSpacing: 0.2,
  fontWeight: FontWeight.w500,
  height: 1.24,
  fontFamily: 'IBMPlexSans',
);
final TextStyle? toolbarTextStyle = const TextTheme(
  titleLarge: TextStyle(color: Colors.white, fontSize: 18.0, letterSpacing: 0.22),
).bodyMedium;
final TextStyle? titleTextStyle = const TextTheme(
  titleLarge: TextStyle(color: Colors.white, fontSize: 18.0, letterSpacing: 0.22),
).titleLarge;
const TextStyle drawerItemTextStyle = TextStyle(height: 1.2, letterSpacing: 0.25, fontSize: 14.3);
const TextStyle bottomAppBarBtnStyle = TextStyle(
  color: Colors.white,
  fontSize: 13.5,
  letterSpacing: 1.2,
  fontWeight: FontWeight.w600,
  height: 1.24,
  fontFamily: 'IBMPlexSans',
);
const TextStyle bottomSheetTextStyle = TextStyle(
  fontFamily: 'IBMPlexSans',
  fontSize: 15,
  letterSpacing: 1.2,
  fontWeight: FontWeight.w400,
  height: 1.30,
);
final TextStyle bottomSheetMenuItemStyle = TextStyle(
  color: BreezColors.white[400],
  fontSize: 14.3,
  letterSpacing: 0.55,
);
final TextStyle blueLinkStyle = TextStyle(color: BreezColors.blue[500], fontSize: 16.0, height: 1.5);
final TextStyle textStyle = TextStyle(color: BreezColors.white[300], fontSize: 16.0);

const TextStyle paymentLimitInformationTextStyle = TextStyle(
  color: Colors.white54,
  fontSize: 14.0,
  height: 1.182,
  fontWeight: FontWeight.w400,
);
const TextStyle navigationDrawerHandleStyle = TextStyle(
  fontSize: 16.0,
  letterSpacing: 0.2,
  color: Color.fromRGBO(255, 255, 255, 0.6),
);
const TextStyle validatorStyle = TextStyle(color: Color(0xFFe3b42f), fontSize: 12.0, height: 1.25);
final TextStyle welcomeTextStyle = TextStyle(color: BreezColors.white[500], fontSize: 16.0, height: 1.1);
final TextStyle buttonStyle = TextStyle(color: BreezColors.blue[500], fontSize: 14.3, letterSpacing: 1.25);
final TextStyle whiteButtonStyle = TextStyle(
  color: BreezColors.white[500],
  fontSize: 14.3,
  letterSpacing: 1.25,
);
final TextStyle cancelButtonStyle = TextStyle(
  color: BreezColors.red[600],
  letterSpacing: 1.25,
  height: 1.16,
  fontSize: 14.0,
  fontWeight: FontWeight.w500,
  fontFamily: 'IBMPlexSans',
);
final TextStyle restoreLinkStyle = TextStyle(
  color: BreezColors.white[300],
  fontSize: 12.0,
  letterSpacing: 0.4,
  height: 1.2,
  decoration: TextDecoration.underline,
);
final TextStyle snackBarStyle = TextStyle(
  color: BreezColors.white[500],
  fontSize: 14.0,
  letterSpacing: 0.25,
  height: 1.2,
);
final TextStyle fiatConversionTitleStyle = TextStyle(
  color: BreezColors.white[500],
  fontSize: 16.3,
  letterSpacing: 0.25,
  height: 1.2,
);
final TextStyle fiatConversionDescriptionStyle = TextStyle(color: BreezColors.white[200], fontSize: 14.3);
final Color snackBarBackgroundColor = BreezColors.blue[300]!;
final Color sessionAvatarBackgroundColor = BreezColors.white[500]!;
const Color themeSwitchBgColor = Color.fromRGBO(229, 238, 251, 0.09);
final Color circularLoaderColor = BreezColors.blue[200]!.withValues(alpha: .7);
const Color warningBoxColor = Color.fromRGBO(251, 233, 148, 0.1);
final BorderSide greyBorderSide = BorderSide(color: BreezColors.grey[500]!);
final TextStyle mnemonicSeedTextStyle = TextStyle(
  color: BreezColors.white[400],
  fontSize: 16.4,
  letterSpacing: 0.73,
  height: 1.25,
);
final TextStyle mnemonicSeedInformationTextStyle = TextStyle(
  color: BreezColors.white[500],
  fontSize: 14.3,
  letterSpacing: 0.4,
  height: 1.16,
);
final TextStyle mnemonicSeedConfirmationTextStyle = TextStyle(
  color: BreezColors.white[500],
  fontSize: 14.3,
  letterSpacing: 1.25,
  height: 1.16,
  fontWeight: FontWeight.w500,
  fontFamily: 'IBMPlexSans',
);
const TextStyle autoCompleteStyle = TextStyle(color: Colors.black, fontSize: 14.0);
final TextStyle smallTextStyle = TextStyle(
  color: BreezColors.white[500],
  fontSize: 10.0,
  letterSpacing: 0.09,
);

const TextStyle warningStyle = TextStyle(color: Color(0xffffe685), fontSize: 16.0);

const TextStyle counterTextStyle = TextStyle(
  color: Colors.white54,
  fontSize: 14.0,
  height: 1.182,
  fontWeight: FontWeight.w400,
);

final TextStyle focusedCounterTextStyle = TextStyle(
  color: BreezColors.white[500],
  fontSize: 14.0,
  height: 1.182,
  fontWeight: FontWeight.w400,
);

extension ThemeExtensions on ThemeData {
  bool get isLightTheme => primaryColor == breezLightTheme.primaryColor;

  DatePickerThemeData get calendarTheme => isLightTheme ? calendarLightTheme : calendarDarkTheme;

  CustomData get customData => isLightTheme ? blueThemeCustomData : darkThemeCustomData;

  Color get warningBoxBorderColor =>
      isLightTheme ? const Color.fromRGBO(250, 239, 188, 0.6) : const Color.fromRGBO(227, 180, 47, 0.6);

  Color get bubblePaintColor => isLightTheme
      ? const Color(0xFF0085fb).withValues(alpha: .1)
      : const Color(0xff4D88EC).withValues(alpha: .1);

  Color get lightThemeSwitchIconColor => isLightTheme ? Colors.white : Colors.white30;

  Color get darkThemeSwitchIconColor => isLightTheme ? Colors.white30 : Colors.white;

  TextStyle get paymentItemTitleTextStyle => isLightTheme
      ? const TextStyle(
          color: Colors.black,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          height: 1.2,
          letterSpacing: 0.25,
        )
      : const TextStyle(
          color: Colors.white,
          fontSize: 12.25,
          fontWeight: FontWeight.w400,
          height: 1.2,
          letterSpacing: 0.25,
        );

  TextStyle get paymentItemAmountTextStyle => isLightTheme
      ? const TextStyle(
          color: Colors.black,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          height: 1.2,
          letterSpacing: 0.5,
        )
      : const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          height: 1.28,
          letterSpacing: 0.5,
        );

  TextStyle get paymentItemFeeTextStyle => isLightTheme
      ? const TextStyle(
          color: Color(0xb3303234),
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          height: 1.16,
          letterSpacing: 0.39,
        )
      : TextStyle(
          color: Colors.white.withValues(alpha: .7),
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          height: 1.16,
          letterSpacing: 0.39,
        );

  TextStyle get paymentItemSubtitleTextStyle => isLightTheme
      ? const TextStyle(
          color: Color(0xb3303234),
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          height: 1.16,
          letterSpacing: 0.39,
        )
      : TextStyle(
          color: Colors.white.withValues(alpha: .7),
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          height: 1.16,
          letterSpacing: 0.39,
        );

  TextStyle get errorTextStyle =>
      TextStyle(color: colorScheme.error, fontSize: 10.5, fontWeight: FontWeight.w400, height: 1.16);
}
