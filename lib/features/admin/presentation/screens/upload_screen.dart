import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({
    super.key,
  }); // FIX: Added named key parameter. This fixes the admin_main_screen error!

  @override
  State createState() => _UploadScreenState(); // FIX: Removed private type warning
}

class _UploadScreenState extends State {
  // FIX: Added
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  File? _selectedFile;
  double _uploadProgress = 0.0;
  String _statusMessage = 'Ready to upload';
  bool _isUploading = false;

 Future pickVideo() async {
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

  Future startUpload() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _statusMessage = 'Requesting secure upload link...';
    });

    try {
      String? adminId = await _storage.read(key: 'user_id');
      String fileName = _selectedFile!.path.split('/').last;

      // Replace with your computer's actual local IP address (e.g., 192.168.1.X)
      final String apiUrl = 'http://127.0.0.1:8787/videos/upload-init';

      final initResponse = await _dio.post(
        apiUrl,
        data: {
          'title': 'New Video Upload',
          'description': 'Uploaded via Admin App',
          'originalFilename': fileName,
          'mimeType': 'video/mp4',
          'adminId': adminId ?? '0acc5266-ebfc-4f9d-9368-8d29cbfcb4df',
        },
      );

      String uploadUrl = initResponse.data['uploadUrl'];

      setState(() {
        _statusMessage = 'Uploading to Cloudflare R2...';
      });

      // STEP B: Upload the raw binary file directly to Cloudflare R2
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
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );

      setState(() {
        _statusMessage = 'Finalizing database record...';
      });

      // STEP C: Confirm completion with the backend
      // Note: Make sure this uses the same IP address variable you set earlier
      await _dio.post(
        'http://10.126.62.70:8787/videos/upload-complete', 
        data: {'videoId': initResponse.data['videoId']},
      );

      

      setState(() {
        _statusMessage = 'Upload Complete! Video is now READY.';
        _isUploading = false;
        _selectedFile = null;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Upload Failed: ${e.toString()}';
        _isUploading = false;
      });
      debugPrint(e.toString()); // FIX: Replaced print() with debugPrint()
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            if (_isUploading) ...[
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 12),
              Text('${(_uploadProgress * 100).toStringAsFixed(1)}%'),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
