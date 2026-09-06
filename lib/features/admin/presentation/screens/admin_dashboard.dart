import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(),
      body: Center(child: Text('Admin Dashboard - Statistics & Overview')),
    );
  }
}
