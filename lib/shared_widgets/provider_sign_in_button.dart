import 'package:flutter/material.dart';

/// The outlined Apple/Google button used by the login screen and by the
/// secure-your-account sheet.
///
/// Extracted so the two flows stay visually identical: they ask for the same
/// credential through the same native prompt, and a user who has seen one
/// should recognise the other. Only the label differs ("Sign in with…" when
/// signing in, "Continue with…" when attaching an identity to a session that
/// is already signed in).
class ProviderSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final bool disabled;

  const ProviderSignInButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.primary,
          ),
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: Theme.of(context).colorScheme.primary.withAlpha(76),
                width: 1,
              );
            }
            return BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1,
            );
          }),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'AvenirNext',
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.white.withAlpha(76);
            }
            return Colors.white;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          splashFactory: NoSplash.splashFactory,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [icon, const SizedBox(width: 12), Text(label)],
        ),
      ),
    );
  }
}
