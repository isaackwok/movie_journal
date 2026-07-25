import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/shared_widgets/provider_sign_in_button.dart';
import 'package:movie_journal/supabase_auth_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.logScreenView('Login');
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await SupabaseAuthManager.signInWithGoogle();
      AnalyticsManager.logSignIn(method: 'google');
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
      await SupabaseAuthManager.signInWithApple();
      AnalyticsManager.logSignIn(method: 'apple');
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
              ProviderSignInButton(
                disabled: _isLoading,
                onPressed: _signInWithGoogle,
                icon: SvgPicture.asset('assets/images/google_icon.svg'),
                label: 'Sign in with Google',
              ),
              const SizedBox(height: 16),
              // Sign in with Apple button
              ProviderSignInButton(
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

