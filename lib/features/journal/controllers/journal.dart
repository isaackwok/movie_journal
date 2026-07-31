import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/journal/controllers/journal_state.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/quesgen/review.dart';
import 'package:movie_journal/supabase_auth_manager.dart';
import 'package:movie_journal/supabase_db_manager.dart';

// The model and mode types lived in this file before it was split; re-export
// so `controllers/journal.dart` stays the one import for journal state.
export 'journal_mode.dart';
export 'journal_state.dart';

class JournalController extends Notifier<JournalState> {
  @override
  JournalState build() {
    return JournalState();
  }

  JournalController setMovie(int tmdbId, String title, String poster) {
    state = state.copyWith(
      tmdbId: tmdbId,
      movieTitle: title,
      moviePoster: poster,
    );
    return this;
  }

  JournalController setTmdbId(int tmdbId) {
    state = state.copyWith(tmdbId: tmdbId);
    return this;
  }

  JournalController setMovieTitle(String title) {
    state = state.copyWith(movieTitle: title);
    return this;
  }

  JournalController setMoviePoster(String poster) {
    state = state.copyWith(moviePoster: poster);
    return this;
  }

  JournalController setEmotions(List<Emotion> emotions) {
    state = state.copyWith(emotions: emotions);
    return this;
  }

  JournalController setSelectedScenes(List<SceneItem> scenes) {
    state = state.copyWith(selectedScenes: scenes);
    return this;
  }

  JournalController setSelectedReviews(List<Review> reviews) {
    state = state.copyWith(selectedRefs: reviews);
    return this;
  }

  JournalController setThoughts(String thoughts) {
    state = state.copyWith(thoughts: thoughts);
    return this;
  }

  JournalController addSelectedScene(String scenePath) {
    state = state.copyWith(
      selectedScenes: [...state.selectedScenes, SceneItem(path: scenePath)],
    );
    return this;
  }

  JournalController addSelectedReview(Review review) {
    state = state.copyWith(selectedRefs: [...state.selectedRefs, review]);
    return this;
  }

  JournalController removeSelectedReview(Review review) {
    state = state.copyWith(
      selectedRefs: state.selectedRefs.where((e) => e != review).toList(),
    );
    return this;
  }

  JournalController addScene(String scenePath) {
    state = state.copyWith(
      selectedScenes: [...state.selectedScenes, SceneItem(path: scenePath)],
    );
    return this;
  }

  JournalController removeScene(String scenePath) {
    state = state.copyWith(
      selectedScenes:
          state.selectedScenes
              .where((scene) => scene.path != scenePath)
              .toList(),
    );
    return this;
  }

  JournalController updateSceneCaption(String scenePath, String caption) {
    final updatedScenes =
        state.selectedScenes.map((scene) {
          if (scene.path == scenePath) {
            return scene.copyWith(caption: caption.isEmpty ? null : caption);
          }
          return scene;
        }).toList();

    state = state.copyWith(selectedScenes: updatedScenes);
    return this;
  }

  String getSceneCaption(String scenePath) {
    final scene = state.selectedScenes.firstWhere(
      (scene) => scene.path == scenePath,
      orElse: () => SceneItem(path: scenePath),
    );
    return scene.caption ?? '';
  }

  JournalController clear() {
    state = JournalState();
    return this;
  }

  JournalController loadJournal(JournalState journal) {
    state = journal.copyWith();
    return this;
  }

  Future<JournalController> update() async {
    final now = Jiffy.now();
    state = state.copyWith(updatedAt: now);

    final user = SupabaseAuthManager.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    await SupabaseDbManager().updateJournal(state.id, state);

    final journalsController = ref.read(journalsControllerProvider.notifier);
    await journalsController.refreshJournals();

    unawaited(AnalyticsManager.logJournalUpdated(journalId: state.id));

    return this;
  }

  Future<JournalController> save() async {
    // Set creation and update times
    final now = Jiffy.now();
    state = state.copyWith(createdAt: state.createdAt, updatedAt: now);

    // Get current user
    final user = SupabaseAuthManager.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Save to Supabase
    final journalId = await SupabaseDbManager().addJournal(user.id, state);

    // Replace the client-generated UUID with the row's server-side id
    state = state.copyWith(id: journalId);

    // Refresh the journals list to include the new journal
    final journalsController = ref.read(journalsControllerProvider.notifier);
    await journalsController.refreshJournals();

    unawaited(
      AnalyticsManager.logJournalCreated(
        movieTitle: state.movieTitle,
        tmdbId: state.tmdbId,
        emotionCount: state.emotions.length,
        sceneCount: state.selectedScenes.length,
      ),
    );

    return this;
  }
}

final journalControllerProvider =
    NotifierProvider<JournalController, JournalState>(JournalController.new);
