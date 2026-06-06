# Quick Shorts

A production-grade TikTok/Instagram Reels clone built with Flutter, GetX, and Firebase.

## Architecture

### Why GetX?

For a feature-focused app like this (essentially one complex screen), GetX's lightweight approach is ideal:
- **Reactive state** via `Rx` types — no boilerplate. The `Obx` widget auto-rebuilds when observables change.
- **Dependency injection** via `Get.lazyPut` — clean, testable, no Provider trees.
- **Navigation** via named routes with bindings — dependencies are wired up before each screen builds.

For a larger app with many developers, Bloc or Riverpod would offer more structure. But for a content consumption app like this, GetX keeps the code lean.

### Video Preloading Strategy

The app maintains a **sliding window** of `VideoPlayerController` instances:

```
[disposed] [disposed] [kept] [kept] [CURRENT] [preloaded] ... [preloaded]
              ←5→              ↑                    ←15→
           behind          current               ahead
```

- **15 ahead**: Enough for rapid swiping without hitting uninitialized videos
- **5 behind**: Lets the user swipe back a few without reloading
- **Everything else**: Disposed to free native decoder threads

Each controller holds a native video decoder (ExoPlayer on Android, AVPlayer on iOS), which consumes ~20-50MB of memory. Without this windowing, scrolling through 100 videos would consume 2-5GB of RAM and crash.

### Caching Approach

```
User swipes to video #5
  → Check disk cache for video URL
  → Cache hit?  → VideoPlayerController.file(localFile)     // instant
  → Cache miss? → VideoPlayerController.networkUrl(url)      // streams
                 + background download to cache               // for next time
```

Cache is limited to 500MB / 7 days via a custom `CacheManager` instance (not the shared default).

### Memory Management

Each `VideoPlayerController` internally:
1. Allocates a native decoder thread
2. Buffers several seconds of decoded frames
3. Holds a reference to the video surface

We aggressively dispose controllers outside the sliding window to prevent:
- OOM crashes on lower-end devices
- Thread exhaustion (Android limits native threads)
- GPU surface leaks

## Project Structure

```
lib/
├── main.dart                          # Entry point, Firebase init
├── firebase_options.dart              # Platform-specific Firebase config
└── app/
    ├── bindings/
    │   └── reel_binding.dart          # DI setup for all reel dependencies
    ├── controllers/
    │   └── reel_controller.dart       # Business logic: fetch, paginate, like
    ├── models/
    │   └── video_model.dart           # Firestore data model
    ├── repositories/
    │   └── video_repository.dart      # Firestore queries (paginated)
    ├── routes/
    │   ├── app_routes.dart            # Route name constants
    │   └── app_pages.dart             # GetPage definitions
    ├── services/
    │   ├── cache_service.dart         # Video disk caching (500MB, 7 days)
    │   └── preload_service.dart       # Controller pool management
    ├── utils/
    │   ├── constants.dart             # App-wide configuration values
    │   └── format_helpers.dart        # Number formatting (12.4K), time ago
    └── views/
        ├── home/
        │   └── home_screen.dart       # PageView-based reel feed
        └── widgets/
            ├── like_animation_widget.dart    # Double-tap flying heart
            ├── music_disc_widget.dart        # Rotating album disc
            ├── reel_player_widget.dart       # Per-video widget (core)
            ├── shimmer_loading_widget.dart   # Initial loading placeholder
            ├── video_overlay_widget.dart     # Username, actions, info
            └── video_progress_bar.dart       # Thin playback progress bar
```

## Getting Started

1. Clone the repo
2. Follow [FIREBASE_SETUP.md](./FIREBASE_SETUP.md) to configure Firebase
3. Run:
```bash
flutter pub get
flutter run
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `get` | State management, routing, DI |
| `firebase_core` | Firebase initialization |
| `cloud_firestore` | Video metadata storage |
| `firebase_storage` | Video file hosting |
| `video_player` | Native video playback |
| `flutter_cache_manager` | Disk caching with size limits |
| `visibility_detector` | Scroll-based auto-play/pause |
| `cached_network_image` | Thumbnail caching |
| `shimmer` | Loading placeholder animations |
