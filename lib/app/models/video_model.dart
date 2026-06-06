import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single reel/short video with all its metadata.
///
/// This model is the single source of truth for what a "reel" looks like
/// throughout the app. Every layer — Firestore, controllers, and UI —
/// speaks this same language. No raw Maps floating around.
class VideoModel {
  /// Firestore document ID — we use this as the cache key for video files
  /// and as the unique identifier for like tracking.
  final String id;

  /// Direct download URL for the video file hosted in Firebase Storage.
  /// This is the full `gs://` or `https://` URL, not a relative path.
  final String videoUrl;

  /// Thumbnail image URL — shown as a blurred placeholder while the
  /// video controller initializes. Also stored in Firebase Storage.
  final String thumbnailUrl;

  /// Caption text the user wrote when posting the reel.
  /// Can contain hashtags and mentions — we display it with truncation
  /// and a "more" button in the overlay.
  final String description;

  /// Total like count. Updated optimistically in the UI when the user
  /// taps like, then synced to Firestore via an atomic increment.
  final int likes;

  /// Display name of the creator (without the @ prefix — we add that in the UI).
  final String username;

  /// Profile picture URL for the creator. Shown in the right-side actions column.
  final String userAvatar;

  /// When the reel was posted. Used for ordering (newest first) and
  /// for the "3h ago" display in the overlay.
  final DateTime createdAt;

  const VideoModel({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.description,
    required this.likes,
    required this.username,
    required this.userAvatar,
    required this.createdAt,
  });

  /// Creates a VideoModel from a Firestore document snapshot.
  ///
  /// We pull the document ID from `doc.id` rather than storing it as a field
  /// inside the document — this is the Firestore convention and avoids
  /// data duplication. Each field has a sensible fallback so the app doesn't
  /// crash if someone adds a document with missing fields in the console.
  factory VideoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return VideoModel(
      id: doc.id,
      videoUrl: data['videoUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      description: data['description'] as String? ?? '',
      likes: data['likes'] as int? ?? 0,
      username: data['username'] as String? ?? 'unknown',
      userAvatar: data['userAvatar'] as String? ?? '',
      // Firestore stores dates as Timestamps — we convert to Dart DateTime
      // for easier manipulation. Falls back to epoch if the field is missing.
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Converts the model back to a Map for writing to Firestore.
  /// Used if we ever need to create/update reel documents from the app
  /// (e.g., an upload feature in the future).
  Map<String, dynamic> toMap() {
    return {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'likes': likes,
      'username': username,
      'userAvatar': userAvatar,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Returns a copy of this model with an updated likes count.
  /// Used for optimistic UI updates — we don't mutate the original,
  /// we create a new instance so GetX detects the change via Rx.
  VideoModel copyWith({int? likes}) {
    return VideoModel(
      id: id,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      description: description,
      likes: likes ?? this.likes,
      username: username,
      userAvatar: userAvatar,
      createdAt: createdAt,
    );
  }
}
