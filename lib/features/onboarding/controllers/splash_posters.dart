import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/data/data_sources/movie_api.dart';

const _imageBaseUrl = 'https://image.tmdb.org/t/p/w342';

const _fallbackPosters = <String>[
  '$_imageBaseUrl/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg', // Fight Club
  '$_imageBaseUrl/q6y0Go1ts8k9NnbdQqFEJVvEpoF.jpg', // Shawshank Redemption
  '$_imageBaseUrl/9O7gLzmreU0nGkIB6K3BsJbzvNv.jpg', // The Godfather
  '$_imageBaseUrl/qJ2tW6WMUDux911r6m7haRef0WH.jpg', // The Dark Knight
  '$_imageBaseUrl/oXUWEc5i3wYyFnL1Ycu8ppxxPvs.jpg', // Pulp Fiction
  '$_imageBaseUrl/rPdtLWNsZmAtoZl9PK7S2wE3qiS.jpg', // Parasite
  '$_imageBaseUrl/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg', // Inception
  '$_imageBaseUrl/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg', // The Matrix
];

final splashPostersProvider = FutureProvider<List<String>>((ref) async {
  try {
    final response = await MovieAPI().popularMovies(page: 1);
    final urls = response.results
        .where((m) => m.posterPath != null && m.posterPath!.isNotEmpty)
        .map((m) => '$_imageBaseUrl${m.posterPath}')
        .take(20)
        .toList();
    return urls.isEmpty ? _fallbackPosters : urls;
  } catch (_) {
    return _fallbackPosters;
  }
});
