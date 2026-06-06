import 'package:get/get.dart';
import 'package:quick_shorts/app/bindings/reel_binding.dart';
import 'package:quick_shorts/app/bindings/upload_binding.dart';
import 'package:quick_shorts/app/routes/app_routes.dart';
import 'package:quick_shorts/app/views/main_layout/main_layout_screen.dart';
import 'package:quick_shorts/app/views/upload/upload_screen.dart';

/// Defines all GetX pages and their bindings.
///
/// Each GetPage bundles a route name, a widget builder, and a binding.
/// When the user navigates to a route, GetX automatically runs the
/// binding's `dependencies()` method before building the widget —
/// so all controllers and services are ready before the first frame renders.
///
/// To add a new screen (e.g., profile, upload), just add another GetPage here
/// with its own binding. No need to touch existing screens.
abstract class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.home,
      page: () => const MainLayoutScreen(),
      binding: ReelBinding(),
      // Full-screen transition — no app bar or system chrome poking through
      // during the route animation
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.upload,
      page: () => const UploadScreen(),
      binding: UploadBinding(),
      transition: Transition.downToUp, // Bottom-to-top sheet style transition
      transitionDuration: const Duration(milliseconds: 350),
    ),
  ];
}
