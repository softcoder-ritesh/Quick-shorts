/// Named route constants for the app.
///
/// Using string constants instead of inline strings prevents typos
/// from causing silent routing failures. A typo here causes a compile
/// error; a typo in an inline string causes a black screen at runtime.
abstract class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String upload = '/upload';
}
