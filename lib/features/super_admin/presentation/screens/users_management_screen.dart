import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserModel {
  final String id;
  final String email;
  final String role;
  final String createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? 'No Email',
      role: json['role'] ?? 'USER',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final Dio _dio = Dio();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      String baseUrl = dotenv.env['API_URL'] ?? '';
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final response = await _dio.get('$baseUrl/superadmin/users');
      final List data = response.data;

      if (mounted) {
        setState(() {
          _users = data.map((json) => UserModel.fromJson(json)).toList();
          _isLoading = false;
          _errorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load users: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeRole(UserModel user, String newRole) async {
    // Basic confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Role?'),
        content: Text('Are you sure you want to make ${user.email} an $newRole?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      String baseUrl = dotenv.env['API_URL'] ?? '';
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      await _dio.patch(
        '$baseUrl/superadmin/users/${user.id}/role',
        data: {'role': newRole},
      );

      // Re-fetch users to reflect changes accurately
      _fetchUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role successfully changed to $newRole'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removed CustomAppBar to avoid double AppBars with the Main Screen
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blueGrey[900]))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchUsers,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      // Don't allow changing SUPER_ADMIN's own role (just a safety UI feature)
                      final isSuperAdmin = user.role == 'SUPER_ADMIN';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: user.role == 'ADMIN' || user.role == 'SUPER_ADMIN' 
                                ? Colors.purple[100] 
                                : Colors.orange[100],
                            child: Icon(
                              user.role == 'ADMIN' || user.role == 'SUPER_ADMIN' 
                                  ? Icons.admin_panel_settings 
                                  : Icons.person,
                              color: user.role == 'ADMIN' || user.role == 'SUPER_ADMIN' 
                                  ? Colors.purple[700] 
                                  : Colors.orange[700],
                            ),
                          ),
                          title: Text(
                            user.email,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Joined: ${user.createdAt.isNotEmpty && user.createdAt.contains('T') ? user.createdAt.split('T').first : 'Unknown'}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: isSuperAdmin
                              ? const Chip(
                                  label: Text('SUPER ADMIN', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  backgroundColor: Colors.orange,
                                )
                              : PopupMenuButton<String>(
                                  onSelected: (newRole) {
                                    if (newRole != user.role) {
                                      _changeRole(user, newRole);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'USER',
                                      child: Row(
                                        children: [
                                          Icon(Icons.person, color: Colors.orange[700], size: 20),
                                          const SizedBox(width: 8),
                                          const Text('Make User'),
                                          if (user.role == 'USER') const Spacer(),
                                          if (user.role == 'USER') const Icon(Icons.check, color: Colors.green, size: 20),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'ADMIN',
                                      child: Row(
                                        children: [
                                          Icon(Icons.admin_panel_settings, color: Colors.purple[700], size: 20),
                                          const SizedBox(width: 8),
                                          const Text('Make Admin'),
                                          if (user.role == 'ADMIN') const Spacer(),
                                          if (user.role == 'ADMIN') const Icon(Icons.check, color: Colors.green, size: 20),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: Chip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          user.role,
                                          style: TextStyle(
                                            color: user.role == 'ADMIN' ? Colors.purple[700] : Colors.orange[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 16,
                                          color: user.role == 'ADMIN' ? Colors.purple[700] : Colors.orange[700],
                                        ),
                                      ],
                                    ),
                                    backgroundColor: user.role == 'ADMIN' ? Colors.purple[50] : Colors.orange[50],
                                    side: BorderSide.none,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
