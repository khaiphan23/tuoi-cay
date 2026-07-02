import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';
import '../core/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Cài đặt')),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final isDark = themeController.isDark.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.bgBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: isDark ? AppTheme.secondary : AppTheme.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isDark ? 'Chế độ tối' : 'Chế độ sáng',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ),
                  Switch(
                    value: isDark,
                    activeColor: AppTheme.secondary,
                    onChanged: (_) => themeController.toggleTheme(),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}