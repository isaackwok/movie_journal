import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/onboarding/controllers/splash_posters.dart';
import 'package:movie_journal/features/onboarding/controllers/splash_shown.dart';
import 'package:movie_journal/features/onboarding/widgets/poster_marquee.dart';

class BrandingSplashScreen extends ConsumerStatefulWidget {
  const BrandingSplashScreen({super.key});

  @override
  ConsumerState<BrandingSplashScreen> createState() =>
      _BrandingSplashScreenState();
}

class _BrandingSplashScreenState extends ConsumerState<BrandingSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _marqueeController;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.logScreenView('OnboardingSplash');

    // Pre-warm the poster fetch so it likely arrives during fade-in.
    // ignore: unused_result
    ref.read(splashPostersProvider.future);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );
    _fade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 20, // 0–600ms fade-in
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 60, // 600–2400ms hold
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 20, // 2400–3000ms fade-out
      ),
    ]).animate(_fadeController);

    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        ref.read(splashShownProvider.notifier).markShown();
      }
    });

    _marqueeController = AnimationController(
      duration: const Duration(seconds: 24),
      vsync: this,
    )..repeat();

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _marqueeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Bottom marquee strip — clipped to the bottom 380px so the rotated,
          // overflowing column can never escape this region.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 380,
            child: PosterMarquee(progress: _marqueeController),
          ),
          // Center brand mark (logo + wordmark are baked into the SVG) and
          // tagline. The SVG already contains the "i + ticket" mark *and* the
          // handwritten "Fink" word, so we don't render an extra wordmark here.
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/fink_logo.svg',
                    height: 160,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'From film to ink,\nBuild your movie journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.35,
                      fontFamily: 'AvenirNext',
                      fontWeight: FontWeight.w400,
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
