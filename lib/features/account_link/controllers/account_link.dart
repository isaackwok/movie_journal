import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/home/screens/home.dart';
import 'package:movie_journal/supabase_auth_manager.dart';

/// Seam between the link UI and the auth SDK.
///
/// [SupabaseAuthManager] is all static methods over a live `Supabase.instance`,
/// which a widget test cannot stand up. Routing the two calls through a
/// provider lets tests override this with a fake and exercise every outcome —
/// including the conflict branch, which is otherwise unreachable without two
/// real provider accounts.
class AccountLinkService {
  const AccountLinkService();

  Future<IdentityLinkOutcome> linkApple() =>
      SupabaseAuthManager.linkAppleIdentity();

  Future<IdentityLinkOutcome> linkGoogle() =>
      SupabaseAuthManager.linkGoogleIdentity();
}

final accountLinkServiceProvider = Provider<AccountLinkService>(
  (ref) => const AccountLinkService(),
);

/// Whether the signed-in user still holds a session with no credential behind
/// it — see [SupabaseAuthManager.needsIdentityLink].
///
/// Derived from [authStateProvider] rather than read off `currentUser`, so a
/// successful link (which emits `userUpdated` with `is_anonymous: false`)
/// flips this to `false` on its own and the prompt and banner disappear with
/// no invalidation anywhere.
///
/// While auth state is still loading this is `false`, which keeps the banner
/// from flashing on for a frame during startup.
final needsAccountLinkProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  return SupabaseAuthManager.needsIdentityLink(user);
});

/// One-shot gate for the *automatic* prompt, so it opens once per app start
/// rather than on every return to the home screen.
///
/// Session-scoped on purpose, mirroring `splashShownProvider`: nothing is
/// persisted, so a user who dismisses the sheet is asked again next launch.
/// That is the intended pressure — the banner alone is easy to ignore forever,
/// and the cost of ignoring it is losing the account on reinstall.
class AccountLinkPromptShownNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markShown() {
    state = true;
  }
}

final accountLinkPromptShownProvider =
    NotifierProvider<AccountLinkPromptShownNotifier, bool>(
      AccountLinkPromptShownNotifier.new,
    );
