import 'package:flutter/material.dart';
import '../../../../mock/mock_users.dart';
import '../../../../core/enums/user_role.dart';
import '../../../user/presentation/screens/user_main_screen.dart';
import '../../../admin/presentation/screens/admin_main_screen.dart';
import '../../../super_admin/presentation/screens/super_admin_main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 1)); // Mock loading
    if (!mounted) return;

    final role = MockUsers.currentUser.role;
    
    Widget nextScreen;
    switch (role) {
      case UserRole.admin:
        nextScreen = const AdminMainScreen();
        break;
      case UserRole.superAdmin:
        nextScreen = const SuperAdminMainScreen();
        break;
      case UserRole.user:
        nextScreen = const UserMainScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF4C44CF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_creation, color: Colors.white, size: 80),
            SizedBox(height: 16),
            Text(
              'RubixPlayer',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'STREAM & LINKS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}
