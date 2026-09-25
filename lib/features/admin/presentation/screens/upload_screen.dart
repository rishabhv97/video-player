import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  File? _selectedFile;
  double _uploadProgress = 0.0;
  String _statusMessage = 'Ready to upload';
  bool _isUploading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _statusMessage = 'Selected: ${result.files.single.name}';
      });
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
      String? adminId = await _storage.read(key: 'user_id');
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
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Upload Failed: ${e.toString()}';
        _isUploading = false;
      });
      debugPrint(e.toString()); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
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
