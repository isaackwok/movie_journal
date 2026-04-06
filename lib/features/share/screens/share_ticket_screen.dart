import 'dart:io';
import 'dart:ui' as ui;

import 'package:appinio_social_share/appinio_social_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/share/widgets/flippable_ticket.dart';
import 'package:movie_journal/features/share/widgets/ticket_back.dart';
import 'package:movie_journal/features/share/widgets/ticket_front.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/toast/custom_toast.dart';
import 'package:movie_journal/shared_widgets/circled_icon_button.dart';

class ShareTicketScreen extends ConsumerStatefulWidget {
  final JournalState journal;
  final String? posterPath;

  const ShareTicketScreen({super.key, required this.journal, this.posterPath});

  @override
  ConsumerState<ShareTicketScreen> createState() => _ShareTicketScreenState();
}

class _ShareTicketScreenState extends ConsumerState<ShareTicketScreen> {
  static const _facebookAppId = '1453372696513556';

  final _repaintKey = GlobalKey();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.logScreenView('ShareTicket');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(movieDetailControllerProvider.notifier)
          .fetchMovieDetails(widget.journal.tmdbId);
      ref
          .read(movieImagesControllerProvider.notifier)
          .getMovieImages(id: widget.journal.tmdbId);
    });
  }

  void _showShareBottomSheet() {
    final thoughts = widget.journal.thoughts;
    CustomToast.init(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (thoughts.isNotEmpty) ...[
                    const Text(
                      'Copy text to post on Social',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              thoughts,
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: thoughts));
                              CustomToast.showSuccess(
                                sheetContext,
                                'Copied to clipboard',
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.copy,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Copy Text',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontFamily: 'AvenirNext',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Share Option',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Instagram Story
                      GestureDetector(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _shareToInstagramStory();
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/instagram_logo.png',
                                  width: 48,
                                  height: 48,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Story',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'AvenirNext',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Threads
                      GestureDetector(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _shareToThreads();
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/threads_logo.png',
                                  width: 48,
                                  height: 48,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Threads',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'AvenirNext',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Others
                      GestureDetector(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _shareImageNatively();
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.more_horiz,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Others',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'AvenirNext',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List?> _captureTicketAsBytes() async {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final boundary =
        _repaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return byteData.buffer.asUint8List();
  }

  Future<File?> _captureTicketToFile(String filename) async {
    final bytes = await _captureTicketAsBytes();
    if (bytes == null) return null;
    final file = File('${Directory.systemTemp.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _shareToInstagramStory() async {
    CustomToast.init(context);

    try {
      final file = await _captureTicketToFile('movie_ticket_story.png');
      if (file == null) return;

      final socialShare = AppinioSocialShare();
      if (Platform.isIOS) {
        await socialShare.iOS.shareToInstagramStory(
          _facebookAppId,
          stickerImage: file.path,
        );
      } else if (Platform.isAndroid) {
        await socialShare.android.shareToInstagramStory(
          _facebookAppId,
          stickerImage: file.path,
        );
      }
      AnalyticsManager.logJournalShared(
        movieTitle: widget.journal.movieTitle,
        shareMethod: 'instagram_story',
      );
    } catch (e) {
      debugPrint('Instagram Story share error: $e');
      if (mounted) {
        CustomToast.showError('Could not open Instagram. Is it installed?');
      }
    }
  }

  Future<void> _shareToThreads() async {
    CustomToast.init(context);

    try {
      final text = _composeThreadsText();
      final uri = Uri.parse(
        'https://www.threads.net/intent/post?text=${Uri.encodeComponent(text)}',
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        AnalyticsManager.logJournalShared(
          movieTitle: widget.journal.movieTitle,
          shareMethod: 'threads',
        );
      } else {
        if (mounted) {
          CustomToast.showError('Could not open Threads. Is it installed?');
        }
      }
    } catch (e) {
      debugPrint('Threads share error: $e');
      if (mounted) {
        CustomToast.showError('Could not open Threads');
      }
    }
  }

  /// Compose the text to share on Threads.
  /// TODO: Implement your preferred text format (~5-10 lines).
  String _composeThreadsText() {
    final journal = widget.journal;
    // Available data:
    //   journal.movieTitle  — e.g. "Fight Club"
    //   journal.thoughts    — the user's written thoughts
    //   journal.emotions    — List<Emotion> selected by user
    //   journal.createdAt   — DateTime when journal was created
    return journal.thoughts;
  }

  Future<void> _shareImageNatively() async {
    try {
      final file = await _captureTicketToFile('movie_ticket_share.png');
      if (file == null) return;

      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      AnalyticsManager.logJournalShared(
        movieTitle: widget.journal.movieTitle,
        shareMethod: 'native',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  Future<void> _saveImage() async {
    if (_saving) return;
    setState(() => _saving = true);
    CustomToast.init(context);

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

      final bytes = await _captureTicketAsBytes();
      if (bytes == null) return;

      await Gal.putImageBytes(bytes);
      AnalyticsManager.logTicketSaved(movieTitle: widget.journal.movieTitle);

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

  int _computeTicketNumber(
    AsyncValue<JournalsState> asyncJournals,
    String journalId,
  ) {
    if (!asyncJournals.hasValue) return 0;
    final journals = asyncJournals.value?.journals;
    if (journals == null || journals.isEmpty) return 0;
    final sorted = [...journals]..sort(
      (a, b) => a.createdAt.dateTime.compareTo(b.createdAt.dateTime),
    );
    final index = sorted.indexWhere((j) => j.id == journalId);
    return index == -1 ? 0 : index + 1;
  }

  @override
  Widget build(BuildContext context) {
    final asyncMovie = ref.watch(movieDetailControllerProvider);
    final asyncImages = ref.watch(movieImagesControllerProvider);
    final asyncJournals = ref.watch(journalsControllerProvider);

    final journal = widget.journal;
    final isLoading =
        asyncMovie.isLoading || asyncImages.isLoading || asyncJournals.isLoading;

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

    final ticketNumber = _computeTicketNumber(asyncJournals, journal.id);

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
              onPressed: isLoading ? null : _showShareBottomSheet,
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
                    color:
                        isLoading
                            ? Colors.white24
                            : Theme.of(context).colorScheme.primary,
                    width: 1,
                  ),
                ),
                foregroundColor: WidgetStateProperty.all(
                  isLoading ? Colors.white38 : Colors.white,
                ),
              ),
              child: const Text('Share'),
            ),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Flippable ticket
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tap to Flip label
                            Text(
                              'Tap to Flip',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'AvenirNext',
                                color: Colors.white.withAlpha(153),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Flexible(
                              child: AspectRatio(
                                aspectRatio: 2 / 3,
                                child: RepaintBoundary(
                            key: _repaintKey,
                            child: FlippableTicket(
                              hintOnMount: true,
                              front: TicketFront(
                                posterPath: widget.posterPath ?? journal.moviePoster,
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
                            // Counterbalance text + gap so ticket stays centered
                            const SizedBox(height: 30 + 20),
                          ],
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
