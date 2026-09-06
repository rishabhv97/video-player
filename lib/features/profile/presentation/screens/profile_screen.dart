import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(showSearch: false),
      body: Center(
        child: Text('Profile Settings Coming Soon'),
      ),
    );
  }
}
