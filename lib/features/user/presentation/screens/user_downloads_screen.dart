import 'package:flutter/material.dart';

class UserDownloadsScreen extends StatelessWidget {
  const UserDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Downloads',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_done, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No downloaded videos',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}