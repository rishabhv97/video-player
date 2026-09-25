import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'features/user/presentation/screens/user_main_screen.dart';
import 'features/admin/presentation/screens/admin_main_screen.dart';
import 'features/super_admin/presentation/screens/super_admin_main_screen.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final role = prefs.getString('user_role');
  final token = prefs.getString('jwt_token');

  Widget initialScreen;
  if (token != null && role != null) {
    if (role == 'super_admin') {
      initialScreen = const SuperAdminMainScreen();
    } else if (role == 'admin') {
      initialScreen = const AdminMainScreen();
    } else {
      initialScreen = const UserMainScreen();
    }
  } else {
    // Guest mode by default
    initialScreen = const UserMainScreen();
  }

  runApp(RubixPlayerApp(initialScreen: initialScreen));
}

class RubixPlayerApp extends StatelessWidget {
  final Widget initialScreen;
  const RubixPlayerApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RubixPlayer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }
}