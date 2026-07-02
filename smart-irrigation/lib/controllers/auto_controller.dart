import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../core/constants.dart';

/// AutoConfig cho một khu
class ZoneAutoConfig {
  final int zone;
  double lowThresh;
  double highThresh;
  bool enabled;

  ZoneAutoConfig({
    required this.zone,
    this.lowThresh  = AppConstants.autoMoistureLow,
    this.highThresh = AppConstants.autoMoistureHigh,
    this.enabled    = true,
  });

  factory ZoneAutoConfig.fromJson(Map<String, dynamic> json) {
    return ZoneAutoConfig(
      zone:       json['zone'] as int,
      lowThresh:  (json['low_thresh']  ?? AppConstants.autoMoistureLow).toDouble(),
      highThresh: (json['high_thresh'] ?? AppConstants.autoMoistureHigh).toDouble(),
      enabled:    json['enabled'] ?? true,
    );
  }
}

/// AutoController — Quản lý chế độ tự động
class AutoController extends GetxController {
  final _service = Get.find<SupabaseService>();

  final configs     = <ZoneAutoConfig>[].obs;
  final isLoading   = false.obs;
  final isSaving    = false.obs;
  final errorMsg    = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadConfigs();
  }

  Future<void> loadConfigs() async {
    isLoading.value = true;
    errorMsg.value  = null;
    try {
      final rows = await _service.getAutoConfig();
      if (rows.isEmpty) {
        // Tạo config mặc định nếu chưa có
        configs.value = List.generate(
          AppConstants.numZones,
          (i) => ZoneAutoConfig(zone: i + 1),
        );
      } else {
        configs.value = rows.map(ZoneAutoConfig.fromJson).toList();
      }
    } catch (e) {
      errorMsg.value = 'Không thể tải cấu hình: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void updateLowThresh(int zoneIdx, double value) {
    configs[zoneIdx].lowThresh = value;
    configs.refresh();
  }

  void updateHighThresh(int zoneIdx, double value) {
    configs[zoneIdx].highThresh = value;
    configs.refresh();
  }

  void toggleZoneEnabled(int zoneIdx) {
    configs[zoneIdx].enabled = !configs[zoneIdx].enabled;
    configs.refresh();
  }

  Future<void> saveAll() async {
    isSaving.value = true;
    try {
      for (final cfg in configs) {
        await _service.updateAutoConfig(
          deviceId:   AppConstants.defaultDeviceId,
          zone:       cfg.zone,
          lowThresh:  cfg.lowThresh,
          highThresh: cfg.highThresh,
          enabled:    cfg.enabled,
        );
      }
      Get.snackbar('Đã lưu', 'Cấu hình AUTO đã được cập nhật',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể lưu cấu hình: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Kiểm tra xem zone nào cần tưới (theo sensor hiện tại) ─
  bool zoneNeedsWater(int zoneIdx, int currentMoisture) {
    if (zoneIdx >= configs.length) return false;
    final cfg = configs[zoneIdx];
    return cfg.enabled && currentMoisture < cfg.lowThresh;
  }
}
