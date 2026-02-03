import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/share/widgets/flippable_ticket.dart';
import 'package:movie_journal/features/share/widgets/ticket_back.dart';
import 'package:movie_journal/features/share/widgets/ticket_front.dart';
import 'package:movie_journal/features/toast/custom_toast.dart';
import 'package:movie_journal/shared_widgets/circled_icon_button.dart';

class ShareTicketScreen extends ConsumerStatefulWidget {
  final JournalState journal;

  const ShareTicketScreen({super.key, required this.journal});

  @override
  ConsumerState<ShareTicketScreen> createState() => _ShareTicketScreenState();
}

class _ShareTicketScreenState extends ConsumerState<ShareTicketScreen> {
  final _repaintKey = GlobalKey();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(movieDetailControllerProvider.notifier)
          .fetchMovieDetails(widget.journal.tmdbId);
      ref
          .read(movieImagesControllerProvider.notifier)
          .getMovieImages(id: widget.journal.tmdbId);
    });
  }

  Future<void> _saveImage() async {
    if (_saving) return;
    setState(() => _saving = true);
    CustomToast.init(context);

    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    try {
      // Request gallery permission
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) {
            CustomToast.showError('Photo library access denied');
          }
          return;
        }
      }

      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      await Gal.putImageBytes(byteData.buffer.asUint8List());

      if (mounted) {
        CustomToast.showSuccess(context, 'Image saved to camera roll');
      }
    } catch (e) {
      debugPrint('Save image error: $e');
      if (mounted) {
        CustomToast.showError('Failed to save image');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncMovie = ref.watch(movieDetailControllerProvider);
    final asyncImages = ref.watch(movieImagesControllerProvider);
    final asyncJournals = ref.watch(journalsControllerProvider);

    final journal = widget.journal;

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

    // Ticket number from total journal count
    final ticketNumber =
        asyncJournals.hasValue
            ? (asyncJournals.value?.journals.length ?? 0)
            : 0;

    return Scaffold(
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
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: () {
                // Share action placeholder for future implementation
              },
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                overlayColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.primary,
                ),
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                side: WidgetStateProperty.all(
                  BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1,
                  ),
                ),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              child: const Text('Share'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Flippable ticket
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: FlippableTicket(
                      front: TicketFront(posterPath: journal.moviePoster),
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

          // Save Image button
          Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: GestureDetector(
              onTap: _saving ? null : _saveImage,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.download,
                    color: _saving ? Colors.white38 : Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Save Image',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'AvenirNext',
                      color: _saving ? Colors.white38 : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
