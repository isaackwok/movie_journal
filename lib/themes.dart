import 'package:flutter/material.dart';

const Color _darkSurface = Color(0xFF000000);
const Color _darkOnSurface = Colors.white;
const Color _darkPrimary = Color(0xFFA8DADD);
const Color _darkOnPrimary = Colors.black;
const String _defaultFontFamily = 'Inter';

class Themes {
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: _darkSurface,
    primaryColor: _darkPrimary,
    fontFamily: _defaultFontFamily,

    colorScheme: ColorScheme.fromSeed(
      seedColor: _darkOnSurface,
      brightness: Brightness.dark,
      surface: _darkSurface,
    ),

    textSelectionTheme: const TextSelectionThemeData(cursorColor: _darkPrimary),

    appBarTheme: AppBarTheme(
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      backgroundColor: _darkSurface,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 22,
        height: 1.25,
        color: _darkOnSurface,
        fontFamily: 'AvenirNext',
      ),
    ),

    bottomAppBarTheme: const BottomAppBarThemeData(
      color: _darkSurface,
      surfaceTintColor: Colors.transparent,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _darkPrimary,
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: _darkPrimary,
        foregroundColor: _darkOnPrimary,
        textStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          fontFamily: 'AvenirNext',
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
  );

  static ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: _defaultFontFamily,
  );
}
