import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Service responsible for managing all file-related operations for uploading reels.
///
/// This includes using the native camera/gallery to pick/record videos,
/// auto-generating JPEG thumbnails from the video file at a specific time index,
/// and streaming upload events to Firebase Storage.
class UploadService extends GetxService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Prompts the user to pick a video from gallery or record via camera.
  ///
  /// Returns a [File] if successful, or `null` if the user cancels.
  /// Sets a limit of 60 seconds to match the "short-form" reel concept
  /// and keep storage/bandwidth usage under control.
  Future<File?> pickVideo({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      Get.log('UploadService: Error picking video: $e');
    }
    return null;
  }

  /// Automatically generates a JPEG thumbnail from the given [videoPath].
  ///
  /// Extracts a frame at the 1-second mark (1000ms) to avoid dark intro frames.
  /// Saves it to the platform's temporary directory and returns a [File].
  Future<File?> generateThumbnail(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      
      // video_thumbnail package creates a thumbnail file on disk and returns its path
      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 640, // standard resolution for thumbnail preview
        quality: 75, // 75% quality offers great compression vs visual fidelity
        timeMs: 1000, // 1-second mark
      );

      if (thumbnailPath != null) {
        return File(thumbnailPath);
      }
    } catch (e) {
      Get.log('UploadService: Error generating thumbnail: $e');
    }
    return null;
  }

  /// Creates and returns an [UploadTask] for the video file.
  ///
  /// The caller can listen to this task's `snapshotEvents` stream to update
  /// the progress bar in the UI.
  UploadTask uploadVideoTask(File file, String reelId) {
    final ref = _storage.ref().child('reels/$reelId.mp4');
    return ref.putFile(
      file,
      SettableMetadata(contentType: 'video/mp4'),
    );
  }

  /// Creates and returns an [UploadTask] for the thumbnail file.
  ///
  /// Uploads thumbnail to 'thumbnails/$reelId.jpg'.
  UploadTask uploadThumbnailTask(File file, String reelId) {
    final ref = _storage.ref().child('thumbnails/$reelId.jpg');
    return ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
  }
}
