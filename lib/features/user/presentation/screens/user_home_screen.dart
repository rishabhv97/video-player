import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLinkDetectedBanner(),
            const SizedBox(height: 16),
            _buildWatchVideoCard(),
            const SizedBox(height: 24),
            _buildContinueWatchingSection(),
            const SizedBox(height: 24),
            _buildTrendingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkDetectedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E2F5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.content_paste_rounded, color: Colors.brown, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Video link detected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('https://example.com/v/1aB2c3D4...', style: TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C44CF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Paste & Watch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.close, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildWatchVideoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link, color: Colors.grey),
              SizedBox(width: 8),
              Text('Watch Video from a Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Paste a supported video link to watch it instantly.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('Watch free • Download with Premium', style: TextStyle(color: Color(0xFF4C44CF), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Paste your video link here...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.content_paste, size: 16, color: Color(0xFF4C44CF)),
                  label: const Text('Paste', style: TextStyle(color: Color(0xFF4C44CF))),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F0FA),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFF5),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, color: Colors.grey, size: 20),
                SizedBox(width: 4),
                Text('Watch Video', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueWatchingSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.play_arrow, color: Color(0xFF4C44CF), size: 20),
                SizedBox(width: 8),
                Text('Continue Watching', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('1 in progress', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF4C44CF)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4C44CF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                      child: const Text('72%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ocean Mystery: Depths of the Aby...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.72,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF4C44CF),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('18:42', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text('30:45', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text('Trending', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('Top Hits', style: TextStyle(color: Color(0xFF4C44CF), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTrendingCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildTrendingCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendingCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade700,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 40),
      ),
    );
  }
}
