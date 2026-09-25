import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rubixplayer/shared/widgets/custom_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../features/videos/presentation/screens/video_details_screen.dart';

class UserDownloadsScreen extends StatefulWidget {
  const UserDownloadsScreen({super.key});

  @override
  State createState() => _UserDownloadsScreenState();
}

class _UserDownloadsScreenState extends State {
  List _downloadedVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future _loadDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('downloaded_videos');
    
    setState(() {
      _downloadedVideos = data != null ? jsonDecode(data) : [];
      _isLoading = false;
    });
  }

  Future _deleteVideo(String id, String localPath) async {
    try {
      // 1. Delete physical file from device
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }

      // 2. Remove from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _downloadedVideos.removeWhere((item) => item['id'] == id);
      await prefs.setString('downloaded_videos', jsonEncode(_downloadedVideos));

      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video deleted from device')),
        );
      }
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: RubixAppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange[600]))
          : _downloadedVideos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_done_rounded, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No offline videos', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDownloads,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _downloadedVideos.length,
                    itemBuilder: (context, index) {
                      final video = _downloadedVideos[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 80,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.offline_pin_rounded, color: Colors.orange[600]),
                        ),
                        title: Text(video['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Available offline'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteVideo(video['id'], video['localPath']),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoDetailsScreen(
                                videoId: video['id'],
                                videoUrl: video['localPath'], // We pass the LOCAL path here!
                                title: video['title'],
                                description: video['description'],
                              ),
                            ),
                          ).then((_) => _loadDownloads()); // Refresh after returning
                        },
                      );
                    },
                  ),
                ),
    );
  }
}