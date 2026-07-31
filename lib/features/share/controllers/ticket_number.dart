import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';

/// A journal's 1-based chronological position across all journals — the
/// ticket number printed on the share ticket. 0 while the journals are still
/// loading or when the id is unknown. Derived here once per journals change
/// instead of re-sorting the full list on every ShareTicketScreen rebuild.
final ticketNumberProvider = Provider.family<int, String>((ref, journalId) {
  final journals = ref.watch(
    journalsControllerProvider.select((s) => s.value?.journals),
  );
  if (journals == null || journals.isEmpty) return 0;

  final sorted = [...journals]
    ..sort((a, b) => a.createdAt.dateTime.compareTo(b.createdAt.dateTime));
  final index = sorted.indexWhere((j) => j.id == journalId);
  return index == -1 ? 0 : index + 1;
});
