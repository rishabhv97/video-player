import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class UsersManagementScreen extends StatelessWidget {
  const UsersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(),
      body: Center(child: Text('Users Management - Overview of Users')),
    );
  }
}
