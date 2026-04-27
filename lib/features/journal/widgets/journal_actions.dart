import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/journal/screens/journaling.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/share/screens/share_ticket_screen.dart';
import 'package:movie_journal/features/share/screens/ticket_poster_picker_screen.dart';
import 'package:movie_journal/features/toast/custom_toast.dart';
import 'package:movie_journal/shared_widgets/confirmation_dialog.dart';

void editJournal(BuildContext context, WidgetRef ref, JournalState journal) {
  ref.read(journalControllerProvider.notifier).loadJournal(journal);
  ref
      .read(movieImagesControllerProvider.notifier)
      .getMovieImages(id: journal.tmdbId);
  ref
      .read(movieDetailControllerProvider.notifier)
      .fetchMovieDetails(journal.tmdbId);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => JournalingScreen(
        movieTitle: journal.movieTitle,
        moviePosterUrl: journal.moviePoster,
        editJournalId: journal.id,
      ),
    ),
  );
}

void shareJournal(BuildContext context, JournalState journal) {
  Navigator.of(context).push(
    MaterialPageRoute(
      settings: const RouteSettings(name: kShareFlowRouteName),
      builder: (_) => TicketPosterPickerScreen(
        journal: journal,
        entry: ShareTicketEntry.journalContent,
      ),
    ),
  );
}

Future<bool> confirmDeleteJournal(BuildContext context) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmationDialog(
      title: 'Delete Journal',
      description: 'Are you sure you want to delete this journal?',
      cancelText: 'Cancel',
      confirmText: 'Delete',
      onCancel: () => Navigator.pop(context, false),
      onConfirm: () => Navigator.pop(context, true),
    ),
  );
  return shouldDelete == true;
}

Future<void> deleteJournal(
  BuildContext context,
  WidgetRef ref,
  String journalId,
) async {
  try {
    CustomToast.init(context);
    await ref.read(journalsControllerProvider.notifier).removeJournal(journalId);

    if (!context.mounted) return;
    CustomToast.showSuccess(context, 'Journal deleted successfully');
  } catch (e) {
    if (!context.mounted) return;
    CustomToast.init(context);
    CustomToast.showError('Failed to delete journal');
  }
}
