import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_shorts/app/controllers/reel_controller.dart';
import 'package:quick_shorts/app/models/video_model.dart';
import 'package:quick_shorts/app/repositories/video_repository.dart';
import 'package:quick_shorts/app/services/upload_service.dart';

/// All possible UI states for the upload screen.
enum UploadState {
  /// Initial state: No video picked.
  idle,

  /// Mid state: Video picked and thumbnail generated; user writing caption.
  picked,

  /// Mid state: Actively picking a video or generating its thumbnail.
  generating,

  /// Active state: Uploading video and thumbnail files to Storage.
  uploading,

  /// Complete state: Database write succeeded; upload is complete.
  success,

  /// Failure state: An error occurred during picker, generation, or upload.
  error,
}

/// Controller that coordinates the logic for the reels upload screen.
///
/// Provides state streams to the view, handles user input validation,
/// triggers background file uploads, updates the database, and forces
/// a refresh of the main feed.
class UploadController extends GetxController {
  final UploadService _uploadService = Get.find<UploadService>();
  final VideoRepository _videoRepository = Get.find<VideoRepository>();

  /// The picked video file on device disk.
  final Rx<File?> selectedVideo = Rx<File?>(null);

  /// The auto-extracted thumbnail file on device disk.
  final Rx<File?> generatedThumbnail = Rx<File?>(null);

  /// Active UI state.
  final Rx<UploadState> state = UploadState.idle.obs;

  /// The overall progress of the video file upload (0.0 to 1.0).
  final RxDouble uploadProgress = 0.0.obs;

  /// Guard to prevent double-submissions.
  final RxBool isUploading = false.obs;

  /// Controller for the caption/description input.
  final TextEditingController descriptionController = TextEditingController();

  /// Prompts the user to pick/record a video, then auto-generates a thumbnail.
  Future<void> pickVideo(ImageSource source) async {
    try {
      state.value = UploadState.generating;
      final file = await _uploadService.pickVideo(source: source);
      
      if (file != null) {
        selectedVideo.value = file;
        
        // Generate the thumbnail automatically from the video file
        final thumbnailFile = await _uploadService.generateThumbnail(file.path);
        if (thumbnailFile != null) {
          generatedThumbnail.value = thumbnailFile;
          state.value = UploadState.picked;
        } else {
          state.value = UploadState.error;
          Get.snackbar(
            'Error',
            'Failed to generate a thumbnail from the video.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
            colorText: Colors.white,
          );
        }
      } else {
        // User cancelled picker — fall back to previous state or idle
        state.value = selectedVideo.value != null ? UploadState.picked : UploadState.idle;
      }
    } catch (e) {
      state.value = UploadState.error;
      Get.log('UploadController: Error picking/generating: $e');
    }
  }

  /// Triggers the entire upload and metadata registration pipeline.
  ///
  /// Steps:
  /// 1. Create a unique Firestore document ID first to use as Storage file paths.
  /// 2. Upload video file to Firebase Storage (with progress tracking).
  /// 3. Upload thumbnail file to Firebase Storage.
  /// 4. Add the [VideoModel] document to Firestore.
  /// 5. Refresh the ReelController feed so the new video displays first.
  Future<void> uploadReel() async {
    final video = selectedVideo.value;
    final thumb = generatedThumbnail.value;

    if (video == null || thumb == null) {
      Get.snackbar(
        'Warning',
        'Please select a video before uploading.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isUploading.value = true;
      state.value = UploadState.uploading;
      uploadProgress.value = 0.0;

      // Pre-allocate a Firestore document ID so both Storage references and
      // the Firestore document share the exact same ID.
      final reelId = FirebaseFirestore.instance.collection('reels').doc().id;

      // 1. Upload the video file (heavy task, track progress)
      final videoTask = _uploadService.uploadVideoTask(video, reelId);
      
      final subscription = videoTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          uploadProgress.value = event.bytesTransferred / event.totalBytes;
        }
      });

      final videoSnapshot = await videoTask;
      await subscription.cancel();
      final videoUrl = await videoSnapshot.ref.getDownloadURL();

      // 2. Upload the thumbnail file (light task)
      final thumbTask = _uploadService.uploadThumbnailTask(thumb, reelId);
      final thumbSnapshot = await thumbTask;
      final thumbnailUrl = await thumbSnapshot.ref.getDownloadURL();

      // 3. Construct the VideoModel.
      // Since there's no auth, we use a default username/avatar as placeholders.
      final newReel = VideoModel(
        id: reelId,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        description: descriptionController.text.trim(),
        likes: 0,
        username: 'quick_creator',
        userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        createdAt: DateTime.now(),
      );

      // 4. Register the reel document in Firestore
      await _videoRepository.createReel(newReel);

      state.value = UploadState.success;

      // 5. Force the feed controller to reload its contents, bringing
      // the newly uploaded reel to the top of the deck.
      if (Get.isRegistered<ReelController>()) {
        final feedController = Get.find<ReelController>();
        await feedController.fetchReels();
      }
    } catch (e) {
      state.value = UploadState.error;
      Get.log('UploadController: Upload pipeline failed: $e');
      Get.snackbar(
        'Upload Failed',
        'Could not complete the upload. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isUploading.value = false;
    }
  }

  /// Resets all controller state back to the fresh, unselected state.
  void reset() {
    selectedVideo.value = null;
    generatedThumbnail.value = null;
    descriptionController.clear();
    uploadProgress.value = 0.0;
    state.value = UploadState.idle;
    isUploading.value = false;
  }

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }
}
