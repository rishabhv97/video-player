import 'package:flutter/material.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Uploads'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildUploadItem('vacation.mp4', 0.45),
          const SizedBox(height: 16),
          _buildUploadItem('meeting_recording.mp4', 0.8),
        ],
      ),
    );
  }

  Widget _buildUploadItem(String fileName, double progress) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${(progress * 100).toInt()}%'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Pause'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
