// App-wide constants live here so we have a single source of truth.
// Changing a value here automatically propagates everywhere — no hunting
// through scattered magic numbers across the codebase.

class AppConstants {
  // ──── Firestore ────
  /// The Firestore collection where all reel documents live.
  /// If you ever rename the collection in the Firebase console,
  /// just update this one constant.
  static const String reelsCollection = 'reels';

  // ──── Pagination ────
  /// How many reels to fetch on the very first load.
  /// 15 gives us enough content to fill the preload window immediately
  /// without making the initial fetch too heavy on bandwidth.
  static const int initialPageSize = 15;

  /// How many more reels to fetch when the user is approaching the end.
  /// 10 is small enough to be fast but large enough to avoid constant
  /// Firestore reads as the user keeps scrolling.
  static const int paginationPageSize = 10;

  // ──── Video Preloading ────
  /// How many videos ahead of the current index to preload controllers for.
  /// 15 means the user can swipe rapidly through 15 videos and still get
  /// instant playback — each controller is already initialized and buffered.
  static const int preloadAhead = 2;

  /// How many videos behind the current index to keep before disposing.
  /// 1 is perfect to allow swiping back one page instantly without lag.
  static const int disposeBehind = 1;

  // ──── Cache ────
  /// Maximum disk space the video cache is allowed to use.
  /// 500MB is a reasonable cap — enough to cache ~50 short videos
  /// (assuming ~10MB each) without eating the user's storage.
  static const int maxCacheSize = 500 * 1024 * 1024; // 500 MB

  /// How long cached video files stay on disk before being considered stale.
  /// 7 days means videos the user watched last week won't clutter storage,
  /// but rewatching within a week is instant.
  static const Duration maxCacheAge = Duration(days: 7);

  /// The key used by flutter_cache_manager to namespace our cache folder.
  /// This prevents collisions with other packages that also use caching.
  static const String cacheKey = 'quickShortsVideoCache';

  // ──── UI ────
  /// The visibility threshold for auto-playing a video.
  /// 0.8 means the video must be at least 80% visible on screen before
  /// we start playing — prevents awkward half-visible autoplay.
  static const double visibilityThreshold = 0.8;

  /// How many items from the end should trigger loading more reels.
  /// If there are 15 reels and the user reaches reel #10 (15 - 5),
  /// we start fetching the next batch in the background.
  static const int paginationThreshold = 5;
}
