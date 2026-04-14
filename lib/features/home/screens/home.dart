import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/home/widgets/add_movie_button.dart';
import 'package:movie_journal/features/home/widgets/empty_placeholder.dart';
import 'package:movie_journal/features/home/widgets/journals_list.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/login/screens/login.dart';
import 'package:movie_journal/features/login/screens/create_user.dart';
import 'package:movie_journal/features/settings/screens/settings.dart';
import 'package:movie_journal/supabase_db_manager.dart';
import 'package:movie_journal/supabase_manager.dart';

/// Provider that streams Supabase authentication state changes.
/// Returns the current [AppUser] or null if not authenticated.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return SupabaseManager().authStateChanges;
});

/// Provider that fetches the current user's username from Supabase.
final currentUsernameProvider = FutureProvider<String>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) {
    return 'Guest';
  }

  final userData = await SupabaseDbManager().getUser(authState.id);
  return userData?['username'] ?? 'User';
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
        // If user is not logged in, show LoginScreen
        if (user == null) {
          return const LoginScreen();
        }

        // Check if user row exists in Supabase.
        return FutureBuilder<bool>(
          future: SupabaseDbManager().userExists(user.id),
          builder: (context, snapshot) {
            // Still loading user existence check
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScaffold();
            }

            // Error checking user existence
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Error checking user: ${snapshot.error}'),
                ),
              );
            }

            // User document doesn't exist - show CreateUserScreen
            if (snapshot.data == false) {
              return const CreateUserScreen();
            }

            // User exists - show home screen
            return _buildHomeScreen(context, ref, user);
          },
        );
      },
      loading: () => const LoadingScaffold(),
      error:
          (error, stack) =>
              Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildHomeScreen(BuildContext context, WidgetRef ref, AppUser user) {
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
                    // Image.asset('assets/images/avatar.png', width: 60, height: 60),
                    // SvgPicture.asset(
                    //   'assets/images/avatar.svg',
                    //   width: 60,
                    //   height: 60,
                    // ),
                    // SizedBox(width: 16),
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
          body:
              journals.isEmpty
                  ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: EmptyPlaceholder(),
                  )
                  : SingleChildScrollView(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: const JournalsList(),
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
