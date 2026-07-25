import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/account_link/controllers/account_link.dart';
import 'package:movie_journal/features/toast/custom_toast.dart';
import 'package:movie_journal/shared_widgets/provider_sign_in_button.dart';
import 'package:movie_journal/supabase_auth_manager.dart';
import 'package:movie_journal/themes.dart';

/// Asks a bridged user to attach an Apple or Google identity to the anonymous
/// session their journals were recovered into.
///
/// Deliberately not blocking: it is dismissible and the app is fully usable
/// behind it. The problem this fixes was created by the migration, so forcing
/// the user through a sign-in to keep using their own journals would charge
/// them for it. Persistence comes from [SecureAccountBanner] instead, which
/// stays put until the identity is linked.
class SecureAccountSheet extends ConsumerStatefulWidget {
  /// Shown in the copy when known ("we found your 17 journals"). Concrete
  /// numbers make the stake legible in a way "your data" does not.
  final int? journalCount;

  const SecureAccountSheet({super.key, this.journalCount});

  static Future<void> show(BuildContext context, {int? journalCount}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151515),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SecureAccountSheet(journalCount: journalCount),
    );
  }

  @override
  ConsumerState<SecureAccountSheet> createState() => _SecureAccountSheetState();
}

class _SecureAccountSheetState extends ConsumerState<SecureAccountSheet> {
  bool _isLinking = false;

  /// Which provider hit "already attached to another account", or null. Kept
  /// inline rather than raised as a dialog so the alternative provider button
  /// is visible in the same breath as the explanation.
  String? _conflictedMethod;

  Future<void> _link(String method) async {
    if (_isLinking) return;
    setState(() {
      _isLinking = true;
      _conflictedMethod = null;
    });

    try {
      final service = ref.read(accountLinkServiceProvider);
      final outcome = method == 'apple'
          ? await service.linkApple()
          : await service.linkGoogle();
      if (!mounted) return;

      switch (outcome) {
        case IdentityLinkOutcome.linked:
          AnalyticsManager.logAccountLinked(method: method);
          // Toast before popping: FToast resolves its overlay from the context
          // it is handed, and this one is about to be torn down.
          CustomToast.init(context);
          CustomToast.showSuccess(context, 'Account secured');
          Navigator.of(context).pop();
        case IdentityLinkOutcome.cancelled:
          // They backed out of the system prompt. Leave the sheet open — that
          // is the state they were in a moment ago, and closing it would read
          // as the app having done something.
          break;
        case IdentityLinkOutcome.alreadyLinkedToAnotherAccount:
          AnalyticsManager.logAccountLinkConflict(method: method);
          setState(() => _conflictedMethod = method);
      }
    } catch (e) {
      if (!mounted) return;
      CustomToast.init(context);
      CustomToast.showError("Couldn't secure your account. Please try again.");
    } finally {
      if (mounted) setState(() => _isLinking = false);
    }
  }

  String get _headline {
    final count = widget.journalCount;
    if (count == null || count <= 0) return 'Keep your journals safe';
    return count == 1
        ? 'Keep your 1 journal safe'
        : 'Keep your $count journals safe';
  }

  @override
  Widget build(BuildContext context) {
    // Scrollable because the conflict notice can push the content past a short
    // screen, and this is the one sheet a user must be able to finish.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _headline,
              style: const TextStyle(
                fontFamily: 'AvenirNext',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'They currently live on this device only. Attach an Apple or '
              'Google account and you can sign back in after a reinstall, or '
              'on a new phone.',
              style: TextStyle(
                fontFamily: 'AvenirNext',
                fontSize: 16,
                height: 1.5,
                color: Colors.white.withAlpha(204),
              ),
            ),
            if (_conflictedMethod != null) ...[
              const SizedBox(height: 20),
              _ConflictNotice(method: _conflictedMethod!),
            ],
            const SizedBox(height: 28),
            ProviderSignInButton(
              disabled: _isLinking,
              onPressed: () => _link('google'),
              icon: SvgPicture.asset('assets/images/google_icon.svg'),
              label: 'Continue with Google',
            ),
            const SizedBox(height: 12),
            ProviderSignInButton(
              disabled: _isLinking,
              onPressed: () => _link('apple'),
              icon: const Icon(Icons.apple, color: Colors.white, size: 28),
              label: 'Continue with Apple',
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _isLinking
                    ? null
                    : () => Navigator.of(context).pop(),
                child: Text(
                  'Not now',
                  style: TextStyle(
                    fontFamily: 'AvenirNext',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(153),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The one outcome the flow cannot resolve by itself: the chosen provider
/// account is already an identity on a different Supabase user.
///
/// Merging the two would need a server-side journal move plus a rule for which
/// profile survives. Reaching this state requires having signed up separately
/// during the migration window *and* still holding the old Firebase session, so
/// the population is expected to be tiny — `account_link_conflict` is logged to
/// find out before anyone builds the merge.
class _ConflictNotice extends StatelessWidget {
  final String method;

  const _ConflictNotice({required this.method});

  @override
  Widget build(BuildContext context) {
    final provider = method == 'apple' ? 'Apple' : 'Google';
    final other = method == 'apple' ? 'Google' : 'Apple';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StatusColors.warning.withAlpha(26),
        border: Border.all(color: StatusColors.warning.withAlpha(102)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: StatusColors.warning,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.priority_high,
              color: Colors.black,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'That $provider account is already attached to another Fink '
              'account, so it can\'t also hold this one. Try $other instead — '
              'or get in touch and we can join the two accounts for you.',
              style: const TextStyle(
                fontFamily: 'AvenirNext',
                fontSize: 14,
                height: 1.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
