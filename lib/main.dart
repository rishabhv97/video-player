import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Your screens
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  // Required for initializing async plugins (like flutter_secure_storage later) before runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const RubixPlayerApp());
}

class RubixPlayerApp extends StatelessWidget {
  const RubixPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RubixPlayer',
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