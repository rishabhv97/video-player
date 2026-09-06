import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class ManageAdminsScreen extends StatelessWidget {
  const ManageAdminsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(),
      body: Center(child: Text('Manage Admins - Enable/Disable')),
    );
  }
}
