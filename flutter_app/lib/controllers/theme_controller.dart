import 'package:get/get.dart';

/// ThemeController — global theme state (GetX), persists across navigation
/// because it's registered with `permanent: true` in main.dart.
class ThemeController extends GetxController {
  final isDark = true.obs; // app starts in dark mode (existing default)

  void toggleTheme() => isDark.value = !isDark.value;
}