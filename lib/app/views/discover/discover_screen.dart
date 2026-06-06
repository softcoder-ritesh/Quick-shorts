import 'package:flutter/material.dart';

/// Discover screen — a beautiful search and explore interface for trending content.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search creators, hashtags, music...',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Main Explore Content
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // Horizontal Categories
                  _buildCategoriesSection(),
                  const SizedBox(height: 24),

                  // Trending Sections
                  _buildTrendingSection(
                    context,
                    title: '#SummerVibes',
                    count: '1.2M posts',
                    imageUrls: [
                      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300',
                      'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=300',
                      'https://images.unsplash.com/photo-1506929562872-bb421503ef21?w=300',
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildTrendingSection(
                    context,
                    title: '#StreetFood',
                    count: '840K posts',
                    imageUrls: [
                      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=300',
                      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=300',
                      'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=300',
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildTrendingSection(
                    context,
                    title: '#FitnessLife',
                    count: '430K posts',
                    imageUrls: [
                      'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=300',
                      'https://images.unsplash.com/photo-1518310383802-640c2de311b2?w=300',
                      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300',
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'name': 'Trending', 'icon': Icons.trending_up, 'color': Colors.redAccent},
      {'name': 'Music', 'icon': Icons.music_note, 'color': Colors.blueAccent},
      {'name': 'Gaming', 'icon': Icons.sports_esports, 'color': Colors.purpleAccent},
      {'name': 'Sports', 'icon': Icons.sports_basketball, 'color': Colors.orangeAccent},
      {'name': 'Travel', 'icon': Icons.flight, 'color': Colors.greenAccent},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (cat['color'] as Color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (cat['color'] as Color).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 16),
                const SizedBox(width: 6),
                Text(
                  cat['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingSection(
    BuildContext context, {
    required String title,
    required String count,
    required List<String> imageUrls,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontally Scrolling Images
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(imageUrls[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
