import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quick_shorts/app/controllers/main_layout_controller.dart';
import 'package:quick_shorts/app/routes/app_routes.dart';
import 'package:quick_shorts/app/views/home/home_screen.dart';
import 'package:quick_shorts/app/views/discover/discover_screen.dart';
import 'package:quick_shorts/app/views/inbox/inbox_screen.dart';
import 'package:quick_shorts/app/views/profile/profile_screen.dart';

/// The root shell layout of the application containing the custom Bottom Navigation Bar.
class MainLayoutScreen extends StatelessWidget {
  const MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MainLayoutController controller = Get.find<MainLayoutController>();

    final List<Widget> screens = [
      const HomeScreen(),
      const DiscoverScreen(),
      const SizedBox.shrink(), // Placeholder for Upload (opens as full modal route)
      const InboxScreen(),
      const ProfileScreen(),
    ];

    return Obx(() {
      final currentTab = controller.activeTab.value;

      return Scaffold(
        backgroundColor: Colors.black,
        // Allows the body to render underneath the bottom navigation bar
        extendBody: true,
        body: IndexedStack(
          index: currentTab,
          children: screens,
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context, controller, currentTab),
      );
    });
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    MainLayoutController controller,
    int currentTab,
  ) {
    // When on the Home (Reels Feed) tab, use a transparent blur overlay.
    // On other screens, use a solid dark background.
    final isHome = currentTab == 0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: isHome ? 12 : 0, sigmaY: isHome ? 12 : 0),
        child: Container(
          height: 60 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: isHome
                ? Colors.black.withValues(alpha: 0.4) // Transparent overlay on feed
                : const Color(0xFF0C0C0E), // Solid dark on other tabs
            border: Border(
              top: BorderSide(
                color: isHome
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: Icons.home_filled,
                label: 'Home',
                isSelected: currentTab == 0,
                onTap: () => controller.changeTab(0),
              ),
              _buildNavItem(
                icon: Icons.explore_rounded,
                label: 'Discover',
                isSelected: currentTab == 1,
                onTap: () => controller.changeTab(1),
              ),
              // Central Upload "+" Button
              _buildUploadButton(),
              _buildNavItem(
                icon: Icons.inbox_rounded,
                label: 'Inbox',
                isSelected: currentTab == 3,
                onTap: () => controller.changeTab(3),
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: currentTab == 4,
                onTap: () => controller.changeTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white38,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Expanded(
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.upload),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 44,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Cyan background offset left
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F2FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // Pink background offset right
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  left: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF007F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // Center white overlay with plus icon (creates the TikTok style overlapping look)
                Positioned.fill(
                  left: 2,
                  right: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        color: Colors.black,
                        size: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
