import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'controllers/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  Get.put(ThemeController(), permanent: true);

  runApp(const SmartIrrigationApp());
}

class SmartIrrigationApp extends StatelessWidget {
  const SmartIrrigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() => MaterialApp.router(
          title: 'Tưới Cây Thông Minh',
          debugShowCheckedModeBanner: false,
          theme: themeController.isDark.value ? AppTheme.darkTheme : AppTheme.lightTheme,
          routerConfig: appRouter,
        ));
  }
}