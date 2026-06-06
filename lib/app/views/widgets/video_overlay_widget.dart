import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:quick_shorts/app/controllers/reel_controller.dart';
import 'package:quick_shorts/app/models/comment_model.dart';
import 'package:quick_shorts/app/models/video_model.dart';
import 'package:quick_shorts/app/utils/format_helpers.dart';
import 'package:quick_shorts/app/views/widgets/music_disc_widget.dart';

/// The overlay UI that sits on top of every video — username, description,
/// like button, share, music disc, and the "For You / Following" tabs.
///
/// This widget is purely presentational — it reads from the ReelController
/// but never modifies video playback state directly. All interactions
/// (like tapping the heart) are routed through controller methods.
class VideoOverlayWidget extends StatefulWidget {
  final VideoModel reel;
  final bool isPlaying;

  const VideoOverlayWidget({
    super.key,
    required this.reel,
    required this.isPlaying,
  });

  @override
  State<VideoOverlayWidget> createState() => _VideoOverlayWidgetState();
}

class _VideoOverlayWidgetState extends State<VideoOverlayWidget>
    with SingleTickerProviderStateMixin {
  final ReelController _controller = Get.find<ReelController>();
  bool _isDescriptionExpanded = false;

  // Like button animation — scales the heart up when tapped
  // to give satisfying tactile feedback
  late AnimationController _likeAnimController;
  late Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _likeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.4),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _likeAnimController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    super.dispose();
  }

  void _onLikeTap() {
    HapticFeedback.lightImpact();
    _likeAnimController.forward(from: 0);
    _controller.toggleLike(widget.reel.id);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Bottom gradient ──
        // Dark gradient behind the text so it's readable on any video.
        // Without this, white text on a bright video frame would be invisible.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 250,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Top gradient ──
        // Gradient behind the "For You / Following" tabs at the top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Top tabs: "For You" / "Following" ──
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // "Following" tab — dimmed since it's not the active tab
              Text(
                'Following',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Divider between tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 1,
                height: 16,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              // "For You" tab — active, bold and fully opaque
              const Text(
                'For You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // ── Right side actions column ──
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            children: [
              // User avatar with white border
              _buildAvatar(),
              const SizedBox(height: 24),

              // Like button with animated scale
              _buildLikeButton(),
              const SizedBox(height: 4),

              // Like count
              Obx(() {
                final reelIndex =
                    _controller.reels.indexWhere((r) => r.id == widget.reel.id);
                final likes = reelIndex != -1
                    ? _controller.reels[reelIndex].likes
                    : widget.reel.likes;
                return Text(
                  FormatHelpers.formatCount(likes),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Comment icon
              GestureDetector(
                onTap: () => _showCommentsBottomSheet(context),
                child: _buildActionIcon(Icons.comment_rounded, 'Comment'),
              ),
              const SizedBox(height: 20),

              // Share button
              GestureDetector(
                onTap: () => _showShareBottomSheet(context),
                child: _buildActionIcon(Icons.share_rounded, 'Share'),
              ),
              const SizedBox(height: 20),

              // Rotating music disc
              MusicDiscWidget(
                imageUrl: widget.reel.userAvatar,
                isPlaying: widget.isPlaying,
              ),
            ],
          ),
        ),

        // ── Bottom-left info area ──
        Positioned(
          left: 12,
          right: 80, // Leave room for the right-side actions column
          bottom: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // @username in bold white
              Text(
                '@${widget.reel.username}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Description with expandable "more" tap
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isDescriptionExpanded = !_isDescriptionExpanded;
                  });
                },
                child: Text(
                  widget.reel.description,
                  maxLines: _isDescriptionExpanded ? 10 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                ),
              ),

              // "more" / "less" toggle — only shown when text overflows
              if (widget.reel.description.length > 60)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDescriptionExpanded = !_isDescriptionExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _isDescriptionExpanded ? 'less' : 'more',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // Scrolling music ticker — mimics TikTok's scrolling song name
              _buildMusicTicker(),
            ],
          ),
        ),
      ],
    );
  }

  /// Interactive bottom sheet containing scrollable user comments,
  /// timestamps, like indicators, and an input text field to add comments in real-time.
  void _showCommentsBottomSheet(BuildContext context) {
    final commentController = TextEditingController();
    final reelId = widget.reel.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              children: [
                // Header drag indicator
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title showing comment count
                Obx(() {
                  final RxList<CommentModel> commentsList = _controller.getCommentsForReel(reelId);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${commentsList.length} comments',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
                const Divider(color: Colors.white12, height: 1),
                // Comments list view
                Expanded(
                  child: Obx(() {
                    final RxList<CommentModel> commentsList = _controller.getCommentsForReel(reelId);
                    if (commentsList.isEmpty) {
                      return const Center(
                        child: Text(
                          'No comments yet. Be the first to comment!',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: commentsList.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        final comment = commentsList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(comment.userAvatar),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '@${comment.username}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      FormatHelpers.formatTimeAgo(comment.createdAt),
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  const Icon(
                                    Icons.favorite_border,
                                    color: Colors.white38,
                                    size: 16,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    comment.likes.toString(),
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
                const Divider(color: Colors.white12, height: 1),
                // Input text field bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: commentController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (val) {
                                if (commentController.text.trim().isNotEmpty) {
                                  _controller.addComment(reelId, commentController.text);
                                  commentController.clear();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: Color(0xFFFF2D55)),
                          onPressed: () {
                            if (commentController.text.trim().isNotEmpty) {
                              _controller.addComment(reelId, commentController.text);
                              commentController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Interactive share sheet with mock contacts row and action items
  /// (Copy Link, Save Video, Favorite, Report).
  void _showShareBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Send to',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Horizontal row of mock contacts
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildShareFriendItem('Alex', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'),
                    _buildShareFriendItem('Sarah', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150'),
                    _buildShareFriendItem('Tom', 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150'),
                    _buildShareFriendItem('Emma', 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150'),
                    _buildShareFriendItem('John', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150'),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              // Grid of share action icons with snacks feedback
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareActionItem(
                      Icons.link_rounded,
                      'Copy Link',
                      () {
                        Navigator.pop(context);
                        Get.snackbar(
                          'Success',
                          'Link copied to clipboard!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xFFFF2D55),
                          colorText: Colors.white,
                        );
                      },
                    ),
                    _buildShareActionItem(
                      Icons.download_rounded,
                      'Save Video',
                      () {
                        Navigator.pop(context);
                        Get.showSnackbar(
                          const GetSnackBar(
                            title: 'Downloading...',
                            message: 'Video is saving to your gallery',
                            duration: Duration(seconds: 2),
                            showProgressIndicator: true,
                            progressIndicatorBackgroundColor: Colors.white24,
                            progressIndicatorValueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF2D55)),
                          ),
                        );
                      },
                    ),
                    _buildShareActionItem(
                      Icons.star_border_rounded,
                      'Favorite',
                      () {
                        Navigator.pop(context);
                        Get.snackbar(
                          'Favorites',
                          'Added to your favorites!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.grey.shade900,
                          colorText: Colors.white,
                        );
                      },
                    ),
                    _buildShareActionItem(
                      Icons.flag_outlined,
                      'Report',
                      () {
                        Navigator.pop(context);
                        Get.snackbar(
                          'Reported',
                          'Thank you for reporting. We will review this content.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.grey.shade900,
                          colorText: Colors.white,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareFriendItem(String name, String avatarUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage(avatarUrl),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildShareActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Circular user avatar with a white border ring.
  /// The "+" badge at the bottom is the follow button (like TikTok).
  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipOval(
            child: widget.reel.userAvatar.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.reel.userAvatar,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.person, color: Colors.white54, size: 24),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.person, color: Colors.white54, size: 24),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.person, color: Colors.white54, size: 24),
                  ),
          ),
        ),
        // Small red "+" follow button below the avatar
        Positioned(
          bottom: -6,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFFF2D55),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 14),
          ),
        ),
      ],
    );
  }

  /// Like button with scale animation on tap.
  /// Turns red when liked, white outline when not.
  Widget _buildLikeButton() {
    return Obx(() {
      final isLiked = _controller.likedReels.contains(widget.reel.id);
      return GestureDetector(
        onTap: _onLikeTap,
        child: AnimatedBuilder(
          animation: _likeAnimController,
          builder: (context, child) {
            return Transform.scale(
              scale: _likeScaleAnimation.value,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? const Color(0xFFFF2D55) : Colors.white,
                size: 35,
                shadows: const [
                  Shadow(color: Colors.black38, blurRadius: 8),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  /// Generic action icon (comment, share, etc.) with label below.
  Widget _buildActionIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 30,
          shadows: const [
            Shadow(color: Colors.black38, blurRadius: 8),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// Scrolling music name ticker at the bottom — continuously scrolls
  /// horizontally to mimic TikTok's "♫ Original Sound - username" bar.
  Widget _buildMusicTicker() {
    return Row(
      children: [
        const Icon(Icons.music_note, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 18,
            child: _MarqueeText(
              text: '♫ Original Sound - ${widget.reel.username}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple marquee/ticker widget that scrolls text horizontally in a loop.
///
/// We build this custom instead of using a package because:
///   1. It's only ~40 lines of code
///   2. No additional dependency to manage
///   3. We have full control over scroll speed and behavior
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // Wait for layout to complete before starting scroll animation.
    // Without this delay, maxScrollExtent would be 0 and the animation
    // would do nothing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _animController.repeat();
        _animController.addListener(_onScroll);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxExtent = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(_animController.value * maxExtent);
    }
  }

  @override
  void dispose() {
    _animController.removeListener(_onScroll);
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      // Disable manual scrolling — the animation handles it
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          Text(widget.text, style: widget.style),
          // Gap between repeated text so it looks like continuous scroll
          const SizedBox(width: 80),
          Text(widget.text, style: widget.style),
        ],
      ),
    );
  }
}

/// AnimatedBuilder wrapper — reusing the one from like_animation_widget
/// to keep code DRY. In a larger app, this would live in a shared widgets folder.
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
