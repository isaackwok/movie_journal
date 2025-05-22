import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/home/screens/home.dart';
import 'package:movie_journal/themes.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  final runnableApp = _buildRunnableApp(
    isWeb: kIsWeb,
    webAppWidth: 400,
    app: const ProviderScope(child: MyApp()),
  );
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
