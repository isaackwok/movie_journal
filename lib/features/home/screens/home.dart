import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/home/widgets/add_movie_button.dart';
import 'package:movie_journal/features/home/widgets/empty_placeholder.dart';
import 'package:movie_journal/features/home/widgets/journals_list.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/login/screens/login.dart';
import 'package:movie_journal/features/login/screens/create_user.dart';
import 'package:movie_journal/firebase_manager.dart';
import 'package:movie_journal/firestore_manager.dart';

/// Provider that streams Firebase authentication state changes
/// Returns the current User or null if not authenticated
final authStateProvider = StreamProvider<User?>((ref) {
  final firebaseManager = FirebaseManager();
  return firebaseManager.authStateChanges;
});

/// Provider that fetches the current user's username from Firestore
final currentUsernameProvider = FutureProvider<String>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) {
    return 'Guest';
  }

  final userData = await FirestoreManager().getUser(authState.uid);
  return userData?['username'] ?? 'User';
});

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

        // Check if user document exists in Firestore
        return FutureBuilder<bool>(
          future: FirestoreManager().userExists(user.uid),
          builder: (context, snapshot) {
            // Still loading user existence check
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
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
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stack) =>
              Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildHomeScreen(BuildContext context, WidgetRef ref, User user) {
    final journalsAsync = ref.watch(journalsControllerProvider);
    final usernameAsync = ref.watch(currentUsernameProvider);

    return journalsAsync.when(
      data: (journalsState) {
        final journals = journalsState.journals;
        return Scaffold(
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
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
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
                              (_, __) => Text(
                                'User',
                                style: GoogleFonts.nothingYouCouldDo(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        ),
                        Text(
                          '${journals.length} movie journals',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
          body: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 40),
            child:
                journals.isEmpty
                    ? const EmptyPlaceholder()
                    : const JournalsList(),
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stack) => Scaffold(
            body: Center(child: Text('Error loading journals: $error')),
          ),
    );
  }
}
