import 'package:flutter/material.dart';

/// Extracts a color scheme from an image provider based on dominant colors.
///
/// Returns a [ColorScheme] generated from the provided image, using Flutter's
/// Material 3 dynamic color extraction algorithm. The color scheme will be
/// harmonized with the theme's brightness.
///
/// Parameters:
/// - [imageProvider]: The image source to extract colors from
/// - [brightness]: The brightness mode for the color scheme (light or dark)
///
/// Returns a [Future<ColorScheme>] that resolves with the extracted color scheme.
/// May throw an exception if color extraction fails.
Future<ColorScheme> getColors(
  ImageProvider imageProvider,
  Brightness brightness,
) async {
  return await ColorScheme.fromImageProvider(
    provider: imageProvider,
    brightness: brightness,
  );
}
