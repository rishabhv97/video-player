import 'package:flutter/material.dart';
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

  Future _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        setState(() {
          _errorMessage = 'User not logged in.';
          _isLoading = false;
        });
        return;
      }

      // FIXED: Clean string interpolation with double quotes and $ symbols
      final response = await _dio.get("\(${dotenv.env['API_URL']}/history/\)userId");
      
      setState(() {
        _historyItems = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load history.';
        _isLoading = false;
      });
      debugPrint('History fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Watch History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue[600]))
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
                  : ListView.builder(
                      itemCount: _historyItems.length,
                      itemBuilder: (context, index) {
                        final video = _historyItems[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 80,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.play_circle_fill, color: Colors.blue[600]),
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
    );
  }
}