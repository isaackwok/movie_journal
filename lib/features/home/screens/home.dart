import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/anonymous_bridge.dart';
import 'package:movie_journal/features/account_link/widgets/secure_account_banner.dart';
import 'package:movie_journal/features/home/widgets/add_movie_button.dart';
import 'package:movie_journal/features/home/widgets/empty_placeholder.dart';
import 'package:movie_journal/features/home/widgets/journals_list.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/login/screens/login.dart';
import 'package:movie_journal/features/login/screens/create_user.dart';
import 'package:movie_journal/features/onboarding/controllers/splash_shown.dart';
import 'package:movie_journal/features/onboarding/screens/branding_splash.dart';
import 'package:movie_journal/features/settings/screens/settings.dart';
import 'package:movie_journal/supabase_auth_manager.dart';
import 'package:movie_journal/supabase_db_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider that streams Supabase authentication state changes
/// Returns the current User or null if not authenticated
final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseAuthManager.authStateChanges;
});

/// Provider that fetches the current user's username from `profiles`
final currentUsernameProvider = FutureProvider<String>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) {
    return 'Guest';
  }

  final userData = await SupabaseDbManager().getUser(authState.id);
  return userData?['username'] ?? 'User';
});

/// A missing profile is ambiguous during the migration window. It means either
/// a genuinely new user, OR a migrated user whose sign-in did not attach to
/// their pre-created account (their provider email changed since the export,
/// so Supabase's email auto-linking had nothing to match on). The second case
/// is why `claim_migrated_data()` exists: it matches on the provider `sub` via
/// `firebase_identity_map` and re-points the pre-created profile + journals to
/// the caller.
///
/// This lives in a provider, not in the `FutureBuilder` it replaced, because
/// `FutureBuilder(future: <inline expression>)` re-evaluates on every rebuild.
/// The claim RPC must run at most once per sign-in; Riverpod's caching is what
/// makes that true.
/// Runs the pre-migration anonymous-account bridge once per app start, before
/// a signed-out user is offered the login screen. See [AnonymousBridge].
///
/// Returns `false` fast (no network) for the common case of a device with no
/// Firebase anonymous session.
final anonymousBridgeProvider = FutureProvider<bool>((ref) async {
  return AnonymousBridge.attempt();
});

/// Whether the signed-in user already has a `profiles` row — i.e. whether to
/// show HomeScreen or CreateUserScreen.
final hasProfileProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return false;

  final db = SupabaseDbManager();
  if (await db.userExists(user.id)) return true;

  // No profile row. Attempt the claim, then re-check: `claimMigratedData`
  // returns 'no_mapping' for a genuinely new user (not an error), and
  // 'claimed' after re-pointing a migrated user's data to this account.
  // Fail CLOSED, deliberately. Swallowing this and returning false would send
  // the user to CreateUserScreen, and a migrated user who creates a second
  // profile there strands their imported journals under the pre-created
  // account — recoverable only by hand. A surfaced error is retryable; a
  // duplicate profile is not, so the error is the better failure.
  await db.claimMigratedData();
  return db.userExists(user.id);
});

/// Reusable loading widget with centered circular progress indicator
class LoadingScaffold extends StatelessWidget {
  const LoadingScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Show loading while checking auth state
    return authState.when(
      data: (user) {
        // If user is not logged in, show the branding splash on first
        // visit per session, then LoginScreen.
        if (user == null) {
          // A device carrying a pre-migration Firebase anonymous session can
          // reclaim its journals without ever signing in. Try that before
          // offering the login screen, since succeeding means this user should
          // never see one.
          final bridge = ref.watch(anonymousBridgeProvider);

          Widget signedOutUi() {
            final splashShown = ref.watch(splashShownProvider);
            return splashShown
                ? const LoginScreen()
                : const BrandingSplashScreen();
          }

          return bridge.when(
            // On success the auth stream re-emits with the new session and
            // this branch is replaced by the signed-in path.
            data: (claimed) =>
                claimed ? const LoadingScaffold() : signedOutUi(),
            loading: () => const LoadingScaffold(),
            // AnonymousBridge.attempt() is written not to throw, so this is
            // defence in depth: a bridge problem must never cost a normal user
            // the ability to sign in.
            error: (_, _) => signedOutUi(),
          );
        }

        // Does this user have a `profiles` row? Runs the migration claim RPC
        // once when they don't — see hasProfileProvider.
        return ref
            .watch(hasProfileProvider)
            .when(
              data: (hasProfile) => hasProfile
                  ? _buildHomeScreen(context, ref)
                  : const CreateUserScreen(),
              loading: () => const LoadingScaffold(),
              error: (error, stack) => Scaffold(
                body: Center(child: Text('Error checking user: $error')),
              ),
            );
      },
      loading: () => const LoadingScaffold(),
      error:
          (error, stack) =>
              Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildHomeScreen(BuildContext context, WidgetRef ref) {
    final journalsAsync = ref.watch(journalsControllerProvider);
    final usernameAsync = ref.watch(currentUsernameProvider);

    return journalsAsync.when(
      data: (journalsState) {
        final journals = journalsState.journals;
        return ScreenViewTracker(
          screenName: 'Home',
          child: Scaffold(
          key: const PageStorageKey('home'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            toolbarHeight: 76,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        usernameAsync.when(
                          data:
                              (username) => Text(
                                username,
                                style: GoogleFonts.nothingYouCouldDo(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          loading:
                              () => Text(
                                'Loading...',
                                style: GoogleFonts.nothingYouCouldDo(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          error:
                              (_, _) => Text(
                                'User',
                                style: GoogleFonts.nothingYouCouldDo(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${journals.length} movie journals',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const SettingsScreen(),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.settings,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const AddMovieButton(),
              ],
            ),
            centerTitle: false,
          ),
          body: Column(
            children: [
              // Renders nothing unless this user came through the anonymous
              // bridge and still holds a credential-less session.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SecureAccountBanner(journalCount: journals.length),
              ),
              // EmptyPlaceholder stays outside a scroll view: its LayoutBuilder
              // needs a bounded height, which Expanded gives it and a
              // SingleChildScrollView would not.
              Expanded(
                child: journals.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: EmptyPlaceholder(),
                      )
                    : const SingleChildScrollView(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        child: JournalsList(),
                      ),
              ),
            ],
          ),
        ));
      },
      loading: () => const LoadingScaffold(),
      error:
          (error, stack) => Scaffold(
            body: Center(child: Text('Error loading journals: $error')),
          ),
    );
  }
}
