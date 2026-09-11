import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Assuming your screens are located here based on your architecture structure
import '../../../user/presentation/screens/user_main_screen.dart';
import '../../../admin/presentation/screens/admin_main_screen.dart';
import '../../../super_admin/presentation/screens/super_admin_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Initialize Dio and Secure Storage for API calls and token management
  // Replace the baseUrl with your actual Cloudflare Worker URL later
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8787'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the login process by calling the Cloudflare Worker API
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Please enter email and password');
      }

      // POST request to your Cloudflare Worker authentication endpoint
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final roleString = response.data['role']; // Expecting 'SUPER_ADMIN', 'ADMIN', or 'USER'

        // Save token and role securely on the device
        await _storage.write(key: 'jwt_token', value: token);
        await _storage.write(key: 'user_role', value: roleString);

        _routeUserBasedOnRole(roleString);
      } else {
        throw Exception('Authentication failed');
      }

    } on DioException catch (e) {
      // Extract error message from API response if available
      final errorMessage = e.response?.data['message'] ?? 'Network error occurred';
      _showError(errorMessage);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Routes the user to the correct screen based on the role returned from the backend
  void _routeUserBasedOnRole(String roleString) {
    if (!mounted) return;

    if (roleString == 'SUPER_ADMIN') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SuperAdminMainScreen()),
      );
    } else if (roleString == 'ADMIN') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminMainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserMainScreen()),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView( 
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_circle, size: 100, color: Colors.blue),
              const SizedBox(height: 32),
              const Text(
                'My Cloud',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading 
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text('Login', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}