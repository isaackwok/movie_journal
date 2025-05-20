import 'package:flutter/material.dart';
import 'package:movie_journal/features/home/screens/home.dart';
import 'package:movie_journal/themes.dart';

void main() {
  runApp(const MyApp());
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
