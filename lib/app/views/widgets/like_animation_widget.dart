import 'package:flutter/material.dart';

/// The floating heart animation triggered by double-tapping on a video.
///
/// Shows a large white heart in the center of the screen that scales up,
/// floats upward slightly, and fades out — exactly like Instagram's
/// double-tap-to-like behavior. It self-destructs after the animation
/// completes via the `onCompleted` callback.
class LikeAnimationWidget extends StatefulWidget {
  /// Called when the animation finishes so the parent can remove this
  /// widget from the overlay stack and free the memory.
  final VoidCallback onCompleted;

  /// Position where the double-tap occurred. The heart appears at this
  /// point so it feels connected to the user's gesture, not random.
  final Offset position;

  const LikeAnimationWidget({
    super.key,
    required this.onCompleted,
    required this.position,
  });

  @override
  State<LikeAnimationWidget> createState() => _LikeAnimationWidgetState();
}

class _LikeAnimationWidgetState extends State<LikeAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();

    // 800ms total duration — long enough to be noticed, short enough
    // to not block interaction. Instagram uses roughly the same timing.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Scale: 0 → 1.2 → 1.0 (overshoot then settle)
    // The overshoot makes it feel bouncy and organic, not robotic.
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 30,
      ),
    ]).animate(_controller);

    // Opacity: fully visible for the first 60%, then fade out.
    // The delay before fading lets the user actually see the heart
    // before it starts disappearing.
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    // Float upward by 80px during the animation — gives the heart
    // that "rising up" feeling like it's escaping the screen.
    _positionAnimation = Tween<double>(begin: 0.0, end: -80.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);

    _controller.forward().then((_) {
      widget.onCompleted();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          // Center the heart icon on the tap position
          left: widget.position.dx - 40,
          top: widget.position.dy - 40 + _positionAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 80,
                shadows: [
                  // Subtle shadow so the white heart is visible even
                  // on bright video frames
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// An AnimatedBuilder that works with any Animation.
/// This is a simple wrapper to avoid the verbose AnimatedWidget pattern.
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder._internal(
      animation: animation,
      builder: builder,
    );
  }

  // Using AnimatedBuilder from Flutter's built-in
  static Widget _internal({
    required Animation<double> animation,
    required Widget Function(BuildContext, Widget?) builder,
  }) {
    return _AnimatedBuilderWidget(animation: animation, builder: builder);
  }
}

class _AnimatedBuilderWidget extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const _AnimatedBuilderWidget({
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
