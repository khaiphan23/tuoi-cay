import 'package:get/get.dart';
import '../models/valve_model.dart';
import '../models/pump_model.dart';
import '../services/supabase_service.dart';
import '../core/constants.dart';

/// IrrigationController — Quản lý van + bơm (MANUAL)
class IrrigationController extends GetxController {
  final _service = Get.find<SupabaseService>();

  // ─── Trạng thái reactive ────────────────────────────────
  final valves = <ValveModel>[].obs;
  final pump   = PumpModel().obs;
  final mode   = 'MANUAL'.obs;
  final isLoading = false.obs;
  final errorMsg  = RxnString();

  @override
  void onInit() {
    super.onInit();
    _initValves();
    fetchStatus();
    _subscribeRealtime();
  }

  void _initValves() {
    valves.value = List.generate(
      AppConstants.numValves,
      (i) => ValveModel(index: i, name: AppConstants.zoneNames[i]),
    );
  }

  void _subscribeRealtime() {
    _service.valveStatusStream().listen((data) {
      if (data != null) _applyValveStatus(data);
    });
  }

  Future<void> fetchStatus() async {
    isLoading.value = true;
    errorMsg.value = null;
    try {
      final data = await _service.getValveStatus();
      if (data != null) _applyValveStatus(data);
    } catch (e) {
      errorMsg.value = 'Không thể tải trạng thái: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _applyValveStatus(Map<String, dynamic> data) {
    valves.value = List.generate(
      AppConstants.numValves,
      (i) => ValveModel(
        index: i,
        name: AppConstants.zoneNames[i],
        isOpen: data['valve_${i + 1}_open'] ?? false,
      ),
    );
    pump.value = PumpModel(isOn: data['pump_on'] ?? false);
    mode.value = data['mode'] ?? 'MANUAL';
  }

  // ─── Điều khiển van ─────────────────────────────────────
  Future<void> toggleValve(int index) async {
    final valve = valves[index];
    _setValveLoading(index, true);
    try {
      if (valve.isOpen) {
        await _service.closeValve(index);
      } else {
        await _service.openValve(index);
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể điều khiển van: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _setValveLoading(index, false);
    }
  }

  void _setValveLoading(int index, bool loading) {
    final updated = List<ValveModel>.from(valves);
    updated[index] = updated[index].copyWith(isLoading: loading);
    valves.value = updated;
  }

  // ─── Điều khiển bơm ─────────────────────────────────────
  Future<void> togglePump() async {
    pump.update((p) => p?.isLoading = true);
    try {
      await _service.setPump(!pump.value.isOn);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể điều khiển bơm: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      pump.update((p) => p?.isLoading = false);
    }
  }

  // ─── Dừng tất cả ────────────────────────────────────────
  Future<void> stopAll() async {
    isLoading.value = true;
    try {
      await _service.stopAll();
      Get.snackbar('Đã dừng', 'Tất cả van và bơm đã tắt',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể dừng hệ thống: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Chuyển chế độ ──────────────────────────────────────
  Future<void> setMode(String newMode) async {
    await _service.setMode(newMode.toLowerCase());
    mode.value = newMode;
  }

  // ─── Getters tiện ích ───────────────────────────────────
  int get openValveCount => valves.where((v) => v.isOpen).length;
  bool get anyValveOpen  => valves.any((v) => v.isOpen);
  bool get isAutoMode    => mode.value == 'AUTO';
}
