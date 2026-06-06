# 📱 Quick Shorts - Flutter Reels Clone

A highly polished, production-grade TikTok/Instagram Reels clone built with **Flutter**, **GetX**, and **Firebase**. This project demonstrates advanced Flutter capabilities including video preloading, gesture animations, disk caching, and seamless UI/UX.

---

## ✨ Features

- **🎬 Seamless Video Playback:** Vertical `PageView` with snapping scroll physics for the authentic TikTok feel.
- **⚡ Advanced Preloading:** Custom sliding-window algorithm that preloads videos ahead of time and disposes old ones to keep memory usage low and prevent crashes.
- **💾 Smart Disk Caching:** Videos are cached to disk so they load instantly on repeat views without burning bandwidth.
- **❤️ Double-Tap to Like:** Animated floating heart that pops exactly where you tap.
- **⏸️ Single-Tap to Pause:** Instantly pause/play with a fading visual indicator.
- **📳 Haptic Feedback:** Subtle, premium device vibrations on likes, double-taps, and pauses.
- **🔄 Pull-to-Refresh:** Swipe down to fetch the latest videos from Firebase.
- **💿 Animated Music Disc:** Rotating vinyl disc showing the current user's avatar.
- **💀 Shimmer Loading:** Full-screen TikTok-style skeleton loading UI.
- **🚀 Instant Launch:** Native splash screen orchestration ensures no "double splash" or white screens on startup.

---

## 🛠 Architecture & Tech Stack

### State Management: GetX
For a feature-focused app like this, GetX's lightweight approach is ideal:
- **Reactive state** via `Rx` types — no boilerplate. The `Obx` widget auto-rebuilds when observables change.
- **Dependency injection** via `Get.lazyPut` — clean, testable, no Provider trees.
- **Navigation** via named routes with bindings — dependencies are wired up before each screen builds.

### Video Preloading Strategy
The app maintains a **sliding window** of `VideoPlayerController` instances:

```text
[disposed] [kept] [kept] [CURRENT] [preloaded] ... [preloaded]
             ←5→              ↑                    ←15→
          behind          current               ahead
```
Each native video decoder (ExoPlayer on Android, AVPlayer on iOS) consumes ~20-50MB of memory. Without this windowing, scrolling through 100 videos would consume 2-5GB of RAM and crash the app. Our `PreloadService` handles this automatically in the background.

### Caching Approach
```text
User swipes to video #5
  → Check disk cache for video URL
  → Cache hit?  → VideoPlayerController.file(localFile)     // instant
  → Cache miss? → VideoPlayerController.networkUrl(url)      // streams
                 + background download to cache               // for next time
```
Cache is limited to 500MB / 7 days via a custom `CacheManager` instance.

---

## 📂 Project Structure

```text
lib/
├── main.dart                          # Entry point, Firebase init
├── firebase_options.dart              # Platform-specific Firebase config
└── app/
    ├── bindings/                      # DI setup for all dependencies
    ├── controllers/                   # Business logic (Reels, Uploads)
    ├── models/                        # Firestore data models
    ├── repositories/                  # Firestore queries & pagination
    ├── routes/                        # Named routing
    ├── services/                      # Preloading, Caching, and Upload Services
    ├── utils/                         # Formatting and constants
    └── views/
        ├── home/                      # PageView-based reel feed
        └── widgets/
            ├── like_animation_widget.dart    # Double-tap flying heart
            ├── music_disc_widget.dart        # Rotating album disc
            ├── reel_player_widget.dart       # Per-video logic
            ├── shimmer_loading_widget.dart   # Loading placeholders
            └── video_overlay_widget.dart     # UI overlays (buttons, text)
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.10+)
- Firebase Account

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/softcoder-ritesh/Quick-shorts.git
   cd Quick-shorts
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Ensure you have your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the correct directories as per the [FIREBASE_SETUP.md](./FIREBASE_SETUP.md).

4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `get` | State management, routing, DI |
| `firebase_core` / `cloud_firestore` / `firebase_storage` | Backend, Database, and Media Storage |
| `video_player` | Native video playback |
| `flutter_cache_manager` | Disk caching with size limits |
| `visibility_detector` | Scroll-based auto-play/pause |
| `cached_network_image` | Thumbnail caching |
| `shimmer` | Loading placeholder animations |

---

## 👨‍💻 Developed By

**Ritesh**
- GitHub: [@softcoder-ritesh](https://github.com/softcoder-ritesh)
