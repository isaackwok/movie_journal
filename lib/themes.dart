import 'package:flutter/material.dart';

class Themes {
  static ThemeData dark = ThemeData(
    scaffoldBackgroundColor: const Color(0xFF161616),
    primaryColor: const Color(0xFFFCA311),
    fontFamily: 'AvenirNext',

    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.white,
      brightness: Brightness.dark,
      surface: const Color(0xFF161616),
    ),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFFFCA311),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF161616),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontFamily: 'AvenirNext',
        fontSize: 24,
      ),
    ),
  );

  static ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'AvenirNext',
  );
}
