import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:quick_shorts/firebase_options.dart';
import 'package:quick_shorts/app/routes/app_pages.dart';
import 'package:quick_shorts/app/routes/app_routes.dart';

/// Entry point for the Quick Shorts app.
///
/// The initialization sequence matters here:
///   1. WidgetsFlutterBinding — required before any async work in main()
///   2. Firebase.initializeApp — connects to our Firebase project
///   3. System UI styling — sets the status bar to transparent
///   4. GetMaterialApp — launches the app with GetX routing
///
/// We use GetMaterialApp instead of MaterialApp because it plugs in
/// GetX's navigation, dependency injection, and snackbar system automatically.
/// Everything else (theming, routes) works the same as regular MaterialApp.
void main() async {
  // Required before calling any async methods (like Firebase.initializeApp)
  // before runApp(). Without this, Flutter would crash with a
  // "ServicesBinding not initialized" error.
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve native splash screen until initialization finishes
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase using the platform-specific config we generated
  // from google-services.json and GoogleService-Info.plist.
  // This must complete before any Firestore or Storage calls.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Make the status bar transparent and the navigation bar dark
  // so they blend into our black UI. Without this, there'd be
  // a jarring colored bar at the top of the immersive video feed.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    GetMaterialApp(
      title: 'Quick Shorts',
      debugShowCheckedModeBanner: false,

      // Dark theme everywhere — the entire app is designed around
      // a black background for maximum contrast with video content.
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2D55), // Instagram/TikTok red-pink
          surface: Colors.black,
        ),
      ),

      // Start on the home screen, bypassing the custom splash
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,

      // Default transition for all routes — a smooth fade instead
      // of the default platform slide. Feels more "app-like" for
      // a content consumption experience.
      defaultTransition: Transition.fadeIn,
    ),
  );
}
