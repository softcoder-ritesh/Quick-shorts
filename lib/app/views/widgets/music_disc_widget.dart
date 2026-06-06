import 'package:flutter/material.dart';

/// A rotating album disc widget — the circular spinning icon you see
/// in the bottom-right of every TikTok/Reels video.
///
/// It spins continuously while the video is playing and freezes when paused.
/// The rotation is controlled by an AnimationController that the parent
/// manages (starts/stops based on video play state).
class MusicDiscWidget extends StatefulWidget {
  /// URL for the user's avatar or album art shown in the center of the disc.
  /// Falls back to a music note icon if empty.
  final String imageUrl;

  /// Whether the disc should be spinning. Tied to the video's play state.
  final bool isPlaying;

  const MusicDiscWidget({
    super.key,
    required this.imageUrl,
    required this.isPlaying,
  });

  @override
  State<MusicDiscWidget> createState() => _MusicDiscWidgetState();
}

class _MusicDiscWidgetState extends State<MusicDiscWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // Full rotation every 3 seconds — slow enough to feel organic
    // (like a real vinyl record) but fast enough to be noticeable.
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(MusicDiscWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync rotation with video play state — when the video pauses,
    // the disc freezes mid-rotation (not resets), which looks natural.
    if (widget.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotationController,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Dark gradient border mimics a vinyl record edge
          gradient: const LinearGradient(
            colors: [Colors.grey, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.grey.shade700,
            width: 8,
          ),
        ),
        child: ClipOval(
          child: widget.imageUrl.isNotEmpty
              ? Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  // If the avatar fails to load, show a music note instead
                  // of a broken image icon — keeps the UI polished.
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black,
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                )
              : Container(
                  color: Colors.black,
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
        ),
      ),
    );
  }
}
