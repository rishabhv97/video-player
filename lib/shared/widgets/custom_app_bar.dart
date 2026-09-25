import 'package:flutter/material.dart';
import 'package:rubixplayer/features/profile/presentation/screens/profile_screen.dart';

class RubixAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final bool showProfile;

  RubixAppBar({
    super.key,
    this.actions,
    this.showProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.grey[50],
      elevation: 0,
      titleSpacing: 16,
      toolbarHeight: 70,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Rubix Player',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Color(0xFF1E1E2C),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'STREAM & LINKS',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: const Color(0xFFFF6B00),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (actions != null) ...actions!,
        if (actions != null && actions!.isNotEmpty) const SizedBox(width: 12),
        if (showProfile)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage('https://ui-avatars.com/api/?name=User&background=C7D2FE&color=3730A3&bold=true'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70.0);
}