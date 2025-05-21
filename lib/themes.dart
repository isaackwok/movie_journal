import 'package:flutter/material.dart';

const Color _darkSurface = Color(0xFF161616);
const Color _darkOnSurface = Colors.white;
const Color _darkPrimary = Color(0xFFFCA311);
const Color _darkOnPrimary = Colors.black;

class Themes {
  static ThemeData dark = ThemeData(
    scaffoldBackgroundColor: _darkSurface,
    primaryColor: _darkPrimary,
    fontFamily: 'AvenirNext',

    colorScheme: ColorScheme.fromSeed(
      seedColor: _darkOnSurface,
      brightness: Brightness.dark,
      surface: _darkSurface,
    ),

    textSelectionTheme: const TextSelectionThemeData(cursorColor: _darkPrimary),

    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: _darkSurface,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 24,
        color: _darkOnSurface,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: _darkPrimary,
        foregroundColor: _darkOnPrimary,
        textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
