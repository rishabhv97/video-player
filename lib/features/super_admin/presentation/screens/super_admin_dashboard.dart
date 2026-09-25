import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final Dio _dio = Dio();
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Dashboard Metrics
  int _totalUsers = 0;
  int _totalAdmins = 0;
  int _totalVideos = 0;
  int _totalViews = 0;

  @override
  void initState() {
    super.initState();
    _fetchPlatformStats();
  }

  Future<void> _fetchPlatformStats() async {
    try {
      String baseUrl = dotenv.env['API_URL'] ?? '';
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      
      final response = await _dio.get('$baseUrl/superadmin/stats');
      
      final data = response.data;

      if (mounted) {
        setState(() {
          _totalUsers = data['totalUsers'] ?? 0;
          _totalAdmins = data['totalAdmins'] ?? 0;
          _totalVideos = data['totalVideos'] ?? 0;
          _totalViews = data['totalViews'] ?? 0;
          _isLoading = false;
          _errorMessage = '';
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load stats. Ensure backend is updated.';
        });
      }
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title, 
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, color: color, size: 28),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Removed the CustomAppBar since SuperAdminMainScreen already has an AppBar
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blueGrey[900]))
          : RefreshIndicator(
              onRefresh: _fetchPlatformStats,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                children: [
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Text(
                    'Platform Overview',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.1,
                    children: [
                      _buildStatCard('Total Users', _totalUsers.toString(), Icons.people_outline, Colors.orange),
                      _buildStatCard('Total Admins', _totalAdmins.toString(), Icons.admin_panel_settings_outlined, Colors.purple),
                      _buildStatCard('Total Videos', _totalVideos.toString(), Icons.video_library_outlined, Colors.orange),
                      _buildStatCard('Total Views', _totalViews.toString(), Icons.remove_red_eye_outlined, Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}