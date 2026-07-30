import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/movie/controllers/search_movie_controller.dart';
import 'package:movie_journal/features/movie/data/models/brief_movie.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/search_movie/widgets/movie_result_list.dart';

import '../../../helpers/test_movie.dart';
import '../../../helpers/widget_test_setup.dart';

/// Serves a fixed state instead of hitting the TMDB repository.
class _FixedSearchMovieController extends SearchMovieController {
  _FixedSearchMovieController(this._state);
  final SearchMovieState _state;

  @override
  Future<SearchMovieState> build() async => _state;
}

void main() {
  setUpAll(() => setUpWidgetTests());
  tearDownAll(() => tearDownWidgetTests());

  // Image loads killed by a test's teardown get their *error* cached in the
  // global imageCache keyed by URL; the next test then synchronously resolves
  // to the poisoned entry and Image.network renders its unconstrained error
  // placeholder, overflowing the item Row. Start every test with a clean cache.
  setUp(() {
    imageCache.clear();
    imageCache.clearLiveImages();
  });

  final movies = [
    BriefMovie.fromJson(makeBriefMovieJson(id: 1, title: 'First Movie')),
    BriefMovie.fromJson(makeBriefMovieJson(id: 2, title: 'Second Movie')),
  ];

  Future<ScrollController> pumpList(
    WidgetTester tester,
    SearchMovieState state,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchMovieControllerProvider.overrideWith(
            () => _FixedSearchMovieController(state),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MovieResultList(scrollController: scrollController),
          ),
        ),
      ),
    );
    await tester.pump();
    return scrollController;
  }

  group('MovieResultList popular mode', () {
    // Regression test for ISA-9 bug 3: the header used to be rendered *in
    // place of* movies[0] with itemCount == movies.length, so the first
    // popular movie never appeared.
    testWidgets('renders the header AND every movie', (tester) async {
      await pumpList(
        tester,
        SearchMovieState(movies: movies, mode: SearchMovieMode.popular),
      );

      expect(find.text('People watched'), findsOneWidget);
      expect(find.byType(MovieResultItem), findsNWidgets(2));
      expect(find.textContaining('First Movie'), findsOneWidget);
      expect(find.textContaining('Second Movie'), findsOneWidget);
    });
  });

  group('MovieResultList search mode', () {
    testWidgets('renders no header and every movie', (tester) async {
      await pumpList(
        tester,
        SearchMovieState(
          movies: movies,
          query: 'movie',
          mode: SearchMovieMode.search,
        ),
      );

      expect(find.text('People watched'), findsNothing);
      expect(find.byType(MovieResultItem), findsNWidgets(2));
      expect(find.textContaining('First Movie'), findsOneWidget);
    });
  });
}
