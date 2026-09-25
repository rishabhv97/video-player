import 'package:flutter/material.dart';
import 'package:rubixplayer/shared/widgets/custom_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../features/auth/presentation/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userRole = 'Loading...';
  bool _isGuest = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    setState(() {
      if (token == null) {
        _isGuest = true;
        _userRole = 'Guest';
      } else {
        _isGuest = false;
        _userRole = prefs.getString('role') ?? prefs.getString('user_role') ?? 'User';
      }
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: RubixAppBar(showProfile: false),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: _isGuest ? Colors.grey[300] : Colors.orange[100],
                child: Icon(Icons.person, size: 60, color: _isGuest ? Colors.grey[600] : Colors.orange[700]),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isGuest ? 'Welcome, Guest!' : 'Welcome Back',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[900]),
            ),
            const SizedBox(height: 4),
            Text(
              _isGuest ? 'Sign in to access more features' : 'Account Type: ${_userRole.toUpperCase()}',
              style: TextStyle(fontSize: 16, color: _isGuest ? Colors.grey[600] : Colors.orange[700], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 60),
            
            if (_isGuest) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: const Text('Log In or Sign Up', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                  ),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Log Out', style: TextStyle(color: Colors.red, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _handleLogout,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}