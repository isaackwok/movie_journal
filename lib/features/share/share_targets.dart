import 'dart:async';
import 'dart:io';

import 'package:appinio_social_share/appinio_social_share.dart';
import 'package:flutter/material.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/share/ticket_capture.dart';
import 'package:movie_journal/features/toast/custom_toast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _facebookAppId = '1453372696513556';

/// Shares the captured ticket as an Instagram Story sticker.
Future<void> shareTicketToInstagramStory(
  BuildContext context, {
  required String movieTitle,
  required GlobalKey repaintKey,
}) async {
  final pixelRatio = MediaQuery.of(context).devicePixelRatio;
  try {
    final file = await captureTicketToFile(
      repaintKey,
      'movie_ticket_story.png',
      pixelRatio: pixelRatio,
    );
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
    unawaited(
      AnalyticsManager.logJournalShared(
        movieTitle: movieTitle,
        shareMethod: 'instagram_story',
      ),
    );
  } catch (e) {
    debugPrint('Instagram Story share error: $e');
    if (context.mounted) {
      CustomToast.showError(
        context,
        'Could not open Instagram. Is it installed?',
      );
    }
  }
}

/// Shares the journal's text via the Threads web intent.
Future<void> shareToThreads(
  BuildContext context, {
  required JournalState journal,
}) async {
  try {
    final text = _composeThreadsText(journal);
    final uri = Uri.parse(
      'https://www.threads.net/intent/post?text=${Uri.encodeComponent(text)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      unawaited(
        AnalyticsManager.logJournalShared(
          movieTitle: journal.movieTitle,
          shareMethod: 'threads',
        ),
      );
    } else {
      if (context.mounted) {
        CustomToast.showError(
          context,
          'Could not open Threads. Is it installed?',
        );
      }
    }
  } catch (e) {
    debugPrint('Threads share error: $e');
    if (context.mounted) {
      CustomToast.showError(context, 'Could not open Threads');
    }
  }
}

/// Compose the text to share on Threads.
/// TODO: Implement your preferred text format (~5-10 lines).
String _composeThreadsText(JournalState journal) {
  // Available data:
  //   journal.movieTitle  — e.g. "Fight Club"
  //   journal.thoughts    — the user's written thoughts
  //   journal.emotions    — List<Emotion> selected by user
  //   journal.createdAt   — DateTime when journal was created
  return journal.thoughts;
}

/// Shares the captured ticket through the OS share sheet.
Future<void> shareTicketNatively(
  BuildContext context, {
  required String movieTitle,
  required GlobalKey repaintKey,
}) async {
  final pixelRatio = MediaQuery.of(context).devicePixelRatio;
  try {
    final file = await captureTicketToFile(
      repaintKey,
      'movie_ticket_share.png',
      pixelRatio: pixelRatio,
    );
    if (file == null) return;

    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    unawaited(
      AnalyticsManager.logJournalShared(
        movieTitle: movieTitle,
        shareMethod: 'native',
      ),
    );
  } catch (e) {
    debugPrint('Share error: $e');
  }
}
