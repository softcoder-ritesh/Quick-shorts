/// Model representing a single comment on a reel.
class CommentModel {
  final String id;
  final String username;
  final String userAvatar;
  final String text;
  final DateTime createdAt;
  final int likes;
  final bool isLikedByMe;

  CommentModel({
    required this.id,
    required this.username,
    required this.userAvatar,
    required this.text,
    required this.createdAt,
    this.likes = 0,
    this.isLikedByMe = false,
  });

  CommentModel copyWith({
    String? id,
    String? username,
    String? userAvatar,
    String? text,
    DateTime? createdAt,
    int? likes,
    bool? isLikedByMe,
  }) {
    return CommentModel(
      id: id ?? this.id,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}
