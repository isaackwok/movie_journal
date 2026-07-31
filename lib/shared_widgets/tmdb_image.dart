import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:movie_journal/core/utils/tmdb_image_url.dart';
import 'package:movie_journal/themes.dart';

/// The disk cache every TMDB image in the app shares.
///
/// Flutter's built-in `imageCache` is memory-only and process-scoped, so a raw
/// `Image.network` re-downloads every poster on each cold start. TMDB paths are
/// content-addressed (`/abc123.jpg` never changes bytes), so a long-lived disk
/// cache is safe: there is no revalidation problem, only a size problem.
///
/// Hence the explicit bounds — the defaults are 30 days / 200 objects, which is
/// short for immutable art and unbounded enough to matter on a device:
/// [_stalePeriod] is long because the bytes cannot go stale, and
/// [_maxNrOfCacheObjects] is a hard ceiling. At the sizes this app requests
/// (w154–w780, roughly 40–160 KB each) 400 objects is ~20–60 MB worst case.
class TmdbImageCache {
  TmdbImageCache._();

  /// Distinct from the default `libCachedImageData` key so app imagery is
  /// evicted on its own schedule, not one shared with any other consumer.
  static const cacheKey = 'tmdbImageCache';
  static const _stalePeriod = Duration(days: 60);
  static const _maxNrOfCacheObjects = 400;

  static CacheManager? _default;

  /// Test seam. Widget tests must not reach `path_provider`/`sqflite` (both are
  /// platform channels with no implementation under `flutter_test`), so
  /// `setUpWidgetTests()` installs an in-memory fake here. Mirrors the
  /// `GoogleFonts.config.allowRuntimeFetching` idiom the suite already uses.
  @visibleForTesting
  static BaseCacheManager? debugCacheManagerOverride;

  static BaseCacheManager get instance =>
      debugCacheManagerOverride ??
      (_default ??= CacheManager(
        Config(
          cacheKey,
          stalePeriod: _stalePeriod,
          maxNrOfCacheObjects: _maxNrOfCacheObjects,
        ),
      ));
}

/// An [ImageProvider] for a TMDB image, backed by [TmdbImageCache].
///
/// Use this only where an `ImageProvider` is genuinely required — `precacheImage`
/// or palette extraction. Anything that renders should use [TmdbImage] so it
/// gets the placeholder and error handling too.
ImageProvider tmdbImageProvider(String path, TmdbImageSize size) =>
    CachedNetworkImageProvider(
      tmdbImageUrl(path, size),
      cacheManager: TmdbImageCache.instance,
    );

/// The single way this app renders a TMDB poster/backdrop.
///
/// Wraps `CachedNetworkImage` so the size bucket, the shared disk cache, and
/// the placeholder/error treatment live in one place rather than being spelled
/// out at each of the call sites.
class TmdbImage extends StatelessWidget {
  const TmdbImage({
    super.key,
    required this.path,
    required this.size,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 200),
  });

  /// A TMDB `poster_path` / `backdrop_path` / `file_path`, with or without its
  /// leading slash — see [tmdbImageUrl].
  final String path;
  final TmdbImageSize size;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  /// Shown while the bytes are being fetched. Defaults to a flat
  /// [DarkSurfaces.imagePlaceholder] fill.
  ///
  /// It must be able to size itself wherever the parent gives unbounded
  /// constraints, because it stands in for an image whose intrinsic size is not
  /// known yet (see `MoviePreviewScreen`, which renders the poster at its
  /// natural aspect ratio inside a scroll view).
  final Widget? placeholder;

  /// Shown when the fetch fails. Defaults to the same flat fill as
  /// [placeholder], which — unlike Flutter's default error box — is bounded and
  /// therefore cannot overflow its parent.
  final Widget? errorWidget;

  /// Zero at capture sites: `ShareTicketScreen` rasterises the ticket through a
  /// `RepaintBoundary`, and a fade still in flight would be baked into the PNG.
  final Duration fadeInDuration;

  Widget _fallback() => Container(
    width: width,
    height: height,
    color: DarkSurfaces.imagePlaceholder,
  );

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: tmdbImageUrl(path, size),
      cacheManager: TmdbImageCache.instance,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fadeInDuration: fadeInDuration,
      // The placeholder is a flat fill, so fading it in reads as a flicker.
      placeholderFadeInDuration: Duration.zero,
      placeholder: (context, url) => placeholder ?? _fallback(),
      errorWidget: (context, url, error) => errorWidget ?? _fallback(),
    );
  }
}
