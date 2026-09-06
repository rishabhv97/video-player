class VideoModel {
  final String id;
  final String title;
  final String url;
  final String thumbnailUrl;
  final double progress;
  final String duration;
  final String status;

  const VideoModel({
    required this.id,
    required this.title,
    required this.url,
    required this.thumbnailUrl,
    this.progress = 0.0,
    required this.duration,
    required this.status,
  });
}
