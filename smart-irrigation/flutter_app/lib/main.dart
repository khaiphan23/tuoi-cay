import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'services/supabase_service.dart';
import 'controllers/irrigation_controller.dart';
import 'controllers/sensor_controller.dart';
import 'controllers/auto_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Đăng ký dependency injection
  Get.put(SupabaseService());
  Get.put(IrrigationController());
  Get.put(SensorController());
  Get.put(AutoController());

  runApp(const SmartIrrigationApp());
}

class SmartIrrigationApp extends StatelessWidget {
  const SmartIrrigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      title: 'Smart Irrigation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
