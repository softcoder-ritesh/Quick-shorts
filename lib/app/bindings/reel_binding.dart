import 'package:get/get.dart';
import 'package:quick_shorts/app/controllers/main_layout_controller.dart';
import 'package:quick_shorts/app/controllers/reel_controller.dart';
import 'package:quick_shorts/app/repositories/video_repository.dart';
import 'package:quick_shorts/app/services/cache_service.dart';
import 'package:quick_shorts/app/services/preload_service.dart';

/// GetX binding for the reels screen — wires up all dependencies
/// before the screen builds.
///
/// Why `lazyPut` instead of `put`? Because lazy instantiation means
/// these objects only get created when something first asks for them
/// via `Get.find()`. In practice they all get created almost immediately
/// (since ReelController depends on all of them), but it's a good habit
/// that becomes useful when you have conditional dependencies.
///
/// The dependency order matters here:
///   1. VideoRepository (standalone, no deps)
///   2. CacheService (standalone, no deps)
///   3. PreloadService (depends on CacheService)
///   4. ReelController (depends on VideoRepository + PreloadService)
///
/// GetX resolves these lazily, so even though we register them in this
/// order, they'll be created in the right dependency order when accessed.
class ReelBinding extends Bindings {
  @override
  void dependencies() {
    // Shell Layout Controller
    Get.lazyPut<MainLayoutController>(() => MainLayoutController());

    // Data layer — talks to Firestore, no dependencies
    Get.lazyPut<VideoRepository>(() => VideoRepository());

    // Caching layer — wraps flutter_cache_manager, no dependencies
    Get.lazyPut<CacheService>(() => CacheService());

    // Video controller pool — needs CacheService to check disk cache
    // before creating VideoPlayerControllers
    Get.lazyPut<PreloadService>(() => PreloadService(Get.find<CacheService>()));

    // Main controller — orchestrates everything
    Get.lazyPut<ReelController>(() => ReelController());
  }
}
