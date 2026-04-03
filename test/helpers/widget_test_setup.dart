import 'dart:io';

import 'package:google_fonts/google_fonts.dart';

import 'fake_http_client.dart';

/// Call in setUpAll() for widget tests that render Image.network or GoogleFonts.
void setUpWidgetTests() {
  HttpOverrides.global = FakeHttpOverrides();
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// Call in tearDownAll() to reset HttpOverrides.
void tearDownWidgetTests() {
  HttpOverrides.global = null;
}
