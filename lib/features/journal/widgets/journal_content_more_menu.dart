import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/journal/widgets/journal_actions.dart';

enum MoreOptionsItem { delete, edit }

class JournalContentMoreMenu extends ConsumerWidget {
  final String journalId;

  const JournalContentMoreMenu({super.key, required this.journalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton(
      menuPadding: EdgeInsets.zero,
      offset: Offset(0, 16),
      position: PopupMenuPosition.under,
      onSelected: (item) {
        onSelected(context, ref, item);
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<MoreOptionsItem>>[
            const PopupMenuItem<MoreOptionsItem>(
              value: MoreOptionsItem.edit,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text('Edit'),
            ),
            const PopupMenuItem<MoreOptionsItem>(
              value: MoreOptionsItem.delete,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text('Delete', style: TextStyle(color: Color(0xFFFF615D))),
            ),
          ],
    );
  }

  void onSelected(BuildContext context, WidgetRef ref, MoreOptionsItem item) async {
    switch (item) {
      case MoreOptionsItem.edit:
        final journals = ref.read(journalsControllerProvider).value?.journals ?? [];
        final journal = journals.where((j) => j.id == journalId).firstOrNull;
        if (journal == null) return;
        editJournal(context, ref, journal);
        break;
      case MoreOptionsItem.delete:
        final shouldDelete = await confirmDeleteJournal(context);
        if (!shouldDelete || !context.mounted) return;
        await deleteJournal(context, ref, journalId);
        if (!context.mounted) return;
        Navigator.of(context).pop();
        break;
    }
  }
}
