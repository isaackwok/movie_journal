import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/core/utils/tmdb_image_url.dart';
import 'package:movie_journal/shared_widgets/tmdb_image.dart';
import 'package:movie_journal/themes.dart';

import '../helpers/widget_test_setup.dart';

void main() {
  setUpAll(setUpWidgetTests);
  tearDownAll(tearDownWidgetTests);

  setUp(() {
    imageCache.clear();
    imageCache.clearLiveImages();
    // A fresh fake per test: requestedUrls and the failAll/delay switches are
    // per-test state, and a leaked delay would hang the next test.
    setUpWidgetTests();
  });

  Future<void> pumpImage(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));

  group('url construction', () {
    testWidgets('requests the URL for the given size bucket', (tester) async {
      await pumpImage(
        tester,
        const SizedBox(
          width: 100,
          height: 100,
          child: TmdbImage(path: '/abc.jpg', size: TmdbImageSize.w342),
        ),
      );
      await tester.pumpAndSettle();

      expect(currentFakeCacheManager!.requestedUrls, [
        'https://image.tmdb.org/t/p/w342/abc.jpg',
      ]);
    });

    testWidgets('tolerates a path with no leading slash', (tester) async {
      await pumpImage(
        tester,
        const SizedBox(
          width: 100,
          height: 100,
          child: TmdbImage(path: 'abc.jpg', size: TmdbImageSize.w154),
        ),
      );
      await tester.pumpAndSettle();

      expect(currentFakeCacheManager!.requestedUrls, [
        'https://image.tmdb.org/t/p/w154/abc.jpg',
      ]);
    });

    test('tmdbImageProvider shares the widget cache manager', () {
      setUpWidgetTests();
      final provider =
          tmdbImageProvider('/abc.jpg', TmdbImageSize.w500)
              as CachedNetworkImageProvider;

      expect(provider.url, 'https://image.tmdb.org/t/p/w500/abc.jpg');
      expect(provider.cacheManager, same(currentFakeCacheManager));
    });
  });

  group('placeholder', () {
    testWidgets('default placeholder fills with the placeholder color', (
      tester,
    ) async {
      currentFakeCacheManager!.delay = const Duration(seconds: 1);

      await pumpImage(
        tester,
        const SizedBox(
          width: 100,
          height: 100,
          child: TmdbImage(path: '/abc.jpg', size: TmdbImageSize.w342),
        ),
      );
      await tester.pump();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TmdbImage),
          matching: find.byType(Container),
        ),
      );
      expect(container.color, DarkSurfaces.imagePlaceholder);

      // Let the withheld response land so no timer outlives the test.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('a supplied placeholder replaces the default', (tester) async {
      currentFakeCacheManager!.delay = const Duration(seconds: 1);

      await pumpImage(
        tester,
        const SizedBox(
          width: 100,
          height: 100,
          child: TmdbImage(
            path: '/abc.jpg',
            size: TmdbImageSize.w342,
            placeholder: Text('loading'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('loading'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });
  });

  group('error', () {
    testWidgets('a supplied errorWidget is shown on failure', (tester) async {
      currentFakeCacheManager!.failAll = true;

      await pumpImage(
        tester,
        const SizedBox(
          width: 100,
          height: 100,
          child: TmdbImage(
            path: '/abc.jpg',
            size: TmdbImageSize.w342,
            errorWidget: Text('broken'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('broken'), findsOneWidget);
    });

    testWidgets('the default error widget is bounded, not an overflow box', (
      tester,
    ) async {
      currentFakeCacheManager!.failAll = true;

      // The regression this guards: Flutter's built-in error placeholder is
      // unconstrained, so a failed load inside a tight parent used to surface
      // as a RenderFlex overflow rather than as a missing image.
      await pumpImage(
        tester,
        const SizedBox(
          width: 40,
          height: 40,
          child: TmdbImage(path: '/abc.jpg', size: TmdbImageSize.w342),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(TmdbImage)),
        const Size(40, 40),
      );
    });
  });
}
