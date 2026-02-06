import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/home/screens/home.dart';
import 'package:movie_journal/firebase_manager.dart';
import 'package:movie_journal/firestore_manager.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/shared_widgets/circled_icon_button.dart';
import 'package:movie_journal/shared_widgets/confirmation_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameAsync = ref.watch(currentUsernameProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: CircledIconButton(
          icon: Icons.arrow_back_ios_new,
          onPressed: () => Navigator.of(context).pop(),
          outerPadding: const EdgeInsets.only(left: 16),
        ),
        title: const Text('Settings'),
        titleSpacing: 10,
        titleTextStyle: TextStyle(
          fontFamily: 'AvenirNext',
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        leadingWidth: 40 + 16,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username display
            usernameAsync.when(
              data:
                  (username) => Text(
                    username,
                    style: GoogleFonts.nothingYouCouldDo(
                      fontSize: 28,
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
                  (error, stack) => Text(
                    'User',
                    style: GoogleFonts.nothingYouCouldDo(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
            const SizedBox(height: 24),

            // Account section
            _AccountSection(),
          ],
        ),
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 0.5,
                fontFamily: 'AvenirNext',
              ),
            ),
          ),

          // Logout option
          _SettingsItem(
            title: 'Logout',
            onTap: () => _showLogoutConfirmation(context, ref),
          ),

          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),

          // Delete Account option
          _SettingsItem(
            title: 'Delete Account',
            titleColor: Colors.red,
            isLast: true,
            onTap: () => _showDeleteAccountConfirmation(context, ref),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: 'Logout',
            description: 'Are you sure you want to logout?',
            confirmText: 'Logout',
            confirmTextStyle: TextStyle(
              fontFamily: 'AvenirNext',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: Theme.of(context).colorScheme.primary,
            ),
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () async {
              await FirebaseManager.signOut();
              ref.invalidate(journalsControllerProvider);
              ref.invalidate(currentUsernameProvider);
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: 'Delete Account',
            description: 'All your data will be permanently deleted.',
            confirmText: 'Delete',
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () async {
              Navigator.of(context).pop();
              await _deleteAccount(context, ref);
            },
          ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    try {
      final firebaseManager = FirebaseManager();
      final userId = firebaseManager.currentUser?.uid;

      if (userId != null) {
        // Delete user data from Firestore
        await FirestoreManager().deleteUser(userId);
      }

      // Delete Firebase Auth account
      await firebaseManager.deleteAccount();

      ref.invalidate(journalsControllerProvider);
      ref.invalidate(currentUsernameProvider);

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SettingsItem extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingsItem({
    required this.title,
    this.titleColor,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine border radius based on position
    BorderRadius? borderRadius;
    if (isLast) {
      // Last item - only bottom corners
      borderRadius = const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      );
    }
    // Middle items get no border radius (null)

    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: titleColor ?? Colors.white,
                fontFamily: 'AvenirNext',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
