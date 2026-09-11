import 'package:flutter/material.dart';

// Your screens
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  // Required for initializing async plugins (like flutter_secure_storage later) before runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const CinematicApp());
}

class CinematicApp extends StatelessWidget {
  const CinematicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinematic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Set the LoginScreen as the initial route
      home: const LoginScreen(),
    );
  }
}