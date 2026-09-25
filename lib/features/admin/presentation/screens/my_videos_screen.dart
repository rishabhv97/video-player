import 'package:flutter/material.dart';
import 'package:rubixplayer/shared/widgets/custom_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class MyVideosScreen extends StatefulWidget {
  const MyVideosScreen({super.key});

  @override
  State<MyVideosScreen> createState() => _MyVideosScreenState();
}

class _MyVideosScreenState extends State<MyVideosScreen> {
  final Dio _dio = Dio();
  List<VideoItem> _videos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId =
          prefs.getString('id') ??
          prefs.getString('userId') ??
          prefs.getString('user_id') ??
          '';

      if (userId.isEmpty) {
        setState(() {
          _errorMessage = 'No Admin ID found. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      String baseUrl = dotenv.env['API_URL'] ?? '';
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final response = await _dio.get('$baseUrl/videos?userId=$userId');
      final List data = response.data;

      setState(() {
        _videos = data.map((json) => VideoItem.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load feed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteVideo(String videoId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video?'),
        content: const Text(
          'This will permanently delete the file from storage and wipe its watch history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      String baseUrl = dotenv.env['API_URL'] ?? '';
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      await _dio.delete('$baseUrl/videos/$videoId');

      setState(() {
        _videos.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video permanently deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareVideo(String videoId) {
    String baseUrl = dotenv.env['API_URL'] ?? '';
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    final shareLink = '$baseUrl/watch/$videoId';
    Clipboard.setData(ClipboardData(text: shareLink));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Share link copied to clipboard!'),
          backgroundColor: Colors.orange[600],
        ),
      );
    }
  }

  Future<void> _showEditDialog(VideoItem video, int index) async {
    final titleController = TextEditingController(text: video.title);
    final descController = TextEditingController(text: video.description);
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Video Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description'),
                      enabled: !isSaving,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty) return;

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            String baseUrl = dotenv.env['API_URL'] ?? '';
                            if (baseUrl.endsWith('/')) {
                              baseUrl = baseUrl.substring(0, baseUrl.length - 1);
                            }

                            await _dio.patch(
                              '$baseUrl/videos/${video.id}',
                              data: {
                                'title': titleController.text.trim(),
                                'description': descController.text.trim(),
                              },
                            );

                            setState(() {
                              _videos[index] = VideoItem(
                                id: video.id,
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                videoUrl: video.videoUrl,
                              );
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Video updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(body: Center(child: Text(_errorMessage)));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: RubixAppBar(),
      body: _videos.isEmpty
          ? const Center(child: Text('You have no uploaded videos.'))
          : RefreshIndicator(
              onRefresh: _fetchVideos,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _videos.length,
                itemBuilder: (context, index) {
                  final video = _videos[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: VideoPlayerWidget(videoUrl: video.videoUrl),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      video.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      video.description,
                                      style: TextStyle(color: Colors.grey[700]),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share, color: Colors.orange),
                                    onPressed: () => _shareVideo(video.id),
                                    tooltip: 'Copy Link',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.orange[700]),
                                    onPressed: () => _showEditDialog(video, index),
                                    tooltip: 'Edit Video',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteVideo(video.id, index),
                                    tooltip: 'Delete Video',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
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
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        VideoPlayer(_controller),
        IconButton(
          icon: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            size: 50,
            color: Colors.white.withOpacity(0.8),
          ),
          onPressed: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            });
          },
        ),
      ],
    );
  }
}