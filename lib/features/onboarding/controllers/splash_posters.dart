import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/data/data_sources/movie_api.dart';

/// TMDB `poster_path` values, not URLs — the size bucket is chosen by the
/// `TmdbImage` that renders them, so it stays in one place app-wide.
const _fallbackPosters = <String>[
  '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg', // Fight Club
  '/q6y0Go1ts8k9NnbdQqFEJVvEpoF.jpg', // Shawshank Redemption
  '/9O7gLzmreU0nGkIB6K3BsJbzvNv.jpg', // The Godfather
  '/qJ2tW6WMUDux911r6m7haRef0WH.jpg', // The Dark Knight
  '/oXUWEc5i3wYyFnL1Ycu8ppxxPvs.jpg', // Pulp Fiction
  '/rPdtLWNsZmAtoZl9PK7S2wE3qiS.jpg', // Parasite
  '/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg', // Inception
  '/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg', // The Matrix
];

final splashPostersProvider = FutureProvider<List<String>>((ref) async {
  try {
    final response = await MovieAPI().popularMovies(page: 1);
    final paths =
        response.results
            .map((m) => m.posterPath)
            .whereType<String>()
            .where((p) => p.isNotEmpty)
            .take(20)
            .toList();
    return paths.isEmpty ? _fallbackPosters : paths;
  } catch (_) {
    return _fallbackPosters;
  }
});
