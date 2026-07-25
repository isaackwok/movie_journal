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

  /// Which branch the pre-migration anonymous bridge took on this launch.
  ///
  /// One event with an `outcome` param rather than an event per branch, so the
  /// whole thing reads as a single funnel in GA. [outcome] must come from
  /// `BridgeOutcome.wire` — the values are dashboard keys, so renaming one
  /// silently breaks history rather than erroring.
  ///
  /// Fires on signed-out cold starts only (that is the sole caller of
  /// `AnonymousBridge.attempt()`), and analytics is off in debug builds — so
  /// this is TestFlight/release volume on a ~26-user app, not a firehose.
  static Future<void> logAnonymousBridge({required String outcome}) {
    return _safe(
      () => _analytics.logEvent(
        name: 'anonymous_bridge',
        parameters: {'outcome': outcome},
      ),
    );
  }

  /// A bridged user attached a provider identity to their anonymous session and
  /// can now sign back in after a reinstall. Should trend up until
  /// `claimed_still_on_anonymous_session` in `migration/bridge_status.ts` hits
  /// zero, after which it should never fire again.
  static Future<void> logAccountLinked({required String method}) {
    return _safe(
      () => _analytics.logEvent(
        name: 'account_linked',
        parameters: {'method': method},
      ),
    );
  }

  /// The chosen Apple/Google account already belongs to a different Fink
  /// account — the one case the link flow cannot resolve on its own.
  ///
  /// Logged specifically to *size* that population: a merge needs a server-side
  /// journal move plus a rule for which profile survives, and it is only worth
  /// building if this fires more than a handful of times.
  static Future<void> logAccountLinkConflict({required String method}) {
    return _safe(
      () => _analytics.logEvent(
        name: 'account_link_conflict',
        parameters: {'method': method},
      ),
    );
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
