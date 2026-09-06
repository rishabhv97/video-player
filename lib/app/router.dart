import 'package:flutter/material.dart';
import '../features/auth/presentation/screens/splash_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      // More routes can be added here
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
