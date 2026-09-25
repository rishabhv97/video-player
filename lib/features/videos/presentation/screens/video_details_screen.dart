import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemChrome (Fullscreen)
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

  // Player UI State
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isDescriptionExpanded = false;
  bool _isFullscreen = false; // Added for fullscreen state

  // Visual feedback for double tap
  bool _showRewind = false;
  bool _showForward = false;

  @override
  void initState() {
    super.initState();
    _initPlayerAndLogHistory();
  }

  Future<void> _initPlayerAndLogHistory() async {
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
      _startHideControlsTimer();
    }
    
    _controller.addListener(() {
      if (mounted) setState(() {});
    });

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

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying && !_showRewind && !_showForward) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _seekRelative(Duration duration) {
    final newPosition = _controller.value.position + duration;
    _controller.seekTo(newPosition);
    if (!_showControls) {
      _toggleControls();
    } else {
      _startHideControlsTimer();
    }
  }

  Future<void> _triggerRewindFeedback() async {
    setState(() => _showRewind = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showRewind = false);
  }

  Future<void> _triggerForwardFeedback() async {
    setState(() => _showForward = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showForward = false);
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _downloadVideo() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/${widget.videoId}.mp4';

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

      final prefs = await SharedPreferences.getInstance();
      final String? existingData = prefs.getString('downloaded_videos');
      List<dynamic> downloads = existingData != null
          ? jsonDecode(existingData)
          : [];

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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _hideControlsTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget playerWidget = Center(
      child: _isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  
                  // Tap detectors for skip & toggle controls
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _toggleControls,
                            onDoubleTap: () {
                              _seekRelative(const Duration(seconds: -10));
                              _triggerRewindFeedback();
                            },
                            child: AnimatedOpacity(
                              opacity: _showRewind ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.black54, Colors.transparent],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.fast_rewind, color: Colors.white, size: 48),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _toggleControls,
                            onDoubleTap: () {
                              _seekRelative(const Duration(seconds: 10));
                              _triggerForwardFeedback();
                            },
                            child: AnimatedOpacity(
                              opacity: _showForward ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, Colors.black54],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.fast_forward, color: Colors.white, size: 48),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center Play/Pause button
                  AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _controller.value.isPlaying ? _controller.pause() : _controller.play();
                            _startHideControlsTimer();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Control Bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black87],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                GestureDetector(
                                  onTap: _toggleFullscreen,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: Theme.of(context).colorScheme.primary,
                                bufferedColor: Colors.white38,
                                backgroundColor: Colors.white24,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            ),
    );

    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: playerWidget),
      );
    }

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
          Expanded(child: playerWidget),

          // Details Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                )
              ]
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle pill
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title and Compact Download Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _isDownloading
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    value: _downloadProgress,
                                    color: Theme.of(context).colorScheme.primary,
                                    backgroundColor: Colors.grey[200],
                                  ),
                                ),
                                Text(
                                  '${(_downloadProgress * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : IconButton.filledTonal(
                              onPressed: _downloadVideo,
                              icon: const Icon(Icons.download_rounded),
                              tooltip: 'Download Video',
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Expandable Description
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    child: AnimatedCrossFade(
                      firstChild: Text(
                        widget.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      secondChild: Text(
                        widget.description,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      crossFadeState: _isDescriptionExpanded 
                          ? CrossFadeState.showSecond 
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ),
                  
                  if (widget.description.length > 100) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Text(
                        _isDescriptionExpanded ? "Show less" : "Read more",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
