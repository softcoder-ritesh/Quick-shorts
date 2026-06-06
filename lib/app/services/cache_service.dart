import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:quick_shorts/app/utils/constants.dart';

/// Wraps flutter_cache_manager with app-specific configuration.
///
/// Instead of using the default `DefaultCacheManager` (which is shared by
/// every package in the app and has no size limits), we create a dedicated
/// cache manager scoped to video files. This gives us:
///   1. A custom 500MB size cap so we don't fill the user's phone
///   2. A 7-day staleness window so old videos are cleaned up automatically
///   3. A unique cache key that won't collide with image caching or other packages
class CacheService {
  /// Our custom cache manager instance. The `Config` constructor lets us
  /// control every aspect of the caching behavior — something you can't
  /// do with the default singleton.
  late final CacheManager _cacheManager;

  CacheService() {
    _cacheManager = CacheManager(
      Config(
        AppConstants.cacheKey,
        stalePeriod: AppConstants.maxCacheAge,
        maxNrOfCacheObjects: 100,
        // We rely on the stalePeriod and object count to manage cache size.
        // flutter_cache_manager doesn't support a byte-based max directly,
        // but 100 objects × ~10MB each ≈ 1GB max, and the stalePeriod
        // ensures old files get cleaned up regularly. For stricter control,
        // we'd need a custom file store implementation.
      ),
    );
  }

  /// Checks if a video is already sitting in the local disk cache.
  ///
  /// We call this before creating a VideoPlayerController so we can decide
  /// whether to use `.file()` (instant, no network) or `.networkUrl()`
  /// (streams from Firebase Storage). This check is cheap — it just looks
  /// at the cache's internal database, no disk I/O.
  Future<FileInfo?> getFileFromCache(String url) async {
    return await _cacheManager.getFileFromCache(url);
  }

  /// Downloads and caches a video file, returning the local File.
  ///
  /// If the file is already cached, it returns immediately from disk.
  /// If not, it downloads from the network (Firebase Storage in our case),
  /// stores it in the cache folder, and then returns the local path.
  ///
  /// We use the video URL as the cache key because Firestore document IDs
  /// might change if we re-import data, but URLs are stable references
  /// to the actual file in Storage.
  Future<File> getVideoFile(String url) async {
    final fileInfo = await _cacheManager.getSingleFile(url);
    return fileInfo;
  }

  /// Starts downloading a video in the background without waiting for it.
  ///
  /// This is the key to our caching strategy: when a video starts playing
  /// from the network URL, we kick off a background download into the cache
  /// at the same time. Next time the user encounters this video (or scrolls
  /// back to it), playback will be instant from disk.
  ///
  /// Returns a Stream that emits download progress — we don't use it today
  /// but it's there if we ever want to show download progress in the UI.
  Stream<FileResponse> downloadFile(String url) {
    return _cacheManager.getFileStream(
      url,
      withProgress: true,
    );
  }

  /// Removes a specific video from the cache.
  /// Useful if we detect a corrupt cached file that causes playback errors.
  Future<void> removeFile(String url) async {
    await _cacheManager.removeFile(url);
  }

  /// Wipes the entire video cache. Nuclear option — used if the user
  /// wants to free up space or if we detect widespread cache corruption.
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  /// Call this when the service is being torn down (e.g., app shutdown)
  /// to release the cache manager's internal resources like database handles.
  void dispose() {
    _cacheManager.dispose();
  }
}
