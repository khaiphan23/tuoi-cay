import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auto_controller.dart';
import '../controllers/sensor_controller.dart';
import '../widgets/auto_threshold_slider.dart';
import '../core/theme.dart';
import '../core/constants.dart';

/// AutoScreen — Cấu hình chế độ tự động
class AutoScreen extends StatelessWidget {
  const AutoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl   = Get.find<AutoController>();
    final sensor = Get.find<SensorController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                title: const Text('Chế độ tự động'),
                actions: [
                  Obx(() => TextButton.icon(
                    onPressed: ctrl.isSaving.value ? null : ctrl.saveAll,
                    icon: ctrl.isSaving.value
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Lưu'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                  )),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ─── Thông tin hướng dẫn ─────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline_rounded, color: AppTheme.secondary, size: 20),
                        SizedBox(width: 10),
                        Expanded(child: Text(
                          'Hệ thống sẽ tự động tưới khi độ ẩm đất xuống dưới ngưỡng thấp, '
                          'và tắt khi đạt ngưỡng cao.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // ─── Slider từng khu ─────────────────────
                    Obx(() {
                      if (ctrl.isLoading.value) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                      }
                      return Column(
                        children: List.generate(ctrl.configs.length, (i) {
                          final cfg    = ctrl.configs[i];
                          final moist  = i < sensor.current.value.moisture.length
                              ? sensor.current.value.moisture[i].toDouble()
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AutoThresholdSlider(
                              zoneIndex:   i,
                              zoneName:    AppConstants.zoneNames[i],
                              lowThresh:   cfg.lowThresh,
                              highThresh:  cfg.highThresh,
                              enabled:     cfg.enabled,
                              currentMoisture: moist,
                              onLowChanged:    (v) => ctrl.updateLowThresh(i, v),
                              onHighChanged:   (v) => ctrl.updateHighThresh(i, v),
                              onToggle:        () => ctrl.toggleZoneEnabled(i),
                            ),
                          );
                        }),
                      );
                    }),

                    const SizedBox(height: 30),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
