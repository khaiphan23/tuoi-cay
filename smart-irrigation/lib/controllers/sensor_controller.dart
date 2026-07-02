import 'package:get/get.dart';
import '../models/sensor_model.dart';
import '../services/supabase_service.dart';
import '../core/constants.dart';

/// SensorController — Quản lý dữ liệu cảm biến realtime
class SensorController extends GetxController {
  final _service = Get.find<SupabaseService>();

  // ─── Reactive state ──────────────────────────────────────
  final current    = SensorModel.empty.obs;
  final history    = <SensorModel>[].obs;
  final isLoading  = false.obs;
  final errorMsg   = RxnString();
  final lastUpdated = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    fetchLatest();
    loadHistory();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    _service.sensorStream().listen((rows) {
      if (rows.isNotEmpty) {
        current.value = SensorModel.fromJson(rows.first);
        lastUpdated.value = DateTime.now();
      }
    });
  }

  Future<void> fetchLatest() async {
    isLoading.value = true;
    errorMsg.value = null;
    try {
      final rows = await _service.getSensorHistory(hours: 1);
      if (rows.isNotEmpty) {
        current.value = SensorModel.fromJson(rows.first);
        lastUpdated.value = DateTime.now();
      }
    } catch (e) {
      errorMsg.value = 'Không thể tải cảm biến: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadHistory({int hours = 24}) async {
    try {
      final rows = await _service.getSensorHistory(hours: hours);
      history.value = rows.map(SensorModel.fromJson).toList();
    } catch (e) {
      errorMsg.value = 'Không thể tải lịch sử: $e';
    }
  }

  // ─── Getters thống kê ────────────────────────────────────
  double moistureAvg24h(int zoneIdx) {
    if (history.isEmpty) return 0;
    return history.map((s) => s.moisture[zoneIdx]).reduce((a, b) => a + b) / history.length;
  }

  double tempAvg24h() {
    if (history.isEmpty) return 0;
    return history.map((s) => s.airTemp).reduce((a, b) => a + b) / history.length;
  }

  List<SensorModel> historyLast(int count) =>
      history.take(count).toList().reversed.toList();
}
