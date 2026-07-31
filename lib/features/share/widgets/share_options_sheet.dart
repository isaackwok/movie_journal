import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movie_journal/features/toast/custom_toast.dart';

/// The bottom sheet behind ShareTicketScreen's "Share" button: copy-thoughts
/// block (when there are thoughts) plus the three share destinations.
///
/// Destination callbacks run *after* the sheet pops, so they may push native
/// UI without the sheet in the way.
class ShareOptionsSheet extends StatelessWidget {
  final String thoughts;
  final VoidCallback onInstagramStory;
  final VoidCallback onThreads;
  final VoidCallback onOthers;

  const ShareOptionsSheet({
    super.key,
    required this.thoughts,
    required this.onInstagramStory,
    required this.onThreads,
    required this.onOthers,
  });

  static void show(
    BuildContext context, {
    required String thoughts,
    required VoidCallback onInstagramStory,
    required VoidCallback onThreads,
    required VoidCallback onOthers,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => ShareOptionsSheet(
            thoughts: thoughts,
            onInstagramStory: onInstagramStory,
            onThreads: onThreads,
            onOthers: onOthers,
          ),
    );
  }

  void _popThen(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (thoughts.isNotEmpty) ...[
                const Text(
                  'Copy text to post on Social',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _CopyThoughtsBlock(thoughts: thoughts),
                const SizedBox(height: 24),
              ],
              const Text(
                'Share Option',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ShareOptionTile(
                    label: 'Story',
                    icon: Image.asset(
                      'assets/images/instagram_logo.png',
                      width: 48,
                      height: 48,
                    ),
                    onTap: () => _popThen(context, onInstagramStory),
                  ),
                  const SizedBox(width: 24),
                  _ShareOptionTile(
                    label: 'Threads',
                    icon: Image.asset(
                      'assets/images/threads_logo.png',
                      width: 48,
                      height: 48,
                    ),
                    onTap: () => _popThen(context, onThreads),
                  ),
                  const Spacer(),
                  _ShareOptionTile(
                    label: 'Others',
                    icon: const Icon(
                      Icons.more_horiz,
                      color: Colors.white,
                      size: 24,
                    ),
                    onTap: () => _popThen(context, onOthers),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The journal's thoughts with a full-width "Copy Text" action underneath.
class _CopyThoughtsBlock extends StatelessWidget {
  final String thoughts;

  const _CopyThoughtsBlock({required this.thoughts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              thoughts,
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          GestureDetector(
            // Opaque so the whole row width is tappable, not just the
            // centered icon+text glyphs (the default deferToChild would
            // ignore taps on the empty space).
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Clipboard.setData(ClipboardData(text: thoughts));
              CustomToast.showSuccess(context, 'Copied to clipboard');
            },
            child: Padding(
              // Vertical padding enlarges the touch target so it matches the
              // visible button area.
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.copy,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Copy Text',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontFamily: 'AvenirNext',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One circular destination tile (48px circle + caption).
class _ShareOptionTile extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'AvenirNext',
            ),
          ),
        ],
      ),
    );
  }
}
