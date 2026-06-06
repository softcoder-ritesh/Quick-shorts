// Small formatting utilities used across the app.
// These keep the UI code clean — instead of inline conditional logic
// for number formatting, widgets just call `formatCount(12400)` and get "12.4K".

class FormatHelpers {
  /// Turns raw numbers into the compact notation you see on social apps:
  ///   - 999 → "999"
  ///   - 1200 → "1.2K"
  ///   - 12400 → "12.4K"
  ///   - 1200000 → "1.2M"
  ///   - 1500000000 → "1.5B"
  ///
  /// We round to one decimal place and strip trailing ".0" so
  /// "10.0K" becomes "10K" which looks cleaner.
  static String formatCount(int count) {
    if (count >= 1000000000) {
      final value = count / 1000000000;
      return '${_trimTrailingZero(value)}B';
    } else if (count >= 1000000) {
      final value = count / 1000000;
      return '${_trimTrailingZero(value)}M';
    } else if (count >= 1000) {
      final value = count / 1000;
      return '${_trimTrailingZero(value)}K';
    }
    return count.toString();
  }

  /// Strips ".0" from values like 10.0 so we display "10K" not "10.0K".
  /// Keeps one decimal for non-round numbers like 12.4.
  static String _trimTrailingZero(double value) {
    final formatted = value.toStringAsFixed(1);
    if (formatted.endsWith('.0')) {
      return formatted.substring(0, formatted.length - 2);
    }
    return formatted;
  }

  /// Converts a DateTime into a human-friendly relative time string.
  /// Used for showing when a reel was posted.
  ///
  /// Examples:
  ///   - 30 seconds ago → "Just now"
  ///   - 5 minutes ago  → "5m ago"
  ///   - 3 hours ago    → "3h ago"
  ///   - 2 days ago     → "2d ago"
  ///   - 3 weeks ago    → "3w ago"
  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }
}
