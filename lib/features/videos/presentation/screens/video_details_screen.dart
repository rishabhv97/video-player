import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

class VideoDetailsScreen extends StatefulWidget {
  final String videoId;
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

  // Download State Variables
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initPlayerAndLogHistory();
  }

  Future<void> _initPlayerAndLogHistory() async {
    // 1. Initialize Player
    if (widget.videoUrl.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
    } else {
      _controller = VideoPlayerController.file(File(widget.videoUrl));
    }

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
          data: {'userId': userId, 'videoId': widget.videoId},
        );
      }
    } catch (e) {
      debugPrint('Failed to log history: $e');
    }
  }

  // --- DOWNLOAD LOGIC ---
  Future<void> _downloadVideo() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // 1. Get the app's secure local document directory
      final appDir = await getApplicationDocumentsDirectory();

      // Correct Dart string interpolation
      final filePath = '${appDir.path}/${widget.videoId}.mp4';

      // 2. Download file using Dio
      await _dio.download(
        widget.videoUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      // 3. Save metadata to SharedPreferences
      // so the Downloads screen can find it
      final prefs = await SharedPreferences.getInstance();

      final String? existingData = prefs.getString('downloaded_videos');

      List<dynamic> downloads = existingData != null
          ? jsonDecode(existingData)
          : [];

      // Remove older entry if re-downloading the same video
      downloads.removeWhere((item) => item['id'] == widget.videoId);

      downloads.add({
        'id': widget.videoId,
        'title': widget.title,
        'description': widget.description,
        'localPath': filePath,
        'downloadedAt': DateTime.now().toIso8601String(),
      });

      await prefs.setString('downloaded_videos', jsonEncode(downloads));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download complete! Available offline.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
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
                                _controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: 60,
                                color: Colors.white.withOpacity(
                                  _controller.value.isPlaying ? 0.0 : 0.8,
                                ),
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
                  : Center(
                      child: CircularProgressIndicator(color: Colors.blue[400]),
                    ),
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

                  const SizedBox(height: 24),

                  // --- DOWNLOAD UI COMPONENT ---
                  _isDownloading
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: _downloadProgress,
                              color: Colors.blue[600],
                              backgroundColor: Colors.grey[200],
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Downloading: '
                              '${(_downloadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,

                          child: ElevatedButton.icon(
                            onPressed: _downloadVideo,

                            icon: const Icon(Icons.download_rounded),

                            label: const Text('Download for Offline'),

                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),

                              backgroundColor: Colors.blue[600],

                              foregroundColor: Colors.white,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
