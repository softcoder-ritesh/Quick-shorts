import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:quick_shorts/app/controllers/reel_controller.dart';
import 'package:quick_shorts/app/controllers/main_layout_controller.dart';

/// Profile screen — shows user stats, details, and their uploaded reels grid.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ReelController reelController = Get.find<ReelController>();
    final MainLayoutController layoutController = Get.find<MainLayoutController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'quick_creator',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header Info
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                // User Avatar
                const CircleAvatar(
                  radius: 46,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                  ),
                ),
                const SizedBox(height: 12),
                // Display Name
                const Text(
                  '@quick_creator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Stats row (Following, Followers, Likes)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatItem('142', 'Following'),
                    _buildDivider(),
                    _buildStatItem('1.2K', 'Followers'),
                    _buildDivider(),
                    _buildStatItem('24.5K', 'Likes'),
                  ],
                ),
                const SizedBox(height: 20),

                // Edit Profile Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Bio
                const Text(
                  'Creating beautiful moments 🎥 | Flutter Developer',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Tabs Divider
          const Divider(color: Colors.white12, height: 1),

          // Profile Video Grid View
          Expanded(
            child: Obx(() {
              // Filter the reels feed to find all videos uploaded by this user
              final userReels = reelController.reels
                  .where((reel) => reel.username == 'quick_creator')
                  .toList();

              if (userReels.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_camera_back_outlined,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Share your first video',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                itemCount: userReels.length,
                padding: const EdgeInsets.all(2),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 3 / 4,
                ),
                itemBuilder: (context, index) {
                  final reel = userReels[index];
                  final isNetwork = reel.thumbnailUrl.startsWith('http://') ||
                      reel.thumbnailUrl.startsWith('https://');

                  return GestureDetector(
                    onTap: () {
                      Get.bottomSheet(
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.play_circle_outline_rounded, color: Colors.white),
                                title: const Text('Watch Reel', style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  Get.back(); // close bottom sheet
                                  final originalIndex = reelController.reels.indexOf(reel);
                                  if (originalIndex != -1) {
                                    layoutController.changeTab(0);
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      reelController.pageController?.jumpToPage(originalIndex);
                                    });
                                  }
                                },
                              ),
                              const Divider(color: Colors.white10),
                              ListTile(
                                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                title: const Text('Delete Reel', style: TextStyle(color: Colors.redAccent)),
                                onTap: () {
                                  Get.back(); // close bottom sheet
                                  // Show confirmation dialog
                                  Get.dialog(
                                    AlertDialog(
                                      backgroundColor: Colors.grey[900],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: const BorderSide(color: Colors.white10),
                                      ),
                                      title: const Text(
                                        'Delete Reel?',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      content: const Text(
                                        'Are you sure you want to delete this Reel? This action cannot be undone.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(),
                                          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Get.back(); // close dialog
                                            reelController.deleteReel(reel.id);
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.grey.shade900,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          isNetwork
                              ? CachedNetworkImage(
                                  imageUrl: reel.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: Colors.grey.shade900),
                                  errorWidget: (_, __, ___) => Container(color: Colors.grey.shade900),
                                )
                              : Image.file(
                                  File(reel.thumbnailUrl),
                                  fit: BoxFit.cover,
                                ),
                          // Small play icon overlay at the bottom left
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Row(
                              children: [
                                const Icon(Icons.play_arrow_outlined, color: Colors.white, size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  reel.likes > 0 ? '${reel.likes}' : '0',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 12,
      color: Colors.white12,
    );
  }
}
