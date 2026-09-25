import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State {
  final Dio _dio = Dio();
  bool _isLoading = true;
  
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

  Future _fetchPlatformStats() async {
    try {
      final String baseUrl = dotenv.env['API_URL'] ?? '';
      
      // We will build this endpoint in Cloudflare next
      // final response = await _dio.get('$baseUrl/admin/stats');
      
      // Mocking the delay for now until the backend is ready
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _totalUsers = 142;
        _totalAdmins = 4;
        _totalVideos = 89;
        _totalViews = 12450;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      setState(() => _isLoading = false);
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
                Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600)),
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blueGrey[900]))
          : RefreshIndicator(
              onRefresh: _fetchPlatformStats,
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
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
                      _buildStatCard('Total Users', _totalUsers.toString(), Icons.people_outline, Colors.blue),
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