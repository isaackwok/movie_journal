import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/auth/auth_providers.dart';
import 'package:movie_journal/features/home/screens/home.dart';
import 'package:movie_journal/supabase_auth_manager.dart';
import 'package:movie_journal/themes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Must precede every plugin call below. Supabase.initialize persists the
  // session over platform channels, so it needs a live binding.
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Firebase stays initialized for Analytics (permanent, per plan decision 6)
  // and for the anonymous-account bridge, which reads the device's existing
  // Firebase session to prove ownership of pre-migration data.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    // Publishable, not secret: RLS is the security boundary. `anonKey` is the
    // deprecated spelling of this parameter.
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  // Disable analytics in debug builds to keep production data clean
  await AnalyticsManager.setAnalyticsCollectionEnabled(!kDebugMode);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();

    // Set/clear analytics user ID on auth state changes
    ref.listenManual(authStateProvider, (_, next) {
      next.whenData((user) {
        // Now the Supabase UUID rather than the Firebase UID. This is an
        // accepted analytics-continuity break: migrated users appear as new
        // ids from the cutover onward.
        AnalyticsManager.setUserId(user?.id);
        if (user != null) {
          AnalyticsManager.setUserProperty(
            'sign_in_method',
            SupabaseAuthManager.providerOf(user) ?? 'unknown',
          );
        }
      });
    }, fireImmediately: true);

    // Set username property when it becomes available
    ref.listenManual(currentUsernameProvider, (_, next) {
      next.whenData((username) {
        AnalyticsManager.setUserProperty('username', username);
      });
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Journal',
      themeMode: ThemeMode.dark,
      darkTheme: Themes.dark,
      theme: Themes.light,
      home: const HomeScreen(),
    );
  }
}
