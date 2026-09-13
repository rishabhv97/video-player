import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VideoDetailsScreen extends StatefulWidget {
  final String videoId; // ADDED: Need this to log history
  final String videoUrl;
  final String title;
  final String description;

  const VideoDetailsScreen({
    super.key,
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.description,
  });

  @override
  State<VideoDetailsScreen> createState() => _VideoDetailsScreenState();
}

class _VideoDetailsScreenState extends State<VideoDetailsScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _initPlayerAndLogHistory();
  }

  Future _initPlayerAndLogHistory() async {
    // 1. Initialize Player
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _controller.initialize();
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
    }

    // 2. Silently log to watch history
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId != null) {
        await _dio.post(
          '${dotenv.env['API_URL']}/history/log',
          data: {
            'userId': userId,
            'videoId': widget.videoId,
          },
        );
      }
    } catch (e) {
      debugPrint('Failed to log history: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true, 
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_controller),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                            child: Center(
                              child: Icon(
                                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 60,
                                color: Colors.white.withOpacity(_controller.value.isPlaying ? 0.0 : 0.8),
                              ),
                            ),
                          ),
                          VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: VideoProgressColors(
                              playedColor: Colors.blue[600]!,
                              bufferedColor: Colors.white38,
                              backgroundColor: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(child: CircularProgressIndicator(color: Colors.blue[400])),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}