import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A thin progress bar at the very bottom of each video showing
/// current playback position.
///
/// We use a ValueListenableBuilder on the controller so this widget
/// rebuilds every frame (approximately 30-60 times/second) to show
/// smooth progress. It's lightweight enough that this doesn't cause
/// any performance issues — it's just a single Container with a
/// width fraction.
class VideoProgressBar extends StatelessWidget {
  final VideoPlayerController controller;

  const VideoProgressBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        // Calculate progress as a fraction of total duration.
        // Guard against division by zero when the video hasn't loaded yet
        // (duration would be Duration.zero).
        final double progress = value.duration.inMilliseconds > 0
            ? value.position.inMilliseconds / value.duration.inMilliseconds
            : 0.0;

        return Container(
          width: double.infinity,
          height: 2,
          color: Colors.white.withValues(alpha: 0.2),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              height: 2,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        );
      },
    );
  }
}
