import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashShownNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markShown() {
    state = true;
  }
}

final splashShownProvider = NotifierProvider<SplashShownNotifier, bool>(
  SplashShownNotifier.new,
);
