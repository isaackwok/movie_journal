import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/toast/custom_toast.dart';
import 'package:movie_journal/shared_widgets/confirmation_dialog.dart';

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
        // Handle edit action
        break;
      case MoreOptionsItem.delete:
        // Handle delete action
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => const _DeleteJournalDialog(),
        );

        if (shouldDelete == true) {
          await _deleteJournal(context, ref);
        }
        break;
    }
  }

  Future<void> _deleteJournal(BuildContext context, WidgetRef ref) async {
    try {
      // Initialize toast with context
      CustomToast.init(context);

      // Delete journal using controller (handles both Firestore and local state)
      await ref.read(journalsControllerProvider.notifier).removeJournal(journalId);

      // Show success toast
      CustomToast.showSuccess(context, 'Journal deleted successfully');

      // Navigate back to home screen
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Show error toast
      CustomToast.init(context);
      CustomToast.showError('Failed to delete journal');
    }
  }
}

class _DeleteJournalDialog extends StatelessWidget {
  const _DeleteJournalDialog();

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: 'Delete Journal',
      description: 'Are you sure you want to delete this journal?',
      cancelText: 'Cancel',
      confirmText: 'Delete',
      onCancel: () => Navigator.pop(context, false),
      onConfirm: () => Navigator.pop(context, true),
    );
  }
}
