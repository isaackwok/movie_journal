import 'package:flutter/material.dart';

const Color _darkSurface = Color(0xFF000000);
const Color _darkOnSurface = Colors.white;
const Color _darkPrimary = Color(0xFFA8DADD);
const Color _darkOnPrimary = Colors.black;
const String _defaultFontFamily = 'Inter';

/// Single source of truth for status accent colors (toast icons, etc.).
///
/// Context-free constants rather than a [ThemeExtension]: they are the same in
/// every theme, and consumers shouldn't need a [BuildContext] just to pick an
/// accent. Used as icon *background* colors; the inner glyph is always plain
/// black for contrast.
class StatusColors {
  StatusColors._();

  /// Success — the app primary ([_darkPrimary], `#A8DADD`).
  static const Color success = Color(0xFFA8DADD);
  static const Color error = Color(0xFFFF615D);
  static const Color warning = Color(0xFFFF9F1C);
}

/// The named dark-surface ramp.
///
/// These greys used to be re-hardcoded per widget and had started to drift
/// (six near-identical values). Pick the closest existing step; don't add a
/// new hex without adding it here first.
class DarkSurfaces {
  DarkSurfaces._();

  /// Dialog / toast / bordered-card background; also filled text fields.
  static const Color card = Color(0xFF151515);

  /// Bottom-sheet background (reviews sheet).
  static const Color sheet = Color(0xFF171717);

  /// iOS dark secondary-surface tone used by the selector sheets.
  static const Color sheetSecondary = Color(0xFF1C1C1E);

  /// Raised card sitting on a sheet (review cards, the "Add" card).
  static const Color raisedCard = Color(0xFF202020);

  /// Journal tile on the home grid.
  static const Color tile = Color(0xFF222222);

  /// Placeholder behind posters while the image loads.
  static const Color imagePlaceholder = Color(0xFF2C2C2E);
}

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
      primary: _darkPrimary,
      onPrimary: _darkOnPrimary,
      onSurface: _darkOnSurface,
    ),

    textSelectionTheme: const TextSelectionThemeData(cursorColor: _darkPrimary),

    appBarTheme: const AppBarTheme(
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
      leadingWidth: 40,
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
        foregroundColor: _darkPrimary,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          fontFamily: 'AvenirNext',
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
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
