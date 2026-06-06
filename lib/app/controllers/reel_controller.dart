import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:quick_shorts/app/models/comment_model.dart';
import 'package:quick_shorts/app/models/video_model.dart';
import 'package:quick_shorts/app/repositories/video_repository.dart';
import 'package:quick_shorts/app/services/preload_service.dart';
import 'package:quick_shorts/app/utils/constants.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// The brain of the reels feed — orchestrates data fetching, pagination,
/// video preloading, and user interactions (likes).
///
/// This controller owns no UI code and imports no Flutter widgets.
/// It communicates with the UI purely through Rx observables and methods.
/// This strict separation means we could wire this same controller to
/// a completely different UI (e.g., a grid view) without changing a line here.
class ReelController extends GetxController {
  final VideoRepository _repository = Get.find<VideoRepository>();
  final PreloadService _preloadService = Get.find<PreloadService>();

  // ──── Observable State ────
  // Using GetX's Rx types so the UI automatically rebuilds when these change.

  /// The full list of reels loaded so far (initial + paginated batches).
  final RxList<VideoModel> reels = <VideoModel>[].obs;

  /// Index of the currently visible reel in the PageView.
  /// The overlay UI reads this to show the right username, description, etc.
  final RxInt currentIndex = 0.obs;

  /// True during the initial Firestore fetch. The UI shows a shimmer
  /// placeholder while this is true. We don't use this for pagination
  /// loading — that has its own flag.
  final RxBool isLoading = true.obs;

  /// True while we're fetching the next page of reels. The UI can show
  /// a small spinner at the bottom of the feed during pagination.
  final RxBool isLoadingMore = false.obs;

  /// Tracks which reel IDs the user has liked in this session.
  /// We use a local Set rather than querying Firestore per-reel because
  /// checking likes on every swipe would create way too many reads.
  /// In a real app with auth, you'd persist this in a user subcollection.
  final RxSet<String> likedReels = <String>{}.obs;

  /// Global reference to the PageController from the PageView reels feed,
  /// allowing profile grid navigation to jump directly to specific reels.
  PageController? pageController;

  /// In-memory database of comments per video.
  final RxMap<String, RxList<CommentModel>> comments = <String, RxList<CommentModel>>{}.obs;

  /// Returns the comments list for a specific reel.
  /// If it doesn't exist yet, populates it with realistic mock comments
  /// so that the application comment sections feel active and populated.
  RxList<CommentModel> getCommentsForReel(String reelId) {
    if (!comments.containsKey(reelId)) {
      comments[reelId] = <CommentModel>[
        CommentModel(
          id: '${reelId}_c1',
          username: 'sarah_travels',
          userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
          text: 'Wow, this looks absolutely incredible! Added to my bucket list ASAP! 😍',
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
          likes: 24,
        ),
        CommentModel(
          id: '${reelId}_c2',
          username: 'alex_adventure',
          userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          text: 'What camera did you shoot this with? The quality is crisp! 🔥',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          likes: 8,
        ),
        CommentModel(
          id: '${reelId}_c3',
          username: 'music_lover',
          userAvatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
          text: 'The background track fits the aesthetic so well 🎵',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          likes: 2,
        ),
      ].obs;
    }
    return comments[reelId]!;
  }

  /// Adds a new comment to the given reel from the current user.
  void addComment(String reelId, String text) {
    if (text.trim().isEmpty) return;

    final newComment = CommentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: 'quick_creator',
      userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    final list = getCommentsForReel(reelId);
    list.insert(0, newComment);
    comments[reelId] = list; // Trigger RxMap update
  }

  @override
  void onInit() {
    super.onInit();
    // Remove the native splash screen as soon as the main controller initializes
    FlutterNativeSplash.remove();
    fetchReels();
  }

