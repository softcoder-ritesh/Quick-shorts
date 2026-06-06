import 'package:get/get.dart';
import 'package:quick_shorts/app/controllers/upload_controller.dart';
import 'package:quick_shorts/app/repositories/video_repository.dart';
import 'package:quick_shorts/app/services/upload_service.dart';

/// GetX binding for the Upload screen.
///
/// Registers the `UploadService` and `UploadController` to be lazily initialized
/// when navigation targets the Upload route.
class UploadBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure VideoRepository is available (if not already instantiated by ReelBinding)
    Get.lazyPut<VideoRepository>(() => VideoRepository());

    // Register file/Storage service
    Get.lazyPut<UploadService>(() => UploadService());

    // Register UploadController with dependency injection
    Get.lazyPut<UploadController>(() => UploadController());
  }
}
