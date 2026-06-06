import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:quick_shorts/app/controllers/upload_controller.dart';

/// The video upload view, implementing 4 states:
/// 1. Choose source (Gallery vs Camera)
/// 2. Picked preview (Looping video preview + generated thumbnail cover + description input)
/// 3. Uploading progress status (glowing progress percentage)
/// 4. Upload success checkmark card
class UploadScreen extends GetView<UploadController> {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            controller.reset();
            Get.back();
          },
        ),
        title: const Text(
          'Create Reel',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        switch (controller.state.value) {
          case UploadState.idle:
            return _buildIdleState();
          case UploadState.generating:
            return _buildProcessingState('Extracting thumbnail frame...');
          case UploadState.picked:
            return _buildPickedState(context);
          case UploadState.uploading:
            return _buildUploadingState();
          case UploadState.success:
            return _buildSuccessState();
          case UploadState.error:
            return _buildErrorState();
        }
      }),
    );
  }

  // --- 1. IDLE STATE: CHOOSE SOURCE ---
  Widget _buildIdleState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [
            Color(0x22FF2D55), // Subtle red glow
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Production App Stepper
              _buildStepper(0),
              const SizedBox(height: 40),
              
              // Central Glassmorphic upload card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Glowing circular upload icon
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF2D55).withValues(alpha: 0.1),
                        border: Border.all(color: const Color(0xFFFF2D55).withValues(alpha: 0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2D55).withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        size: 38,
                        color: Color(0xFFFF2D55),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Create New Reel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share your moments with the world.\nVertical MP4 videos up to 60 seconds.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Buttons inside the glass container
                    _buildUploadSourceButton(
                      title: 'Upload from Gallery',
                      subtitle: 'Browse your device photos & videos',
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFF8E2DE2),
                      onTap: () => controller.pickVideo(ImageSource.gallery),
                    ),
                    const SizedBox(height: 16),
                    _buildUploadSourceButton(
                      title: 'Shoot with Camera',
                      subtitle: 'Record a vertical short clip now',
                      icon: Icons.videocam_rounded,
                      color: const Color(0xFFFF2D55),
                      onTap: () => controller.pickVideo(ImageSource.camera),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSourceButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper(int activeStep) {
    final steps = ['Select', 'Details', 'Upload'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Line connection
          final stepIndex = index ~/ 2;
          final isActive = stepIndex < activeStep;
          return Container(
            width: 40,
            height: 2,
            color: isActive ? const Color(0xFFFF2D55) : Colors.white12,
          );
        } else {
          // Circle node
          final stepIndex = index ~/ 2;
          final isActive = stepIndex <= activeStep;
          final isCurrent = stepIndex == activeStep;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrent
                  ? const Color(0xFFFF2D55)
                  : (isActive ? const Color(0xFFFF2D55).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFFFF2D55)
                    : (isActive ? const Color(0xFFFF2D55).withValues(alpha: 0.5) : Colors.white10),
              ),
            ),
            child: Text(
              steps[stepIndex],
              style: TextStyle(
                color: isCurrent ? Colors.white : (isActive ? Colors.white70 : Colors.white38),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
      }),
    );
  }

  // --- 2. PROCESSING STATE: GENERATING PREVIEW/THUMBNAIL ---
  Widget _buildProcessingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF2D55)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. PICKED STATE: PREVIEW & CAPTION INPUT ---
  Widget _buildPickedState(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.6),
          radius: 1.2,
          colors: [
            Color(0x228E2DE2), // Subtle purple glow
            Colors.black,
          ],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Production App Stepper
            _buildStepper(1),
            const SizedBox(height: 28),

            // Top preview and metadata row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Looping video preview container
                  Container(
                    width: 100,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: controller.selectedVideo.value != null
                        ? _VideoPreviewWidget(file: controller.selectedVideo.value!)
                        : Container(color: Colors.grey[900]),
                  ),
                  const SizedBox(width: 16),
                  
                  // Selected Video details info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VIDEO SELECTED',
                          style: TextStyle(
                            color: Color(0xFFFF2D55),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.selectedVideo.value != null
                              ? controller.selectedVideo.value!.path.split('/').last
                              : 'Reel Video',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.video_file_outlined, color: Colors.grey[500], size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Format: MP4 (Vertical)',
                              style: TextStyle(color: Colors.grey[500], fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.sd_storage_outlined, color: Colors.grey[500], size: 12),
                            const SizedBox(width: 4),
                            Text(
                              controller.selectedVideo.value != null
                                  ? '${(File(controller.selectedVideo.value!.path).lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB'
                                  : '10.5 MB',
                              style: TextStyle(color: Colors.grey[500], fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Caption Section
            const Text(
              'Caption',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.descriptionController,
              maxLines: 4,
              maxLength: 150,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Share a story behind this video, add tags (e.g. #india #vlog)...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                contentPadding: const EdgeInsets.all(16),
                counterStyle: TextStyle(color: Colors.grey[600], fontSize: 10),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFF2D55), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Thumbnail Cover Section
            const Text(
              'Auto-Generated Cover',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (controller.generatedThumbnail.value != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            controller.generatedThumbnail.value!,
                            width: 90,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'COVER',
                              style: TextStyle(
                                color: Color(0xFFFF2D55),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'This frame is extracted locally on your device to represent your Reel.',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Production mockup settings card
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _buildToggleRow(
                    icon: Icons.comment_outlined,
                    title: 'Allow Comments',
                    value: true,
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildToggleRow(
                    icon: Icons.share_outlined,
                    title: 'Allow Duets & Stitch',
                    value: true,
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildToggleRow(
                    icon: Icons.save_alt_outlined,
                    title: 'Save to Device Gallery',
                    value: false,
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 20),
                    title: const Text(
                      'Who can watch this video',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Everyone',
                          style: TextStyle(color: Color(0xFFFF2D55), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.3), size: 12),
                      ],
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Upload / Post Button
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF2D55),
                    Color(0xFFFF5A79),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2D55).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.uploadReel(),
                  borderRadius: BorderRadius.circular(26),
                  child: const Center(
                    child: Text(
                      'Post Reel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Clear / Change video text button
            Center(
              child: TextButton(
                onPressed: () => controller.reset(),
                child: Text(
                  'Change Video',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required bool value,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool active = value;
        return SwitchListTile(
          value: active,
          onChanged: (val) {
            setState(() {
              active = val;
            });
          },
          secondary: Icon(icon, color: Colors.white70, size: 20),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          activeThumbColor: const Color(0xFFFF2D55),
          activeTrackColor: const Color(0xFFFF2D55).withValues(alpha: 0.3),
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.white10,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        );
      },
    );
  }

  // --- 4. UPLOADING STATE: PROGRESS PERCENTAGE BAR ---
  Widget _buildUploadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [
            Color(0x22FF2D55),
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepper(2),
              const SizedBox(height: 60),
              // Circular percentage ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 130,
                    width: 130,
                    child: CircularProgressIndicator(
                      value: controller.uploadProgress.value,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF2D55)),
                    ),
                  ),
                  Text(
                    '${(controller.uploadProgress.value * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                'Publishing your Reel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please keep the app open while we upload the video files.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              // Linear progress line
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: controller.uploadProgress.value,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF2D55)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 5. SUCCESS STATE: GLOWING CHECKMARK ---
  Widget _buildSuccessState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [
            Color(0x2200E676), // Subtle green glow
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing checkmark
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x1F00E676),
                  border: Border.all(color: const Color(0xFF00E676), width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3300E676),
                      blurRadius: 20,
                      spreadRadius: 3,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 56,
                  color: Color(0xFF00E676),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Share Successful!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your reel has been published. Swipe back to the main feed to watch it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              // Return to feed button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    controller.reset();
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Back to Feed',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 6. ERROR STATE ---
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something Went Wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'An error occurred while preparing or uploading the video. Please verify your connection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => controller.reset(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2D55),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper stateful widget to manage the video preview player inside UploadScreen.
class _VideoPreviewWidget extends StatefulWidget {
  final File file;
  const _VideoPreviewWidget({required this.file});

  @override
  State<_VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<_VideoPreviewWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _controller = VideoPlayerController.file(widget.file);
    try {
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.setVolume(0.0); // Keep preview muted
      await _controller!.play();
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      Get.log('Error initializing video preview player: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF2D55)),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