  /// Loads the first batch of reels and kicks off preloading.
  ///
  /// We wrap this in a try/catch so a Firestore outage doesn't crash the app.
  /// Instead, the user sees an error state with a retry option.
  Future<void> fetchReels() async {
    try {
      isLoading.value = true;
      final fetchedReels = await _repository.fetchReels();
      reels.assignAll(fetchedReels);

      // Start preloading controllers for the first batch immediately.
      // By the time the shimmer fades and the user sees the first video,
      // its controller is already initialized and ready to play.
      if (reels.isNotEmpty) {
        await _preloadService.preload(reels, 0);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load reels. Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Called by the PageView's onPageChanged callback every time the user
  /// swipes to a new reel.
  ///
  /// This method is the coordination hub — it:
  ///   1. Updates the current index (so the overlay shows the right metadata)
  ///   2. Triggers preloading (so upcoming videos are ready)
  ///   3. Checks if we need to paginate (so we never run out of content)
  void onPageChanged(int index) {
    currentIndex.value = index;

    // Preload the sliding window of controllers around the new index.
    // This is fire-and-forget — we don't await it because we don't want
    // to delay the page transition while controllers initialize.
    _preloadService.preload(reels, index);

    // If the user is within N reels of the end, start fetching more.
    // We check against the threshold so the new batch arrives before
    // the user actually reaches the last loaded reel — seamless infinite scroll.
    if (index >= reels.length - AppConstants.paginationThreshold) {
      loadMore();
    }
  }

  /// Fetches the next page of reels and appends them to the list.
  ///
  /// Guard: if we're already loading more, or the repository says there's
  /// nothing left, bail out immediately. Without these guards, rapid swiping
  /// could trigger multiple simultaneous pagination requests — each returning
  /// the same batch of documents and creating duplicates.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !_repository.hasMore) return;

    try {
      isLoadingMore.value = true;
      final moreReels = await _repository.fetchMoreReels();
      reels.addAll(moreReels);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load more reels.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Toggles the like state for a reel, with optimistic UI updating.
  ///
  /// Optimistic update means we immediately reflect the change in the UI
  /// (increment/decrement the count, toggle the heart color) and then
  /// send the update to Firestore in the background. If the Firestore
  /// write fails, we revert the UI. This makes likes feel instant.
  Future<void> toggleLike(String reelId) async {
    final isCurrentlyLiked = likedReels.contains(reelId);

    // Optimistic: flip the like state and update the count in the local list
    if (isCurrentlyLiked) {
      likedReels.remove(reelId);
    } else {
      likedReels.add(reelId);
    }

    // Find the reel in our list and update its like count
    final reelIndex = reels.indexWhere((r) => r.id == reelId);
    if (reelIndex != -1) {
      final reel = reels[reelIndex];
      reels[reelIndex] = reel.copyWith(
        likes: isCurrentlyLiked ? reel.likes - 1 : reel.likes + 1,
      );
    }

    // Now sync to Firestore in the background
    try {
      await _repository.updateLikes(
        reelId: reelId,
        isLiked: !isCurrentlyLiked,
      );
    } catch (e) {
      // Revert the optimistic update if Firestore write failed
      if (isCurrentlyLiked) {
        likedReels.add(reelId);
      } else {
        likedReels.remove(reelId);
      }

      if (reelIndex != -1) {
        final reel = reels[reelIndex];
        reels[reelIndex] = reel.copyWith(
          likes: isCurrentlyLiked ? reel.likes + 1 : reel.likes - 1,
        );
      }

      Get.snackbar(
        'Error',
        'Could not update like. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Retries loading a single video that failed to initialize.
  /// Called when the user taps the retry button on an error slide.
  Future<void> retryVideo(int index) async {
    if (index >= 0 && index < reels.length) {
      await _preloadService.retryReel(reels[index]);
      // Force a rebuild on the specific index by reassigning the reel
      reels[index] = reels[index];
    }
  }

  /// Deletes a reel from both Firestore and Firebase Storage, and updates state.
  Future<void> deleteReel(String reelId) async {
    try {
      // 1. Dispose preloaded controller if any
      await _preloadService.disposeReel(reelId);

      // 2. Delete from repository (Firestore)
      await _repository.deleteReel(reelId);

      // 3. Delete files from Firebase Storage if it's not a mock reel
      if (!reelId.startsWith('mock_')) {
        try {
          final videoRef = FirebaseStorage.instance.ref().child('reels/$reelId.mp4');
          await videoRef.delete();
        } catch (e) {
          Get.log('Firebase Storage video delete warning: $e');
        }
        try {
          final thumbRef = FirebaseStorage.instance.ref().child('thumbnails/$reelId.jpg');
          await thumbRef.delete();
        } catch (e) {
          Get.log('Firebase Storage thumbnail delete warning: $e');
        }
      }

      // 4. Remove locally from memory list
      reels.removeWhere((r) => r.id == reelId);

      // 5. Adjust current index if it goes out of bounds
      if (currentIndex.value >= reels.length && reels.isNotEmpty) {
        currentIndex.value = reels.length - 1;
      }

      Get.snackbar(
        'Success',
        'Reel deleted successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xCC00E676),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.log('Error deleting reel: $e');
      Get.snackbar(
        'Delete Failed',
        'Could not delete reel. Please check your connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xCCFF2D55),
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    // Dispose all video controllers when the user leaves the reels screen.
    // Each controller holds a native decoder thread — failing to dispose
    // them would leak system resources and eventually cause OOM crashes.
    _preloadService.disposeAll();
    super.onClose();
  }
}
