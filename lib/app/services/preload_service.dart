import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:quick_shorts/app/models/video_model.dart';
import 'package:quick_shorts/app/services/cache_service.dart';
import 'package:quick_shorts/app/utils/constants.dart';

/// Manages a pool of VideoPlayerControllers, preloading upcoming videos
/// and disposing old ones to balance instant playback against memory usage.
///
/// The core idea: each VideoPlayerController holds a native video decoder
/// thread (ExoPlayer on Android, AVPlayer on iOS). These are expensive —
/// holding 50 of them simultaneously would crash the app. So we maintain
/// a sliding window: preload 15 ahead, keep 5 behind, dispose everything else.
///
/// This means the user can swipe through 15 videos before encountering
/// any loading, and can swipe back 5 videos and still get instant playback.
class PreloadService {
  final CacheService _cacheService;

  /// The map of active controllers, keyed by their unique reel ID.
  final Map<String, VideoPlayerController> _controllers = {};

  /// Tracks which reel IDs are currently being initialized.
  /// This prevents duplicate initialization attempts when scrolling quickly.
  final Set<String> _initializingReelIds = {};

  PreloadService(this._cacheService);

  /// Returns the controller for a given reel ID, or null if it hasn't
  /// been preloaded yet.
  VideoPlayerController? getController(String reelId) {
    return _controllers[reelId];
  }

  /// The main preloading method — called every time the user swipes to a new page.
  ///
  /// It does two things:
  ///   1. Ensures controllers exist for videos in the [currentIndex - disposeBehind]
  ///      to [currentIndex + preloadAhead] window
  ///   2. Disposes any controllers outside that window
  Future<void> preload(List<VideoModel> reels, int currentIndex) async {
    // Calculate the window boundaries
    final int start = (currentIndex - AppConstants.disposeBehind).clamp(0, reels.length - 1);
    final int end = (currentIndex + AppConstants.preloadAhead).clamp(0, reels.length - 1);

    // Get the set of visible/preloading reel IDs in this sliding window
    final Set<String> visibleReelIds = reels.sublist(start, end + 1).map((r) => r.id).toSet();

    // Dispose controllers that have fallen outside the window.
    final keysToDispose = _controllers.keys
        .where((reelId) => !visibleReelIds.contains(reelId))
        .toList();

    for (final reelId in keysToDispose) {
      final controller = _controllers.remove(reelId);
      if (controller != null) {
        // Dispose asynchronously after scroll animation finishes, so it doesn't block the UI thread
        Future.delayed(const Duration(seconds: 1), () async {
          try {
            await controller.dispose();
          } catch (e) {
            // ignore
          }
        });
      }
    }

    // Preload controllers for videos in the window that don't have one yet.
    final futures = <Future>[];
    for (int i = start; i <= end; i++) {
      final reel = reels[i];
      if (!_controllers.containsKey(reel.id) && !_initializingReelIds.contains(reel.id)) {
        futures.add(_initializeController(reel));
      }
    }
    await Future.wait(futures);
  }

  /// Creates and initializes a single VideoPlayerController.
  Future<void> _initializeController(VideoModel reel) async {
    // Prevent duplicate initialization
    if (_initializingReelIds.contains(reel.id)) return;
    _initializingReelIds.add(reel.id);

    try {
      VideoPlayerController controller;

      final isNetwork = reel.videoUrl.startsWith('http://') || reel.videoUrl.startsWith('https://');

      if (isNetwork) {
        // Try to load from disk cache first
        final cachedFile = await _cacheService.getFileFromCache(reel.videoUrl);

        if (cachedFile != null) {
          controller = VideoPlayerController.file(cachedFile.file);
        } else {
          controller = VideoPlayerController.networkUrl(
            Uri.parse(reel.videoUrl),
          );
          _cacheService.downloadFile(reel.videoUrl).listen((_) {});
        }
      } else {
        controller = VideoPlayerController.file(File(reel.videoUrl));
      }

      await controller.initialize();
      controller.setLooping(true);

      _controllers[reel.id] = controller;
    } catch (e) {
      // ignore: avoid_print
      print('PreloadService: Failed to initialize controller for reel ${reel.id}: $e');
    } finally {
      _initializingReelIds.remove(reel.id);
    }
  }

  /// Plays the video with the given reel ID and pauses all others.
  void playReel(String reelId) {
    _controllers.forEach((key, controller) {
      if (key == reelId) {
        controller.play();
      } else {
        controller.pause();
      }
    });
  }

  /// Pauses the video for the given reel ID.
  void pauseReel(String reelId) {
    _controllers[reelId]?.pause();
  }

  /// Disposes ALL controllers.
  Future<void> disposeAll() async {
    for (final controller in _controllers.values) {
      await controller.dispose();
    }
    _controllers.clear();
    _initializingReelIds.clear();
  }

  /// Disposes and removes the controller for a specific reel ID.
  Future<void> disposeReel(String reelId) async {
    final controller = _controllers.remove(reelId);
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (e) {
        // ignore
      }
    }
    _initializingReelIds.remove(reelId);
  }

  /// Disposes and reinitializes the controller for a specific reel.
  Future<void> retryReel(VideoModel reel) async {
    await _controllers[reel.id]?.dispose();
    _controllers.remove(reel.id);
    _initializingReelIds.remove(reel.id);
    await _initializeController(reel);
  }
}
