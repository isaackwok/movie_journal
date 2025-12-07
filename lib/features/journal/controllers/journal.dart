import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/firestore_manager.dart';
import 'package:uuid/uuid.dart';

// Scene item with path and optional caption
class SceneItem {
  final String path;
  final String? caption;

  SceneItem({required this.path, this.caption});

  Map<String, dynamic> toMap() {
    final map = {'path': path};
    if (caption != null && caption!.isNotEmpty) {
      map['caption'] = caption!;
    }
    return map;
  }

  static SceneItem fromMap(Map<String, dynamic> map) {
    return SceneItem(
      path: map['path'] as String,
      caption: map['caption'] as String?,
    );
  }

  // Backward compatibility: parse from string format
  static SceneItem fromString(String path) {
    return SceneItem(path: path);
  }

  SceneItem copyWith({String? path, String? caption}) {
    return SceneItem(
      path: path ?? this.path,
      caption: caption ?? this.caption,
    );
  }
}

class JournalState {
  String id = '';
  int tmdbId = 0;
  String movieTitle = '';
  String moviePoster = '';
  List<Emotion> emotions = [];
  List<SceneItem> selectedScenes = [];
  List<String> selectedRefs = [];
  String thoughts = '';
  late Jiffy createdAt;
  late Jiffy updatedAt;

  JournalState({
    String? id,
    this.tmdbId = 0,
    this.movieTitle = '',
    this.moviePoster = '',
    this.emotions = const [],
    this.selectedScenes = const [],
    this.selectedRefs = const [],
    this.thoughts = '',
    Jiffy? createdAt,
    Jiffy? updatedAt,
  }) {
    this.id = id ?? Uuid().v4();
    this.createdAt = createdAt ?? Jiffy.now();
    this.updatedAt = updatedAt ?? this.createdAt;
  }

  JournalState copyWith({
    String? id,
    int? tmdbId,
    String? movieTitle,
    String? moviePoster,
    List<Emotion>? emotions,
    List<SceneItem>? selectedScenes,
    List<String>? selectedRefs,
    String? thoughts,
    Jiffy? createdAt,
    Jiffy? updatedAt,
  }) {
    return JournalState(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      movieTitle: movieTitle ?? this.movieTitle,
      moviePoster: moviePoster ?? this.moviePoster,
      emotions: emotions ?? this.emotions,
      selectedScenes: selectedScenes ?? this.selectedScenes,
      selectedRefs: selectedRefs ?? this.selectedRefs,
      thoughts: thoughts ?? this.thoughts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tmdbId': tmdbId,
      'movieTitle': movieTitle,
      'moviePoster': moviePoster,
      'emotions': emotions.map((e) => e.id).toList(),
      'selectedScenes': selectedScenes.map((scene) => scene.toMap()).toList(),
      'selectedRefs': selectedRefs,
      'thoughts': thoughts,
      'createdAt': createdAt.toString(),
      'updatedAt': updatedAt.toString(),
    };
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'tmdbId': tmdbId,
      'movieTitle': movieTitle,
      'moviePoster': moviePoster,
      'emotions': emotions.map((e) => e.id).toList(),
      'selectedScenes': selectedScenes.map((scene) => scene.toMap()).toList(),
      'selectedRefs': selectedRefs,
      'thoughts': thoughts,
      'createdAt': createdAt.toString(),
      'updatedAt': updatedAt.toString(),
    });
  }

  static JournalState fromJson(String json) {
    // Decode a given json string and return a JournalState object
    final map = jsonDecode(json);

    // Parse selectedScenes with backward compatibility
    List<SceneItem> parseSelectedScenes(dynamic scenesData) {
      if (scenesData == null) return [];

      final scenesList = scenesData as List<dynamic>;
      return scenesList.map((item) {
        if (item is String) {
          // Backward compatibility: old format was just strings
          return SceneItem.fromString(item);
        } else if (item is Map<String, dynamic>) {
          // New format: object with path and optional caption
          return SceneItem.fromMap(item);
        }
        return SceneItem(path: item.toString());
      }).toList();
    }

    return JournalState(
      id: map['id'] ?? '',
      tmdbId:
          map['tmdbId'] is int
              ? map['tmdbId']
              : int.parse(map['tmdbId'].toString()),
      movieTitle: map['movieTitle'] ?? '',
      moviePoster: map['moviePoster'] ?? '',
      emotions:
          (map['emotions'] as List<dynamic>? ?? []).map((emotionId) {
            final emotionEntry = emotionList.entries.firstWhere(
              (entry) => entry.value.id == emotionId,
              orElse: () => emotionList.entries.first,
            );
            return emotionEntry.value;
          }).toList(),
      selectedScenes: parseSelectedScenes(map['selectedScenes']),
      selectedRefs: List<String>.from(map['selectedRefs'] ?? []),
      thoughts: map['thoughts'] ?? '',
      createdAt:
          map['createdAt'] != null
              ? Jiffy.parse(map['createdAt'])
              : Jiffy.now(),
      updatedAt:
          map['updatedAt'] != null
              ? Jiffy.parse(map['updatedAt'])
              : Jiffy.now(),
    );
  }
}

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

  JournalController setselectedRefs(List<String> questions) {
    state = state.copyWith(selectedRefs: questions);
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

  JournalController addSelectedQuestion(String question) {
    state = state.copyWith(selectedRefs: [...state.selectedRefs, question]);
    return this;
  }

  JournalController removeSelectedQuestion(String question) {
    state = state.copyWith(
      selectedRefs: state.selectedRefs.where((e) => e != question).toList(),
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
          state.selectedScenes.where((scene) => scene.path != scenePath).toList(),
    );
    return this;
  }

  JournalController updateSceneCaption(String scenePath, String caption) {
    final updatedScenes = state.selectedScenes.map((scene) {
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

  Future<JournalController> save() async {
    // Set creation and update times
    final now = Jiffy.now();
    state = state.copyWith(createdAt: state.createdAt, updatedAt: now);

    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Save to Firestore
    final firestoreManager = FirestoreManager();
    final docRef = await firestoreManager.addJournal(user.uid, state);

    // Update the state with the Firestore document ID
    state = state.copyWith(id: docRef.id);

    // Refresh the journals list from Firestore to include the new journal
    final journalsController = ref.read(journalsControllerProvider.notifier);
    await journalsController.refreshJournals();

    return this;
  }
}

final journalControllerProvider =
    NotifierProvider<JournalController, JournalState>(JournalController.new);
