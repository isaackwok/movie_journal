import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/core/utils/tmdb_image_url.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/share/controllers/ticket_number.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/share/share_flow.dart';
import 'package:movie_journal/features/share/share_targets.dart';
import 'package:movie_journal/features/share/ticket_capture.dart';
import 'package:movie_journal/features/share/widgets/flippable_ticket.dart';
import 'package:movie_journal/features/share/widgets/share_options_sheet.dart';
import 'package:movie_journal/features/share/widgets/ticket_back.dart';
import 'package:movie_journal/features/share/widgets/ticket_front.dart';
import 'package:movie_journal/features/toast/custom_toast.dart';
import 'package:movie_journal/shared_widgets/circled_icon_button.dart';
import 'package:movie_journal/shared_widgets/tmdb_image.dart';

class ShareTicketScreen extends ConsumerStatefulWidget {
  final JournalState journal;
  final String? posterPath;
  final ShareTicketEntry entry;

  const ShareTicketScreen({
    super.key,
    required this.journal,
    this.posterPath,
    required this.entry,
  });

  @override
  ConsumerState<ShareTicketScreen> createState() => _ShareTicketScreenState();
}

class _ShareTicketScreenState extends ConsumerState<ShareTicketScreen> {
  final _repaintKey = GlobalKey();
  bool _saving = false;

  /// The ticket is rasterised through [_repaintKey], so it must never be built
  /// while the poster is still a placeholder — that placeholder would be baked
  /// into the saved PNG. Decoding the poster up front makes the first frame of
  /// the ticket already contain it.
  bool _posterReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Warm the per-movie detail cache; build() fetches on first read.
      ref.read(movieDetailControllerProvider(widget.journal.tmdbId));
      ref
          .read(movieImagesControllerProvider(widget.journal.tmdbId).notifier)
          .getMovieImages();
      _precachePoster();
    });
  }

  /// Warms Flutter's `imageCache` for the entry `TicketFront`'s [TmdbImage]
  /// resolves — `CachedNetworkImageProvider` equality is by URL, so the same
  /// path and size bucket is the same cache key.
  Future<void> _precachePoster() async {
    try {
      await precacheImage(
        tmdbImageProvider(
          widget.posterPath ?? widget.journal.moviePoster,
          TmdbImageSize.w780,
        ),
        context,
      );
    } catch (_) {
      // A poster that will never load must not strand the screen on its
      // spinner; TicketFront's errorWidget takes over from here.
    }
    if (mounted) setState(() => _posterReady = true);
  }

  void _showShareBottomSheet() {
    ShareOptionsSheet.show(
      context,
      thoughts: widget.journal.thoughts,
      onInstagramStory:
          () => shareTicketToInstagramStory(
            context,
            movieTitle: widget.journal.movieTitle,
            repaintKey: _repaintKey,
          ),
      onThreads: () => shareToThreads(context, journal: widget.journal),
      onOthers:
          () => shareTicketNatively(
            context,
            movieTitle: widget.journal.movieTitle,
            repaintKey: _repaintKey,
          ),
    );
  }

  Future<void> _saveImage() async {
    if (_saving) return;
    setState(() => _saving = true);
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    try {
      // Request gallery permission
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) {
            CustomToast.showError(context, 'Photo library access denied');
          }
          return;
        }
      }

      final bytes = await captureTicketAsBytes(
        _repaintKey,
        pixelRatio: pixelRatio,
      );
      if (bytes == null) return;

      await Gal.putImageBytes(bytes);
      unawaited(
        AnalyticsManager.logTicketSaved(movieTitle: widget.journal.movieTitle),
      );

      if (mounted) {
        CustomToast.showSuccess(context, 'Image saved to camera roll');
      }
    } catch (e) {
      debugPrint('Save image error: $e');
      if (mounted) {
        CustomToast.showError(context, 'Failed to save image');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _onClose() {
    closeShareFlow(context, widget.entry);
  }

  @override
  Widget build(BuildContext context) {
    final asyncMovie = ref.watch(
      movieDetailControllerProvider(widget.journal.tmdbId),
    );
    final asyncImages = ref.watch(
      movieImagesControllerProvider(widget.journal.tmdbId),
    );
    final journalsLoading = ref.watch(
      journalsControllerProvider.select((s) => s.isLoading),
    );

    final journal = widget.journal;
    final isLoading =
        asyncMovie.isLoading ||
        asyncImages.isLoading ||
        journalsLoading ||
        // Gate the ticket on the poster too: it is rasterised through a
        // RepaintBoundary, so building it with a placeholder in place would
        // bake that placeholder into the saved PNG.
        !_posterReady;

    // Extract movie details
    final movie = asyncMovie.hasValue ? asyncMovie.value : null;
    final director =
        movie?.credits.crew
            .where((e) => e.job == 'Director')
            .firstOrNull
            ?.name ??
        'Unknown';
    final cast =
        movie?.credits.cast.take(3).map((c) => c.name).join(', ') ?? '--';
    final releaseDate = movie?.releaseDate.split('-').join('. ') ?? '--';
    final year = movie?.year ?? '--';

    // Scene path: journal's first scene, or fallback to movie images
    final scenePath =
        journal.selectedScenes.isNotEmpty
            ? journal.selectedScenes.first.path
            : (asyncImages.hasValue
                ? asyncImages.value?.backdrops.firstOrNull?.filePath
                : null);

    final ticketNumber = ref.watch(ticketNumberProvider(journal.id));

    return ScreenViewTracker(
      screenName: 'ShareTicket',
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 56,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: CircledIconButton(
              icon: Icons.arrow_back_ios_new,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _onClose,
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: RepaintBoundary(
                              key: _repaintKey,
                              child: FlippableTicket(
                                hintOnMount: true,
                                front: TicketFront(
                                  posterPath:
                                      widget.posterPath ?? journal.moviePoster,
                                ),
                                back: TicketBack(
                                  movieTitle: journal.movieTitle,
                                  year: year,
                                  releaseDate: releaseDate,
                                  director: director,
                                  cast: cast,
                                  emotions: journal.emotions,
                                  scenePath: scenePath,
                                  createdAt: journal.createdAt,
                                  ticketNumber: ticketNumber,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      child: Row(
                        children: [
                          CircledIconButton(
                            icon: Icons.download,
                            onPressed: _saving ? null : _saveImage,
                            iconSize: 20,
                            size: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _showShareBottomSheet,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'AvenirNext',
                                ),
                              ),
                              child: const Text('Share'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
