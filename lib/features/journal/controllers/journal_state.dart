import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneItem &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          caption == other.caption;

  @override
  int get hashCode => Object.hash(path, caption);
}

class JournalState {
  final String id;
  final int tmdbId;
  final String movieTitle;
  final String moviePoster;
  final List<Emotion> emotions;
  final List<SceneItem> selectedScenes;
  final List<Review> selectedRefs;
  final String thoughts;
  final Jiffy createdAt;
  final Jiffy updatedAt;

  // A factory so updatedAt can default to the *resolved* createdAt — with a
  // plain initializer list both would get their own Jiffy.now() and drift by
  // a few microseconds.
  factory JournalState({
    String? id,
    int tmdbId = 0,
    String movieTitle = '',
    String moviePoster = '',
    List<Emotion> emotions = const [],
    List<SceneItem> selectedScenes = const [],
    List<Review>? selectedRefs,
    String thoughts = '',
    Jiffy? createdAt,
    Jiffy? updatedAt,
  }) {
    final resolvedCreatedAt = createdAt ?? Jiffy.now();
    return JournalState._(
      id: id ?? const Uuid().v4(),
      tmdbId: tmdbId,
      movieTitle: movieTitle,
      moviePoster: moviePoster,
      emotions: emotions,
      selectedScenes: selectedScenes,
      selectedRefs: selectedRefs ?? [],
      thoughts: thoughts,
      createdAt: resolvedCreatedAt,
      updatedAt: updatedAt ?? resolvedCreatedAt,
    );
  }

  JournalState._({
    required this.id,
    required this.tmdbId,
    required this.movieTitle,
    required this.moviePoster,
    required this.emotions,
    required this.selectedScenes,
    required this.selectedRefs,
    required this.thoughts,
    required this.createdAt,
    required this.updatedAt,
  });

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

  // Value equality: Riverpod's default updateShouldNotify compares with ==,
  // so equal states produced by no-op copyWith calls stop notifying
  // listeners, and .select() on list fields works as expected.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalState &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tmdbId == other.tmdbId &&
          movieTitle == other.movieTitle &&
          moviePoster == other.moviePoster &&
          listEquals(emotions, other.emotions) &&
          listEquals(selectedScenes, other.selectedScenes) &&
          listEquals(selectedRefs, other.selectedRefs) &&
          thoughts == other.thoughts &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    tmdbId,
    movieTitle,
    moviePoster,
    Object.hashAll(emotions),
    Object.hashAll(selectedScenes),
    Object.hashAll(selectedRefs),
    thoughts,
    createdAt,
    updatedAt,
  );

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

  static JournalState fromJson(String json) => fromMap(jsonDecode(json));

  /// The map counterpart of [fromJson]. Callers that already hold decoded
  /// data (e.g. a Postgres row) use this directly instead of paying an
  /// encode/decode round trip per row.
  static JournalState fromMap(Map<String, dynamic> map) {
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
