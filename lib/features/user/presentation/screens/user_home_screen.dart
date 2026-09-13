import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';

import '../../../../features/videos/presentation/screens/video_details_screen.dart';

class VideoItem {
  final String id;
  final String title;
  final String description;
  final String videoUrl;

  VideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
  });

  factory VideoItem.fromJson(Map json) {
    return VideoItem(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'],
    );
  }
}

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State {
  final Dio _dio = Dio();
  List _videos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future _fetchFeed() async {
    try {
      // IMPORTANT: Update this IP to your current hotspot IP!
      final response = await _dio.get('http://10.126.62.70:8787/videos');
      final List data = response.data;
      setState(() {
        _videos = data.map((json) => VideoItem.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load videos. Check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Very light off-white background
      appBar: AppBar(
        title: Text(
          'Discover',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue[600]))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.black87)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Icon(Icons.person, color: Colors.blue[700]),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    video.title,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Video Player
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: FeedVideoPlayer(videoUrl: video.videoUrl),
                          ),
                          
                          // Details (Tappable)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoDetailsScreen(
                                    videoUrl: video.videoUrl,
                                    title: video.title,
                                    description: video.description,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.all(16.0),
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    video.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Read more',
                                    style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const FeedVideoPlayer({super.key, required this.videoUrl});

  @override
  State createState() => _FeedVideoPlayerState(videoUrl);
}

class _FeedVideoPlayerState extends State {
  final String localVideoUrl;
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  _FeedVideoPlayerState(this.localVideoUrl);

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(localVideoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.grey[200],
        child: Center(child: CircularProgressIndicator(color: Colors.blue[400])),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          if (!_controller.value.isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.play_arrow, size: 40, color: Colors.blue[800]),
            ),
        ],
      ),
    );
  }
}