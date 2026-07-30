import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/account_link/controllers/account_link.dart';
import 'package:movie_journal/features/account_link/widgets/secure_account_sheet.dart';
import 'package:movie_journal/features/home/screens/home.dart';
import 'package:movie_journal/supabase_auth_manager.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/shared_widgets/circled_icon_button.dart';
import 'package:movie_journal/shared_widgets/confirmation_dialog.dart';
import 'package:movie_journal/themes.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameAsync = ref.watch(currentUsernameProvider);

    return ScreenViewTracker(
      screenName: 'Settings',
      child: Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: CircledIconButton(
          icon: Icons.arrow_back_ios_new,
          onPressed: () => Navigator.of(context).pop(),
          outerPadding: const EdgeInsets.only(left: 16),
        ),
        title: const Text('Settings'),
        titleSpacing: 10,
        titleTextStyle: const TextStyle(
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
    ));
  }
}

class _AccountSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsAccountLink = ref.watch(needsAccountLinkProvider);

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

          // A bridged user's only route back into this account, and the only
          // place they can find it once the one-time prompt has been dismissed.
          if (needsAccountLink) ...[
            _SettingsItem(
              title: 'Secure Account',
              titleColor: StatusColors.warning,
              onTap: () => SecureAccountSheet.show(context),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          ],

          // Logout option
          _SettingsItem(
            title: 'Logout',
            onTap: () => _showLogoutConfirmation(
              context,
              ref,
              isDeviceDependent: needsAccountLink,
            ),
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

  /// [isDeviceDependent] marks the case where a bridged user has no credential
  /// to sign back in with, so returning to this account depends entirely on
  /// this device.
  ///
  /// Not phrased as "you will lose everything": logging out is in fact
  /// recoverable. `AnonymousBridge` re-runs on the next cold start and
  /// `claim_anonymous_data` matches the profile by its retained `firebase_uid`,
  /// re-pointing the journals to the new session. What is unrecoverable is
  /// losing the *Firebase* anonymous session — a reinstall or a new phone —
  /// which signing out does not do. Overstating it would be a warning the user
  /// can discover is false, which is worse than none.
  void _showLogoutConfirmation(
    BuildContext context,
    WidgetRef ref, {
    bool isDeviceDependent = false,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: 'Logout',
            description: isDeviceDependent
                ? 'Your account has no Apple or Google sign-in attached yet, '
                      'so getting back in depends on this device — and '
                      'reinstalling the app would lose your journals for good. '
                      'Secure your account first.'
                : 'Are you sure you want to logout?',
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
              await SupabaseAuthManager.signOut();
              ref.invalidate(journalsControllerProvider);
              ref.invalidate(currentUsernameProvider);
              // Otherwise the next sign-in reuses this user's cached
              // profile-existence answer and can skip CreateUserScreen.
              ref.invalidate(hasProfileProvider);
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
              await _deleteAccount(context, ref);
            },
          ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    if (SupabaseAuthManager.currentUser == null) return;

    // 1. Confirm presence before anything destructive. Supabase has no
    //    `requires-recent-login`, so unlike the Firebase flow this is no
    //    longer load-bearing for correctness — it is kept because backing out
    //    of the provider prompt must still cancel the deletion.
    try {
      final confirmed = await SupabaseAuthManager.reauthenticate();
      if (!confirmed) return; // user backed out of the prompt
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Re-authentication required: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 2. A single server-side call. Deleting the auth user cascades to the
    //    profile and journals and fires the tombstone triggers, so there is no
    //    longer a window where data is gone but the account still exists —
    //    the half-deleted state the old ordering existed to avoid.
    try {
      final deletedJournalIds = await SupabaseAuthManager.deleteAccount();
      for (final id in deletedJournalIds) {
        AnalyticsManager.logJournalDeleted(journalId: id);
      }

      ref.invalidate(journalsControllerProvider);
      ref.invalidate(currentUsernameProvider);
      ref.invalidate(hasProfileProvider);

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
