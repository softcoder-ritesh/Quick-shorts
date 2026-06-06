import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_shorts/app/models/video_model.dart';
import 'package:quick_shorts/app/utils/constants.dart';

/// The single point of contact between the app and Firestore.
///
/// All Firestore queries live here — controllers and views never import
/// cloud_firestore directly. This makes it trivial to swap out Firestore
/// for a different backend later (REST API, Supabase, etc.) without
/// touching any business logic or UI code.
class VideoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// We keep a reference to the last document we fetched so we can
  /// use Firestore's `startAfterDocument` for cursor-based pagination.
  /// This is more reliable than offset-based pagination because it handles
  /// real-time additions/deletions gracefully — you won't skip or duplicate
  /// documents if the collection changes between page fetches.
  DocumentSnapshot? _lastDocument;

  /// Whether there are more documents to fetch from Firestore.
  /// Once a query returns fewer documents than the requested limit,
  /// we know we've hit the end and stop making further requests.
  bool _hasMore = true;

  /// Public getter so the controller can check if it should bother
  /// calling loadMore() — avoids unnecessary Firestore reads.
  bool get hasMore => _hasMore;

  /// Fetches the first batch of reels from Firestore.
  ///
  /// We order by `createdAt` descending so the newest content appears first
  /// (just like TikTok/Instagram). The limit defaults to 15 which gives us
  /// enough videos to fill the preload window immediately.
  ///
  /// This also resets the pagination cursor, so calling this again
  /// effectively refreshes the entire feed (useful for pull-to-refresh
  /// if we add that later).
  Future<List<VideoModel>> fetchReels({
    int limit = AppConstants.initialPageSize,
  }) async {
    // Reset pagination state for a fresh fetch
    _lastDocument = null;
    _hasMore = true;

    try {
      final query = _firestore
          .collection(AppConstants.reelsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();

      // If we got fewer docs than we asked for, there's nothing more to load
      if (snapshot.docs.length < limit) {
        _hasMore = false;
      }

      // Save the last document for pagination cursor
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      return snapshot.docs.map((doc) => VideoModel.fromFirestore(doc)).toList();
    } catch (e) {
      // ignore: avoid_print
      print("VideoRepository: Firebase fetch failed: $e");
      _hasMore = false;
      rethrow;
    }
  }

  /// Fetches the next page of reels starting after the last document
  /// from the previous fetch.
  Future<List<VideoModel>> fetchMoreReels({
    int limit = AppConstants.paginationPageSize,
  }) async {
    // Guard: if there's nothing more to fetch, return empty immediately
    if (!_hasMore || _lastDocument == null) {
      return [];
    }

    try {
      final query = _firestore
          .collection(AppConstants.reelsCollection)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(limit);

      final snapshot = await query.get();

      if (snapshot.docs.length < limit) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      return snapshot.docs.map((doc) => VideoModel.fromFirestore(doc)).toList();
    } catch (e) {
      // ignore: avoid_print
      print("VideoRepository: Firebase pagination failed: $e");
      _hasMore = false;
      return [];
    }
  }

  /// Atomically increments or decrements the like count on a reel document.
  Future<void> updateLikes({
    required String reelId,
    required bool isLiked,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.reelsCollection)
          .doc(reelId)
          .update({
        'likes': FieldValue.increment(isLiked ? 1 : -1),
      });
    } catch (e) {
      // Ignore errors for mock reels
      if (reelId.startsWith('mock_')) return;
      rethrow;
    }
  }

  /// Creates a new reel document in Firestore after the user uploads a video.
  Future<String> createReel(VideoModel reel) async {
    final docRef = _firestore
        .collection(AppConstants.reelsCollection)
        .doc(reel.id.isEmpty ? null : reel.id);
    await docRef.set(reel.toMap());
    return docRef.id;
  }

  /// Deletes a reel document from Firestore by ID.
  Future<void> deleteReel(String reelId) async {
    await _firestore
        .collection(AppConstants.reelsCollection)
        .doc(reelId)
        .delete();
  }


}
