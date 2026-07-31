import 'dart:io';

import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/shared_widgets/tmdb_image.dart';

import 'fake_cache_manager.dart';
import 'fake_http_client.dart';

/// The cache manager installed by the most recent [setUpWidgetTests] call.
/// Exposed so a test can assert which TMDB URLs a widget asked for.
FakeCacheManager? currentFakeCacheManager;

/// Call in setUpAll() for widget tests that render TmdbImage, Image.network or
/// GoogleFonts.
void setUpWidgetTests() {
  HttpOverrides.global = FakeHttpOverrides();
  GoogleFonts.config.allowRuntimeFetching = false;
  // TmdbImage goes through cached_network_image, which bypasses HttpOverrides
  // and would otherwise hit the path_provider/sqflite platform channels.
  currentFakeCacheManager = FakeCacheManager();
  TmdbImageCache.debugCacheManagerOverride = currentFakeCacheManager;
}

/// Call in tearDownAll() to reset HttpOverrides.
void tearDownWidgetTests() {
  HttpOverrides.global = null;
  TmdbImageCache.debugCacheManagerOverride = null;
  currentFakeCacheManager = null;
}
