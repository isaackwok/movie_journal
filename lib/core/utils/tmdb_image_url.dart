/// The TMDB image widths the app actually uses — a subset of the sizes the
/// TMDB configuration endpoint offers.
enum TmdbImageSize { w154, w342, w500, w780, original }

/// Builds a TMDB image URL from a TMDB `poster_path` / `backdrop_path` /
/// `file_path` value and a size bucket.
///
/// TMDB paths come with a leading slash; a missing one is tolerated so call
/// sites never produce a `w154//x.jpg`-style double slash.
String tmdbImageUrl(String path, TmdbImageSize size) {
  final slash = path.startsWith('/') ? '' : '/';
  return 'https://image.tmdb.org/t/p/${size.name}$slash$path';
}
