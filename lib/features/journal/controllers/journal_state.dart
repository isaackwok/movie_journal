import 'dart:convert';

import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/quesgen/review.dart';
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
    return SceneItem(path: path ?? this.path, caption: caption ?? this.caption);
  }
}

class JournalState {
  String id = '';
  int tmdbId = 0;
  String movieTitle = '';
  String moviePoster = '';
  List<Emotion> emotions = [];
  List<SceneItem> selectedScenes = [];
  List<Review> selectedRefs = [];
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
    List<Review>? selectedRefs,
    this.thoughts = '',
    Jiffy? createdAt,
    Jiffy? updatedAt,
  }) {
    this.id = id ?? const Uuid().v4();
    this.selectedRefs = selectedRefs ?? [];
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
    List<Review>? selectedRefs,
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
      'selectedRefs': selectedRefs.map((r) => r.toMap()).toList(),
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
      'selectedRefs': selectedRefs.map((r) => r.toMap()).toList(),
      'thoughts': thoughts,
      'createdAt': createdAt.toString(),
      'updatedAt': updatedAt.toString(),
    });
  }

  static JournalState fromJson(String json) {
    // Decode a given json string and return a JournalState object
    final map = jsonDecode(json);

    // Parse selectedRefs with backward compatibility
    List<Review> parseSelectedRefs(dynamic refsData) {
      if (refsData == null) return [];

      final refsList = refsData as List<dynamic>;
      return refsList.map((item) {
        if (item is String) {
          // Backward compatibility: old format was just strings
          return Review.fromString(item);
        } else if (item is Map<String, dynamic>) {
          return Review.fromMap(item);
        }
        return Review.fromString(item.toString());
      }).toList();
    }

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
      selectedRefs: parseSelectedRefs(map['selectedRefs']),
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
