import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoDetailsScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;

  const VideoDetailsScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.description,
  });

  @override
  // Pass the variables directly to the state
  State createState() => _VideoDetailsScreenState(videoUrl, title, description);
}

class _VideoDetailsScreenState extends State {
  // Local variables to bypass the 'widget.' requirement
  final String localVideoUrl;
  final String localTitle;
  final String localDescription;

  late VideoPlayerController _controller;
  bool _isInitialized = false;

  // Constructor receives the variables
  _VideoDetailsScreenState(this.localVideoUrl, this.localTitle, this.localDescription);

  @override
  void initState() {
    super.initState();
    // Use the local variable here
    _controller = VideoPlayerController.networkUrl(Uri.parse(localVideoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        // Auto-play when opened in full screen
        _controller.play(); 
      });
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
      // Transparent AppBar overlay for an immersive look
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true, 
      body: Column(
        children: [
          // Player Section
          Expanded(
            child: Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_controller),
                          // Play/Pause Tap Area
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
                                // Hide icon if playing, show if paused
                                color: Colors.white.withOpacity(_controller.value.isPlaying ? 0.0 : 0.7),
                              ),
                            ),
                          ),
                          // Video Scrubber / Progress Bar
                          VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Colors.blue,
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator(color: Colors.blue),
            ),
          ),
          // Details Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localTitle, // Use local variable
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localDescription, // Use local variable
                    style: TextStyle(
                      color: Colors.grey[400],
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