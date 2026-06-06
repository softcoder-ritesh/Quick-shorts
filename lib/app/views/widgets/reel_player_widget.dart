import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:quick_shorts/app/controllers/reel_controller.dart';
import 'package:quick_shorts/app/models/video_model.dart';
import 'package:quick_shorts/app/services/preload_service.dart';
import 'package:quick_shorts/app/views/widgets/like_animation_widget.dart';
import 'package:quick_shorts/app/views/widgets/video_overlay_widget.dart';
import 'package:quick_shorts/app/views/widgets/video_progress_bar.dart';

/// The main per-video widget that handles the full lifecycle of displaying
/// a single reel: thumbnail → loading → video playback → overlay.
///
/// Each instance of this widget lives inside a page of the PageView.
/// It wraps everything in a VisibilityDetector to auto-play/pause based
/// on how much of the video is visible on screen.
///
/// The layering from bottom to top:
///   1. Blurred thumbnail (always present as a backdrop)
///   2. Video player (fades in once initialized)
///   3. Tap gesture detector (double-tap to like, single-tap to pause)
///   4. Like animation overlay (shown on double-tap)
///   5. Video metadata overlay (username, actions, progress bar)
///   6. Buffering indicator (only when actually buffering)
///   7. Error/retry state (replaces everything if initialization fails)
class ReelPlayerWidget extends StatefulWidget {
  final VideoModel reel;
  final int index;

  const ReelPlayerWidget({
    super.key,
    required this.reel,
    required this.index,
  });

  @override
  State<ReelPlayerWidget> createState() => _ReelPlayerWidgetState();
}

class _ReelPlayerWidgetState extends State<ReelPlayerWidget> {
  final ReelController _reelController = Get.find<ReelController>();
  final PreloadService _preloadService = Get.find<PreloadService>();

  /// Tracks the double-tap-to-like animation widgets currently on screen.
  /// We use a list (not a single bool) because the user might double-tap
  /// rapidly, and we want each tap to spawn its own flying heart.
  final List<Widget> _likeAnimations = [];

  /// Whether the video is currently playing — used to sync the overlay's
  /// music disc rotation and the pause icon display.
  bool _isPlaying = false;

