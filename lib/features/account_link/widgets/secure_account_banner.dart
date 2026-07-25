import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/account_link/controllers/account_link.dart';
import 'package:movie_journal/features/account_link/widgets/secure_account_sheet.dart';
import 'package:movie_journal/themes.dart';

/// Persistent nudge for a bridged user whose session has no credential behind
/// it, plus the trigger for the one-time prompt that follows a successful claim.
///
/// Renders nothing — and costs nothing — for everyone else, which is every user
/// who did not come through the pre-migration anonymous bridge.
///
/// Not dismissible, by design. The condition it reports is not a preference but
/// a live risk (a reinstall loses the account), and it clears itself the moment
/// the identity is linked, so there is a real action that makes it go away.
class SecureAccountBanner extends ConsumerStatefulWidget {
  /// Passed through to the sheet's copy. Null renders the generic headline.
  final int? journalCount;

  const SecureAccountBanner({super.key, this.journalCount});

  @override
  ConsumerState<SecureAccountBanner> createState() =>
      _SecureAccountBannerState();
}

class _SecureAccountBannerState extends ConsumerState<SecureAccountBanner> {
  bool _promptScheduled = false;

  /// Opens the sheet once per app start, on the first build where the account
  /// turns out to need linking.
  ///
  /// Scheduled to a post-frame callback rather than run inline because both
  /// steps — flipping [accountLinkPromptShownProvider] and pushing a route —
  /// mutate state Riverpod and Navigator refuse to have mutated mid-build.
  void _schedulePromptIfNeeded() {
    if (_promptScheduled) return;
    _promptScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(accountLinkPromptShownProvider)) return;
      ref.read(accountLinkPromptShownProvider.notifier).markShown();
      SecureAccountSheet.show(context, journalCount: widget.journalCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(needsAccountLinkProvider)) return const SizedBox.shrink();
    _schedulePromptIfNeeded();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: StatusColors.warning.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => SecureAccountSheet.show(
            context,
            journalCount: widget.journalCount,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: StatusColors.warning.withAlpha(102)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: StatusColors.warning,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.priority_high,
                    color: Colors.black,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your account isn\'t secured',
                        style: TextStyle(
                          fontFamily: 'AvenirNext',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Attach Apple or Google so reinstalling the app '
                        'doesn\'t lose your journals.',
                        style: TextStyle(
                          fontFamily: 'AvenirNext',
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.white.withAlpha(204),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.white.withAlpha(153),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
