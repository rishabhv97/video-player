import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rubixplayer/shared/widgets/custom_app_bar.dart';
import 'dart:convert';

import '../../../../features/videos/presentation/screens/video_details_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class VideoItem {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String tag;
  final String duration;
  final int views;

  VideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.tag,
    required this.duration,
    required this.views,
  });

  factory VideoItem.fromJson(Map json) {
    int rawDuration = json['duration'] is int ? json['duration'] : int.tryParse(json['duration']?.toString() ?? '0') ?? 0;
    String fDuration = '00:00';
    if (rawDuration > 0) {
      int h = rawDuration ~/ 3600;
      int m = (rawDuration % 3600) ~/ 60;
      int s = rawDuration % 60;
      if (h > 0) {
        fDuration = '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      } else {
        fDuration = '$m:${s.toString().padLeft(2, '0')}';
      }
    }
    return VideoItem(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'],
      tag: json['tag'] ?? 'featured',
      duration: fDuration,
      views: json['views'] is int ? json['views'] : int.tryParse(json['views']?.toString() ?? '0') ?? 0,
    );
  }
}

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final Dio _dio = Dio();
  List<VideoItem> _videos = [];
  List<VideoItem> _filteredVideos = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  String _selectedPill = 'all';
  Map<String, dynamic>? _lastPlayed;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredVideos = List.from(_videos);
      });
      return;
    }

    String searchTarget = query.trim();

    if (searchTarget.contains('/watch/')) {
      final parts = searchTarget.split('/watch/');
      if (parts.length > 1) {
        searchTarget = parts.last.split('?').first.trim();
      }
    }

    setState(() {
      _filteredVideos = _videos.where((video) {
        if (video.id == searchTarget) return true;
        if (video.title.toLowerCase().contains(searchTarget.toLowerCase())) return true;
        if (video.description.toLowerCase().contains(searchTarget.toLowerCase())) return true;
        return false;
      }).toList();
    });
  }

  Future<void> _fetchFeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPlayedStr = prefs.getString('last_played_video');
      Map<String, dynamic>? lastPlayed;
      if (lastPlayedStr != null) {
        lastPlayed = jsonDecode(lastPlayedStr);
      }

      final response = await _dio.get('${dotenv.env['API_URL']}/videos');
      final List data = response.data;
      if (mounted) {
        setState(() {
          _videos = data.map((json) => VideoItem.fromJson(json)).toList();
          _filteredVideos = List.from(_videos);
          _lastPlayed = lastPlayed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load videos. Check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPill(String id, String text) {
    bool isSelected = _selectedPill == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPill = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFFF6B00) : Colors.grey[300]!),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  List<VideoItem> get _displayedVideos {
    if (_selectedPill == 'all') return _filteredVideos;
    return _filteredVideos.where((v) => v.tag.toLowerCase() == _selectedPill).toList();
  }

  String formatViews(int views) {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K';
    return views.toString();
  }

  String formatTag(String tag) {
    switch (tag) {
      case 'movies': return 'Movies';
      case 'viralvideo': return 'Viral Videos';
      case 'featured': return 'Featured';
      case 'shortvideo': return 'Shorts';
      default: return tag.toUpperCase();
    }
  }

  String _formatSeconds(int seconds) {
    if (seconds <= 0) return '00:00';
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildContinueWatching() {
    if (_lastPlayed == null) return const SizedBox.shrink();

    final id = _lastPlayed!['id'];
    final title = _lastPlayed!['title'];
    final videoUrl = _lastPlayed!['videoUrl'];
    final description = _lastPlayed!['description'];
    final position = _lastPlayed!['position'] as int;
    final duration = _lastPlayed!['duration'] as int;
    final progress = duration > 0 ? (position / duration) : 0.0;
    final percentage = (progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_arrow, color: Color(0xFFFF6B00), size: 20),
              const SizedBox(width: 8),
              const Text('Continue Watching', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const Spacer(),
              Text('1 in progress', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoDetailsScreen(
                    videoId: id,
                    videoUrl: videoUrl,
                    title: title,
                    description: description,
                  ),
                ),
              ).then((_) => _fetchFeed());
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          'https://picsum.photos/seed/$id/600/300',
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
                              ],
                            ),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('$percentage%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B00)),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatSeconds(position), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            Text(_formatSeconds(duration), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ],
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

  Widget _buildGridItem(BuildContext context, VideoItem video) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoDetailsScreen(
              videoId: video.id,
              videoUrl: video.videoUrl,
              title: video.title,
              description: video.description,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 11,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://picsum.photos/seed/${video.id}/400/300',
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(video.duration, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.2, color: Colors.black87),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(formatTag(video.tag), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                        ),
                        const Spacer(),
                        Text('${formatViews(video.views)} views', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
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
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        titleSpacing: 16,
        toolbarHeight: 70,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Rubix Player',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Color(0xFF1E1E2C),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'STREAM & LINKS',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: const Color(0xFFFF6B00),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.black87, size: 22),
              onPressed: () {
                setState(() {
                  _isSearchVisible = !_isSearchVisible;
                  if (!_isSearchVisible) {
                    _searchController.clear();
                    _onSearchChanged('');
                    FocusScope.of(context).unfocus();
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage('https://ui-avatars.com/api/?name=User&background=C7D2FE&color=3730A3&bold=true'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchVisible)
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search title or paste video link...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.orange[600]))
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.black87)))
                    : _filteredVideos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text('No videos found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchFeed,
                            child: CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                  SliverToBoxAdapter(
                                    child: _buildContinueWatching(),
                                  ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[100],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('NEW', style: TextStyle(color: Colors.orange[700], fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Latest Videos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        const Spacer(),
                                        Text('${_filteredVideos.length} videos', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16, bottom: 16),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _buildPill('all', 'All'),
                                          _buildPill('movies', 'Movies'),
                                          _buildPill('viralvideo', 'Viral Videos'),
                                          _buildPill('featured', 'Featured'),
                                          _buildPill('shortvideo', 'Shorts'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  sliver: SliverGrid(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.85,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final video = _displayedVideos[index];
                                        return _buildGridItem(context, video);
                                      },
                                      childCount: _displayedVideos.length,
                                    ),
                                  ),
                                ),
                                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}