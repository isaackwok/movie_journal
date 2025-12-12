import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:movie_journal/firebase_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseManager.signInWithGoogle();
    } catch (e) {
      // handle error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseManager.signInWithApple();
    } catch (e) {
      // handle error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Title
              const Text(
                'Start your movie journals.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  fontFamily: 'AvenirNext',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Subtitle
              const Text(
                'Get started by signing in with your\nGoogle or Apple accounts.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'AvenirNext',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Sign in with Google button
              _SignInButton(
                disabled: _isLoading,
                onPressed: _signInWithGoogle,
                icon: SvgPicture.asset('assets/images/google_icon.svg'),
                label: 'Sign in with Google',
              ),
              const SizedBox(height: 16),
              // Sign in with Apple button
              _SignInButton(
                disabled: _isLoading,
                onPressed: _signInWithApple,
                icon: const Icon(Icons.apple, color: Colors.white, size: 28),
                label: 'Sign in with Apple',
              ),
              const Spacer(),
              // Loading indicator
              // if (_isLoading)
              //   const Padding(
              //     padding: EdgeInsets.only(bottom: 32.0),
              //     child: CircularProgressIndicator(color: Colors.white),
              //   )
              // else
              //   const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final bool disabled;

  const _SignInButton({
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
              Theme.of(context).colorScheme.primary),
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: Theme.of(context).colorScheme.primary.withAlpha(76),
                width: 1,
              );
            }
            return BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 1);
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
