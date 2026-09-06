import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class MyVideosScreen extends StatelessWidget {
  const MyVideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(),
      body: Center(child: Text('My Videos - Manage Uploaded Content')),
    );
  }
}
