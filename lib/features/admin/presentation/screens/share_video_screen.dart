import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class ShareVideoScreen extends StatelessWidget {
  const ShareVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(),
      body: Center(child: Text('Share Video - Generate Links')),
    );
  }
}
