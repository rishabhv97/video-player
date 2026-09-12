import 'package:flutter/material.dart';

// Import the screens that will act as our tabs
import 'user_home_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State {
  int _selectedIndex = 0;

  // The list of screens that the bottom nav will switch between
  final List _screens = [
    const UserHomeScreen(),
    const ProfileScreen(), // We will build this fully in the next step
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}