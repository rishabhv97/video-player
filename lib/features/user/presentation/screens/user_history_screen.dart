import 'package:flutter/material.dart';
import 'package:rubixplayer/shared/widgets/custom_app_bar.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../features/videos/presentation/screens/video_details_screen.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  State createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State {
  final Dio _dio = Dio();
  List _historyItems = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId =
          prefs.getString('id') ??
          prefs.getString('userId') ??
          prefs.getString('user_id') ??
          '';

      if (userId.isEmpty) {
        final String? existingData = prefs.getString('guest_history');
        setState(() {
          _historyItems = existingData != null ? jsonDecode(existingData) : [];
          _isLoading = false;
        });
        return;
      }

      String baseUrl = dotenv.env['API_URL'] ?? '';
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final url = "$baseUrl/history/$userId";
      
      final response = await _dio.get(url);
      
      setState(() {
        _historyItems = (response.data as List).take(15).toList();
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        if (e.response != null) {
          _errorMessage = 'Server Error (${e.response?.statusCode}): ${e.response?.data}';
        } else {
          _errorMessage = 'Network Error: Cannot reach server.';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'App Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: RubixAppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange[600]))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _historyItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No history yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchHistory,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _historyItems.length,
                        itemBuilder: (context, index) {
                          final video = _historyItems[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 80,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.play_circle_fill, color: Colors.orange[600]),
                            ),
                            title: Text(video['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Tap to rewatch'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoDetailsScreen(
                                    videoId: video['id'],
                                    videoUrl: video['videoUrl'],
                                    title: video['title'],
                                    description: video['description'],
                                  ),
                                ),
                              ).then((_) => _fetchHistory());
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}