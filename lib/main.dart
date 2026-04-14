import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/home/screens/home.dart';
import 'package:movie_journal/shared_preferences_manager.dart';
import 'package:movie_journal/themes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  final runnableApp = _buildRunnableApp(
    isWeb: kIsWeb,
    webAppWidth: 400,
    app: const ProviderScope(child: MyApp()),
  );

  // Initialize shared preferences with default values
  await SharedPreferencesManager.init();

  WidgetsFlutterBinding.ensureInitialized();

  // firebase_core + firebase_analytics remain for analytics only.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Supabase handles auth + database (see lib/supabase_manager.dart and
  // lib/supabase_db_manager.dart).
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Disable analytics in debug builds to keep production data clean
  await AnalyticsManager.setAnalyticsCollectionEnabled(!kDebugMode);

  runApp(runnableApp);
}

Widget _buildRunnableApp({
  required bool isWeb,
  required double webAppWidth,
  required Widget app,
}) {
  if (!isWeb) {
    return app;
  }

  return Center(
    child: ClipRect(child: SizedBox(width: webAppWidth, child: app)),
  );
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
        AnalyticsManager.setUserId(user?.id);
        if (user != null) {
          AnalyticsManager.setUserProperty('sign_in_method', user.providerId);
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
