import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// A class providing Firebase Analytics wrappers for event tracking.
/// All methods are safe to call without Firebase initialized (e.g., in tests).
class AnalyticsManager {
  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  /// Safely execute an analytics call, silently ignoring errors when
  /// Firebase is not initialized (e.g., in test environments).
  static Future<void> _safe(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      debugPrint('AnalyticsManager: $e');
    }
  }

  // ── User identification ──────────────────────────────────────────

  static Future<void> setUserId(String? userId) {
    return _safe(() => _analytics.setUserId(id: userId));
  }

  static Future<void> setUserProperty(String name, String? value) {
    return _safe(() => _analytics.setUserProperty(name: name, value: value));
  }

  // ── Collection control ───────────────────────────────────────────

  static Future<void> setAnalyticsCollectionEnabled(bool enabled) {
    return _safe(() => _analytics.setAnalyticsCollectionEnabled(enabled));
  }

  // ── Screen views ─────────────────────────────────────────────────

  static Future<void> logScreenView(String screenName) {
    return _safe(
      () => _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      ),
    );
  }

  // ── Custom events ────────────────────────────────────────────────

  static Future<void> logSignIn({required String method}) {
    return _safe(() => _analytics.logLogin(loginMethod: method));
  }

  static Future<void> logSignUp({required String method}) {
    return _safe(() => _analytics.logSignUp(signUpMethod: method));
  }

  static Future<void> logJournalCreated({
    required String movieTitle,
    required int tmdbId,
    required int emotionCount,
    required int sceneCount,
  }) {
    return _safe(
      () => _analytics.logEvent(
        name: 'journal_created',
        parameters: {
          'movie_title': movieTitle,
          'tmdb_id': tmdbId,
          'emotion_count': emotionCount,
          'scene_count': sceneCount,
        },
      ),
    );
  }

  static Future<void> logJournalUpdated({required String journalId}) {
    return _safe(
      () => _analytics.logEvent(
        name: 'journal_updated',
        parameters: {'journal_id': journalId},
      ),
    );
  }

  static Future<void> logJournalDeleted({required String journalId}) {
    return _safe(
      () => _analytics.logEvent(
        name: 'journal_deleted',
        parameters: {'journal_id': journalId},
      ),
    );
  }

  static Future<void> logJournalShared({
    required String movieTitle,
    required String shareMethod,
  }) {
    return _safe(
      () => _analytics.logEvent(
        name: 'journal_shared',
        parameters: {
          'movie_title': movieTitle,
          'share_method': shareMethod,
        },
      ),
    );
  }

  static Future<void> logTicketSaved({required String movieTitle}) {
    return _safe(
      () => _analytics.logEvent(
        name: 'ticket_saved',
        parameters: {'movie_title': movieTitle},
      ),
    );
  }

  static Future<void> logMovieSearched({required String query}) {
    return _safe(
      () => _analytics.logEvent(
        name: 'movie_searched',
        parameters: {'query': query},
      ),
    );
  }

  static Future<void> logMovieSelected({
    required int tmdbId,
    required String movieTitle,
  }) {
    return _safe(
      () => _analytics.logEvent(
        name: 'movie_selected',
        parameters: {
          'tmdb_id': tmdbId,
          'movie_title': movieTitle,
        },
      ),
    );
  }
}

/// A widget that logs a screen view once when first mounted.
/// Use this to wrap ConsumerWidget/StatelessWidget screens that lack initState.
class ScreenViewTracker extends StatefulWidget {
  final String screenName;
  final Widget child;

  const ScreenViewTracker({
    super.key,
    required this.screenName,
    required this.child,
  });

  @override
  State<ScreenViewTracker> createState() => _ScreenViewTrackerState();
}

class _ScreenViewTrackerState extends State<ScreenViewTracker> {
  @override
  void initState() {
    super.initState();
    AnalyticsManager.logScreenView(widget.screenName);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