  /// Whether to show the pause icon in the center of the screen
  /// (briefly shown when user taps to pause, then fades out).
  bool _showPauseIcon = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      // Unique key per reel so VisibilityDetector can track each one independently
      key: Key('reel_${widget.index}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(
        color: Colors.black,
        child: _buildContent(),
      ),
    );
  }

  /// Responds to visibility changes as the user scrolls.
  ///
  /// The threshold is 0.8 (80%) — we play the video only when it's
  /// mostly visible. This prevents the "two videos playing at once"
  /// problem during the transition between pages.
  void _onVisibilityChanged(VisibilityInfo info) {
    final controller = _preloadService.getController(widget.reel.id);
    if (controller == null || !controller.value.isInitialized) return;

    if (info.visibleFraction >= 0.8) {
      // This video is now the primary visible one — play it
      // and pause all others
      _preloadService.playReel(widget.reel.id);
      if (mounted) setState(() => _isPlaying = true);
    } else {
      // This video is being scrolled away — pause it
      _preloadService.pauseReel(widget.reel.id);
      if (mounted) setState(() => _isPlaying = false);
      
      // Reset the video to the beginning when it is completely off-screen
      if (info.visibleFraction == 0) {
        controller.seekTo(Duration.zero);
      }
    }
  }

  Widget _buildContent() {
    final controller = _preloadService.getController(widget.reel.id);

    // If the controller exists but failed to initialize, show error state
    if (controller != null && controller.value.hasError) {
      return _buildErrorState();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Blurred thumbnail — always visible as the bottom layer.
        // This is what the user sees while the video controller initializes.
        // The blur effect makes it look intentional (like a splash screen)
        // rather than just a static image.
        _buildThumbnailBackground(),

        // Layer 2: Video player — crossfades in on top of the thumbnail
        // once the controller is initialized and ready to play.
        if (controller != null && controller.value.isInitialized)
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: _buildVideoPlayer(controller),
          ),

        // Layer 3: Gesture detector for tap interactions
        _buildGestureLayer(),

        // Layer 4: Double-tap like animations (floating hearts)
        ..._likeAnimations,

        // Layer 5: Video overlay UI (username, actions, etc.)
        VideoOverlayWidget(
          reel: widget.reel,
          isPlaying: _isPlaying,
        ),

        // Layer 6: Progress bar at the very bottom
        if (controller != null && controller.value.isInitialized)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressBar(controller: controller),
          ),

        // Layer 7: Buffering indicator — only shown when the video is
        // actually buffering (network hiccup), not during initial load
        // (that's what the thumbnail is for).
        if (controller != null &&
            controller.value.isInitialized &&
            controller.value.isBuffering)
          const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ),

        // Pause icon — briefly shown when user taps to pause
        if (_showPauseIcon)
          Center(
            child: AnimatedOpacity(
              opacity: _showPauseIcon ? 0.7 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 70,
                shadows: [Shadow(color: Colors.black38, blurRadius: 20)],
              ),
            ),
          ),

        // Show a centered loading spinner if the controller hasn't
        // initialized yet (and we don't have an error)
        if (controller == null ||
            (!controller.value.isInitialized && !controller.value.hasError))
          Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Colors.white.withValues(alpha: 0.5),
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }

  /// Blurred thumbnail that fills the entire screen.
  /// Uses CachedNetworkImage for disk caching so thumbnails load instantly
  /// on repeat views (no network request needed).
  Widget _buildThumbnailBackground() {
    if (widget.reel.thumbnailUrl.isEmpty) {
      return Container(color: Colors.black);
    }

    final isNetwork = widget.reel.thumbnailUrl.startsWith('http://') ||
        widget.reel.thumbnailUrl.startsWith('https://');

    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: widget.reel.thumbnailUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Apply a blur filter to make the thumbnail look like a soft background
        // rather than a sharp still frame. This creates the nice "loading" feel.
        imageBuilder: (context, imageProvider) {
          return _buildBlurredBackground(imageProvider);
        },
        placeholder: (_, __) => Container(color: Colors.black),
        errorWidget: (_, __, ___) => Container(color: Colors.black),
      );
    } else {
      // Local file path
      return _buildBlurredBackground(FileImage(File(widget.reel.thumbnailUrl)));
    }
  }

  Widget _buildBlurredBackground(ImageProvider imageProvider) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  /// The actual video player — fills the entire screen with cover fit
  /// (crops edges to avoid black bars, just like TikTok).
  Widget _buildVideoPlayer(VideoPlayerController controller) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  /// Gesture layer: handles single-tap (pause/play) and double-tap (like).
  ///
  /// We use a GestureDetector rather than InkWell because:
  ///   1. We need double-tap detection (InkWell doesn't support it well)
  ///   2. We need the exact tap position for the like animation
  ///   3. We don't want the ripple effect on a full-screen video
  Widget _buildGestureLayer() {
    return GestureDetector(
      onTap: _onSingleTap,
      onDoubleTapDown: (details) {
        // Store the position for the like animation
        _onDoubleTap(details.localPosition);
      },
      onDoubleTap: () {
        // Required to register double-tap, but actual logic is in onDoubleTapDown
      },
      behavior: HitTestBehavior.translucent,
      child: Container(color: Colors.transparent),
    );
  }

  /// Single tap toggles play/pause and briefly shows the pause icon.
  void _onSingleTap() {
    final controller = _preloadService.getController(widget.reel.id);
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      HapticFeedback.selectionClick();
      controller.pause();
      setState(() {
        _isPlaying = false;
        _showPauseIcon = true;
      });
    } else {
      HapticFeedback.selectionClick();
      controller.play();
      setState(() {
        _isPlaying = true;
        _showPauseIcon = false;
      });
    }

    // Auto-hide the pause icon after a short delay
    if (_showPauseIcon) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showPauseIcon = false);
        }
      });
    }
  }

  /// Double tap triggers like + spawns a flying heart animation at the tap position.
  void _onDoubleTap(Offset position) {
    HapticFeedback.lightImpact();
    
    // Trigger the like in the controller (handles optimistic update + Firestore)
    final isAlreadyLiked = _reelController.likedReels.contains(widget.reel.id);
    if (!isAlreadyLiked) {
      _reelController.toggleLike(widget.reel.id);
    }

    // Spawn a flying heart animation at the tap position
    final uniqueKey = UniqueKey();
    setState(() {
      _likeAnimations.add(
        LikeAnimationWidget(
          key: uniqueKey,
          position: position,
          onCompleted: () {
            if (mounted) {
              setState(() {
                _likeAnimations.removeWhere(
                  (w) => w.key == uniqueKey,
                );
              });
            }
          },
        ),
      );
    });
  }

  /// Error state: shown when the video controller fails to initialize.
  /// Gives the user a clear retry button instead of just a black screen.
  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load video',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _reelController.retryVideo(widget.index),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
