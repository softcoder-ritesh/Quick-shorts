import 'package:get/get.dart';

/// Lightweight controller managing the active navigation tab index.
class MainLayoutController extends GetxController {
  /// Reactive selected tab index (default is Home = 0)
  final RxInt activeTab = 0.obs;

  /// Update the active tab index
  void changeTab(int index) {
    activeTab.value = index;
  }
}
