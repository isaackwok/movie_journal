import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/screens/journal_content.dart';
import 'package:movie_journal/features/journal/widgets/journal_actions.dart';

enum _JournalCardAction { edit, share, delete }

class JournalCard extends ConsumerStatefulWidget {
  final JournalState journal;
  const JournalCard({super.key, required this.journal});

  @override
  ConsumerState<JournalCard> createState() => _JournalCardState();
}

class _JournalCardState extends ConsumerState<JournalCard> {
  Offset? _tapPosition;

  Future<void> _showContextMenu() async {
    final position = _tapPosition;
    if (position == null) return;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final selected = await showMenu<_JournalCardAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: const <PopupMenuEntry<_JournalCardAction>>[
        PopupMenuItem<_JournalCardAction>(
          value: _JournalCardAction.edit,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text('Edit'),
        ),
        PopupMenuItem<_JournalCardAction>(
          value: _JournalCardAction.share,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text('Share'),
        ),
        PopupMenuItem<_JournalCardAction>(
          value: _JournalCardAction.delete,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text('Delete', style: TextStyle(color: Color(0xFFFF615D))),
        ),
      ],
    );

    if (!mounted || selected == null) return;
    await _handleAction(selected);
  }

  Future<void> _handleAction(_JournalCardAction action) async {
    final journal = widget.journal;
    switch (action) {
      case _JournalCardAction.edit:
        editJournal(context, ref, journal);
        break;
      case _JournalCardAction.share:
        shareJournal(context, journal);
        break;
      case _JournalCardAction.delete:
        final shouldDelete = await confirmDeleteJournal(context);
        if (!shouldDelete || !mounted) return;
        await deleteJournal(context, ref, journal.id);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final journal = widget.journal;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTapDown: (details) => _tapPosition = details.globalPosition,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JournalContent(journalId: journal.id),
          ),
        );
      },
      onLongPress: _showContextMenu,
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
    );
  }
}
