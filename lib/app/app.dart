import 'package:flutter/material.dart';
import 'theme.dart';
import 'router.dart';

class CinematicApp extends StatelessWidget {
  const CinematicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinematic',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
