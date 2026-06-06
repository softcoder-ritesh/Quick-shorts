import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quick_shorts/app/controllers/reel_controller.dart';
import 'package:quick_shorts/app/views/widgets/reel_player_widget.dart';
import 'package:quick_shorts/app/views/widgets/shimmer_loading_widget.dart';

/// The main screen — a full-screen vertical PageView of reels.
///
/// This is the TikTok/Instagram Reels experience: swipe up/down to
/// navigate between videos, each snapping into place. The PageView
/// handles the snap physics automatically — we just provide the items.
///
/// System chrome (status bar, navigation bar) is hidden to give the
/// immersive full-screen experience. We restore it when the user
/// leaves this screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ReelController _controller = Get.find<ReelController>();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _controller.pageController = _pageController;

    // Hide system UI for immersive full-screen experience.
    // This removes the status bar and navigation bar so videos
    // use every pixel of the screen — just like TikTok.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Force portrait orientation — reels are vertical content and
    // landscape mode would look wrong with the vertical PageView.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _controller.pageController = null;
    _pageController.dispose();
    // Restore system UI when leaving the reels screen so other
    // screens in the app (if any) behave normally.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Pure black background — matches the video player background
      // and prevents any white flash during page transitions.
      backgroundColor: Colors.black,
      // No app bar — we draw our own "For You / Following" tabs
      // in the overlay widget.
      body: Obx(() {
        // Show shimmer loading during the initial Firestore fetch
        if (_controller.isLoading.value) {
          return const ShimmerLoadingWidget();
        }

        // If we loaded but got zero reels (empty Firestore collection),
        // show a friendly message instead of a blank black screen.
        if (_controller.reels.isEmpty) {
          return _buildEmptyState();
        }

        // The main PageView — each page is a full-screen reel
        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await _controller.fetchReels();
          },
          color: const Color(0xFFFF2D55),
          backgroundColor: Colors.black,
          strokeWidth: 3,
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _controller.reels.length,
            onPageChanged: (index) {
              _controller.onPageChanged(index);
            },
            // Use BouncingScrollPhysics to allow overscroll for the refresh indicator
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            itemBuilder: (context, index) {
              final reel = _controller.reels[index];
              return ReelPlayerWidget(
                reel: reel,
                index: index,
              );
            },
          ),
        );
      }),
    );
  }

  /// Empty state shown when the Firestore "reels" collection has no documents.
  /// This tells the user clearly what's going on instead of showing a blank screen.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.video_library_outlined,
            color: Colors.white.withValues(alpha: 0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No reels yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some videos to the "reels" collection\nin your Firestore database.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _controller.fetchReels(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
