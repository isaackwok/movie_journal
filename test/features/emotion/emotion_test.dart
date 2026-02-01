import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/emotion/emotion.dart';

void main() {
  group('Emotion data integrity', () {
    test('emotionList contains exactly 24 emotions', () {
      expect(emotionList.length, 24);
    });

    test('all 4 groups present: Uplifting, Intense, Soothing, Quiet', () {
      final groups = emotionList.values.map((e) => e.group).toSet();
      expect(groups, {'Uplifting', 'Intense', 'Soothing', 'Quiet'});
    });

    test('each group has exactly 6 emotions', () {
      final groupCounts = <String, int>{};
      for (final emotion in emotionList.values) {
        groupCounts[emotion.group] = (groupCounts[emotion.group] ?? 0) + 1;
      }
      for (final entry in groupCounts.entries) {
        expect(entry.value, 6, reason: '${entry.key} should have 6 emotions');
      }
    });

    test('Uplifting/Intense are high energy, Soothing/Quiet are low energy',
        () {
      for (final emotion in emotionList.values) {
        if (emotion.group == 'Uplifting' || emotion.group == 'Intense') {
          expect(emotion.energyLevel, 'high',
              reason: '${emotion.name} in ${emotion.group} should be high');
        } else {
          expect(emotion.energyLevel, 'low',
              reason: '${emotion.name} in ${emotion.group} should be low');
        }
      }
    });

    test('each emotion has a unique id', () {
      final ids = emotionList.values.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'ids should be unique');
    });

    test('emotion lookup by id works (validates fromJson emotion parsing)',
        () {
      // This mirrors the lookup logic in JournalState.fromJson
      const testId = 'joyful';
      final found = emotionList.entries.firstWhere(
        (entry) => entry.value.id == testId,
        orElse: () => emotionList.entries.first,
      );
      expect(found.value.id, testId);
      expect(found.value.name, 'Joyful');
      expect(found.value.group, 'Uplifting');
    });
  });
}
