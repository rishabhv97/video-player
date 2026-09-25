import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rubixplayer/shared/widgets/custom_app_bar.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({
    super.key,
  }); 

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final Dio _dio = Dio();


  File? _selectedFile;
  double _uploadProgress = 0.0;
  String _statusMessage = 'Ready to upload';
  bool _isUploading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  int _extractedDuration = 0;
  String _selectedTag = 'movies';
  final List<String> _tags = ['movies', 'viralvideo', 'featured', 'shortvideo'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      
      setState(() {
        _selectedFile = file;
        _statusMessage = 'Extracting video metadata...';
      });

      try {
        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        final duration = controller.value.duration;
        
        String formattedDuration = '';
        if (duration.inHours > 0) {
          formattedDuration = '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
        } else {
          formattedDuration = '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
        }
        
        _durationController.text = formattedDuration;
        _extractedDuration = duration.inSeconds;
        await controller.dispose();

        setState(() {
          _statusMessage = 'Selected: ${result.files.single.name}';
        });
      } catch (e) {
        setState(() {
          _statusMessage = 'Selected: ${result.files.single.name} (Could not read duration)';
        });
      }
    }
  }

  Future<void> startUpload() async {
    if (_selectedFile == null) return;

    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a video title first.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _statusMessage = 'Requesting secure upload link...';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? adminId = prefs.getString('user_id');
      String fileName = _selectedFile!.path.split('/').last;

      final String apiUrl = '${dotenv.env['API_URL']}/videos/upload-init';

      final initResponse = await _dio.post(
        apiUrl,
        data: {
          'title': _titleController.text.trim(),
          'description': _descController.text.trim().isEmpty ? 'No description provided.' : _descController.text.trim(),
          'originalFilename': fileName,
          'mimeType': 'video/mp4',
          'adminId': adminId ?? '0acc5266-ebfc-4f9d-9368-8d29cbfcb4df',
          'tag': _selectedTag,
          'duration': _extractedDuration,
        },
      );

      String uploadUrl = initResponse.data['uploadUrl'];

      setState(() {
        _statusMessage = 'Uploading to Cloudflare R2...';
      });

      await _dio.put(
        uploadUrl,
        data: _selectedFile!.openRead(), 
        options: Options(
          headers: {
            Headers.contentLengthHeader: _selectedFile!.lengthSync(),
            'Content-Type': 'video/mp4', 
          },
        ),
        onSendProgress: (int sent, int total) {
          if (total != -1) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );

      setState(() {
        _statusMessage = 'Finalizing database record...';
      });

      await _dio.post(
        '${dotenv.env['API_URL']}/videos/upload-complete', 
        data: {'videoId': initResponse.data['videoId']},
      );

      setState(() {
        _statusMessage = 'Upload Complete! Video is now READY.';
        _isUploading = false;
        _selectedFile = null;
        _titleController.clear();
        _descController.clear();
        _durationController.clear();
        _extractedDuration = 0;
      });
    } on DioException catch (e) {
      setState(() {
        var err = e.response?.data;
        if (err is Map) err = err['message'] ?? err.toString();
        _statusMessage = 'Upload Failed: $err';
        _isUploading = false;
      });
      debugPrint('Dio Error: ${e.response?.data}');
    } catch (e) {
      setState(() {
        _statusMessage = 'Upload Failed: $e';
        _isUploading = false;
      });
      debugPrint(e.toString()); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RubixAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Video Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                enabled: !_isUploading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Video Description (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                enabled: !_isUploading,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedTag,
                      decoration: const InputDecoration(
                        labelText: 'Category Tag',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _tags.map((String tag) {
                        return DropdownMenuItem<String>(
                          value: tag,
                          child: Text(tag.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: _isUploading
                          ? null
                          : (String? newValue) {
                              setState(() {
                                _selectedTag = newValue!;
                              });
                            },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (e.g. 10:30)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                      enabled: !_isUploading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              if (_isUploading) ...[
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 12),
                Text(
                  '${(_uploadProgress * 100).toStringAsFixed(1)}%',
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.video_file),
                  label: const Text('Select Video'),
                  onPressed: pickVideo,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Start Upload'),
                  onPressed: _selectedFile == null ? null : startUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
