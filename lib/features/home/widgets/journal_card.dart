import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/screens/journal_content.dart';
import 'package:movie_journal/features/journal/widgets/journal_actions.dart';

class JournalCard extends ConsumerStatefulWidget {
  final JournalState journal;
  const JournalCard({super.key, required this.journal});

  @override
  ConsumerState<JournalCard> createState() => _JournalCardState();
}

class _JournalCardState extends ConsumerState<JournalCard> {
  void _openJournal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalContent(journalId: widget.journal.id),
      ),
    );
  }

  Future<void> _dismissMenuThen(
    BuildContext menuContext,
    Future<void> Function() action,
  ) async {
    Navigator.of(menuContext, rootNavigator: true).pop();
    // Let the context menu overlay finish dismissing before the next
    // navigation/dialog pushes, so the back stack is clean.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await action();
  }

  @override
  Widget build(BuildContext context) {
    final journal = widget.journal;
    return CupertinoContextMenu.builder(
      enableHapticFeedback: true,
      actions: [
        CupertinoContextMenuAction(
          trailingIcon: CupertinoIcons.pencil,
          onPressed: () => _dismissMenuThen(context, () async {
            editJournal(this.context, ref, journal);
          }),
          child: const Text('Edit'),
        ),
        CupertinoContextMenuAction(
          trailingIcon: CupertinoIcons.share,
          onPressed: () => _dismissMenuThen(context, () async {
            shareJournal(this.context, journal);
          }),
          child: const Text('Share'),
        ),
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          trailingIcon: CupertinoIcons.delete,
          onPressed: () => _dismissMenuThen(context, () async {
            final shouldDelete = await confirmDeleteJournal(this.context);
            if (!shouldDelete || !mounted) return;
            await deleteJournal(this.context, ref, journal.id);
          }),
          child: const Text('Delete'),
        ),
      ],
      builder: (ctx, animation) => ConstrainedBox(
        // Cap the preview's intrinsic size. Without this, CupertinoContextMenu's
        // delegate can compute childSize.height larger than the overlay, making
        // the menu-sheet constraint `size.height - childSize.height - padding`
        // go negative and triggering a layout assertion. The cap is larger than
        // any real grid cell, so in-grid rendering is unaffected.
        constraints: const BoxConstraints(maxWidth: 240, maxHeight: 340),
        child: _JournalCardVisual(
          journal: journal,
          // Only accept taps when the menu is at rest — during the zoom
          // transition, taps should be consumed by the context menu route.
          onTap: animation.value == 0 ? _openJournal : null,
        ),
      ),
    );
  }
}

class _JournalCardVisual extends StatelessWidget {
  final JournalState journal;
  final VoidCallback? onTap;

  const _JournalCardVisual({required this.journal, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Color(0xFF222222),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://image.tmdb.org/t/p/w342${journal.moviePoster}',
                  width: 150,
                  height: 215,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journal.movieTitle,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    journal.updatedAt.format(pattern: 'MMM. do yyyy'),
                    style: GoogleFonts.nothingYouCouldDo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
