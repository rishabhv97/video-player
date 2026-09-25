import 'package:flutter/material.dart';
import 'theme.dart';
import 'router.dart';

class RubixPlayerApp extends StatelessWidget {
  const RubixPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RubixPlayer',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
